import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A published GitHub release that can be installed on this device.
class AppRelease {
  final String version; // e.g. "1.2.2"
  final String tagName; // e.g. "v1.2.2"
  final String title;
  final String notes;
  final String pageUrl;
  final String apkName;
  final String apkUrl;
  final int apkSize;

  const AppRelease({
    required this.version,
    required this.tagName,
    required this.title,
    required this.notes,
    required this.pageUrl,
    required this.apkName,
    required this.apkUrl,
    required this.apkSize,
  });
}

enum UpdateCheckStatus { updateAvailable, upToDate, skipped, notSupported, failed }

class UpdateCheckResult {
  final UpdateCheckStatus status;
  final AppRelease? release;
  final String currentVersion;
  final String? error;

  const UpdateCheckResult(
    this.status, {
    this.release,
    this.currentVersion = '',
    this.error,
  });
}

/// Checks GitHub Releases for a newer version and installs it.
///
/// Release convention: tag `vX.Y.Z` (matching pubspec `version`), with the
/// APK(s) attached. Per-ABI APKs from `flutter build apk --split-per-abi`
/// (`app-arm64-v8a-release.apk`, ...) or a single universal APK both work.
/// Android only installs an update signed with the same key as the
/// installed app.
class AppUpdateService {
  AppUpdateService._();

  static const String repository = 'SonuSinghRajpoot/expenza';
  static const String releasesPageUrl = 'https://github.com/$repository/releases';
  static const String _latestReleaseApi =
      'https://api.github.com/repos/$repository/releases/latest';

  static const String _prefSkippedTag = 'app_update_skipped_tag';
  static const String _apkMimeType = 'application/vnd.android.package-archive';

  static const MethodChannel _channel =
      MethodChannel('com.fieldexpensemanager/app_update');

  /// ABI names used in split APK file names.
  static const List<String> knownAbis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks for an update.
  ///
  /// Automatic checks ([manual] false) ignore a version the user chose to
  /// skip; manual checks always report it.
  static Future<UpdateCheckResult> checkForUpdate({bool manual = false}) async {
    if (!isSupported) {
      return const UpdateCheckResult(UpdateCheckStatus.notSupported);
    }

    final prefs = await SharedPreferences.getInstance();

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    try {
      final response = await http
          .get(
            Uri.parse(_latestReleaseApi),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        // No published release yet.
        return UpdateCheckResult(
          UpdateCheckStatus.upToDate,
          currentVersion: currentVersion,
        );
      }
      if (response.statusCode != 200) {
        throw HttpException('GitHub returned ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (json['tag_name'] ?? '').toString();
      final releaseVersion = normalizeVersion(tagName);

      if (compareVersions(releaseVersion, currentVersion) <= 0) {
        return UpdateCheckResult(
          UpdateCheckStatus.upToDate,
          currentVersion: currentVersion,
        );
      }
      if (!manual && prefs.getString(_prefSkippedTag) == tagName) {
        return UpdateCheckResult(
          UpdateCheckStatus.skipped,
          currentVersion: currentVersion,
        );
      }

      final assets = (json['assets'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final asset = pickApkAsset(assets, await _supportedAbis());
      if (asset == null) {
        return UpdateCheckResult(
          UpdateCheckStatus.failed,
          currentVersion: currentVersion,
          error: 'Version $releaseVersion has no APK attached on GitHub.',
        );
      }

      return UpdateCheckResult(
        UpdateCheckStatus.updateAvailable,
        currentVersion: currentVersion,
        release: AppRelease(
          version: releaseVersion,
          tagName: tagName,
          title: (json['name'] ?? tagName).toString(),
          notes: (json['body'] ?? '').toString(),
          pageUrl: (json['html_url'] ?? releasesPageUrl).toString(),
          apkName: asset['name'].toString(),
          apkUrl: asset['browser_download_url'].toString(),
          apkSize: (asset['size'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (e) {
      debugPrint('AppUpdateService.checkForUpdate failed: $e');
      return UpdateCheckResult(
        UpdateCheckStatus.failed,
        currentVersion: currentVersion,
        error: e is SocketException || e is TimeoutException
            ? 'Could not reach GitHub. Check your internet connection.'
            : 'Could not check for updates.',
      );
    }
  }

  /// Remembers that the user does not want to be reminded about [tagName].
  static Future<void> skipVersion(String tagName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSkippedTag, tagName);
  }

  /// Downloads the release APK into the app cache, reporting progress (0..1).
  /// Returns the local file path.
  static Future<String> downloadApk(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final cacheDir = await getTemporaryDirectory();
    final dir = Directory('${cacheDir.path}/updates');
    if (await dir.exists()) {
      await dir.delete(recursive: true); // drop older downloads
    }
    await dir.create(recursive: true);
    final file = File('${dir.path}/${release.apkName}');

    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', Uri.parse(release.apkUrl)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})');
      }
      final total = response.contentLength ?? release.apkSize;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call(received / total);
        }
      } finally {
        await sink.close();
      }
      if (release.apkSize > 0 && received != release.apkSize) {
        await file.delete();
        throw const HttpException('Download incomplete. Please try again.');
      }
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Opens the Android installer for the downloaded APK.
  /// Returns null on success, otherwise a message for the user.
  static Future<String?> installApk(String path) async {
    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) {
      return 'Allow "Install unknown apps" for Expenza in Settings, then try again.';
    }
    final result = await OpenFilex.open(path, type: _apkMimeType);
    switch (result.type) {
      case ResultType.done:
        return null;
      case ResultType.permissionDenied:
        return 'Allow "Install unknown apps" for Expenza in Settings, then try again.';
      default:
        return 'Could not open the installer: ${result.message}';
    }
  }

  /// "v1.2.3+9" / "1.2.3-beta" -> "1.2.3"
  static String normalizeVersion(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);
    return v.split('+').first.split('-').first.trim();
  }

  /// Compares dotted numeric versions: negative if [a] < [b], 0 if equal.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => normalizeVersion(v)
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final pa = parts(a);
    final pb = parts(b);
    for (var i = 0; i < 3 || i < pa.length || i < pb.length; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  /// Picks the APK for this device: the first split APK matching the device's
  /// supported ABIs (in the device's order of preference), otherwise a
  /// universal APK (no ABI in the name), otherwise any APK.
  static Map<String, dynamic>? pickApkAsset(
    List<Map<String, dynamic>> assets,
    List<String> deviceAbis,
  ) {
    final apks = assets
        .where((a) => (a['name'] ?? '').toString().toLowerCase().endsWith('.apk'))
        .toList();
    if (apks.isEmpty) return null;

    String nameOf(Map<String, dynamic> a) => a['name'].toString().toLowerCase();
    // ABI as a separate token: "app-x86-release" has x86, "app-x86_64-release" does not.
    bool hasAbi(String name, String abi) =>
        RegExp('(^|[^a-z0-9])${RegExp.escape(abi)}([^a-z0-9_]|\$)')
            .hasMatch(name);

    for (final abi in deviceAbis) {
      final match = apks.where((a) => hasAbi(nameOf(a), abi.toLowerCase()));
      if (match.isNotEmpty) return match.first;
    }
    final universal = apks.where(
      (a) => !knownAbis.any((abi) => hasAbi(nameOf(a), abi)),
    );
    if (universal.isNotEmpty) return universal.first;
    return deviceAbis.isEmpty ? apks.first : null;
  }

  static Future<List<String>> _supportedAbis() async {
    try {
      final abis = await _channel.invokeListMethod<String>('getSupportedAbis');
      return abis ?? const [];
    } catch (e) {
      debugPrint('AppUpdateService: could not read device ABIs: $e');
      return const [];
    }
  }
}
