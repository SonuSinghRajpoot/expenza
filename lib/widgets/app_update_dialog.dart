import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/app_update_service.dart';
import '../core/services/share_session.dart';
import '../core/theme/app_design.dart';
import '../core/theme/app_text_styles.dart';

/// Entry points for checking GitHub for a newer app version.
class AppUpdateFlow {
  AppUpdateFlow._();

  static bool _inProgress = false;

  static bool _launchCheckDone = false;

  /// Automatic check, once per app launch: silent unless an update is
  /// available. Skipped for a launch that came from sharing a file into the
  /// app, and never shown while a share is being handled.
  static Future<void> checkOnLaunch(BuildContext context) async {
    if (_launchCheckDone || _inProgress) return;
    _inProgress = true;
    try {
      // Wait until the share listener knows whether this launch was a share.
      await ShareSession.initialShareChecked.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
      if (ShareSession.launchedWithShare) {
        _launchCheckDone = true; // the user is here to share, not to update
        return;
      }
      // A share, form or dialog is open: try again when the main screen is
      // shown next in this launch (e.g. after unlocking).
      if (!context.mounted ||
          ShareSession.isHandlingShare ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      _launchCheckDone = true;

      final result = await AppUpdateService.checkForUpdate();
      if (result.status == UpdateCheckStatus.updateAvailable &&
          context.mounted &&
          !ShareSession.isHandlingShare &&
          ModalRoute.of(context)?.isCurrent == true) {
        await _showDialog(context, result);
      } else if (result.status == UpdateCheckStatus.failed) {
        _launchCheckDone = false; // e.g. offline: retry when the main screen opens next
      }
    } finally {
      _inProgress = false;
    }
  }

  /// "Check for updates" from Profile: always tells the user the outcome.
  static Future<void> checkManually(BuildContext context) async {
    if (_inProgress) return;
    _inProgress = true;
    try {
      final result = await AppUpdateService.checkForUpdate(manual: true);
      if (!context.mounted) return;
      switch (result.status) {
        case UpdateCheckStatus.updateAvailable:
          await _showDialog(context, result);
          break;
        case UpdateCheckStatus.upToDate:
          _snack(context, 'You have the latest version (${result.currentVersion}).');
          break;
        case UpdateCheckStatus.notSupported:
          _snack(context, 'In-app updates are only available on Android.');
          break;
        case UpdateCheckStatus.failed:
        case UpdateCheckStatus.skipped:
          _snack(
            context,
            result.error ?? 'Could not check for updates.',
            isError: true,
          );
          break;
      }
    } finally {
      _inProgress = false;
    }
  }

  static Future<void> _showDialog(BuildContext context, UpdateCheckResult result) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(
        release: result.release!,
        currentVersion: result.currentVersion,
      ),
    );
  }

  static void _snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : null,
      ),
    );
  }
}

class AppUpdateDialog extends StatefulWidget {
  final AppRelease release;
  final String currentVersion;

  const AppUpdateDialog({
    super.key,
    required this.release,
    required this.currentVersion,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _downloading = false;
  double? _progress;
  String? _error;

  Future<void> _update() async {
    setState(() {
      _downloading = true;
      _progress = null;
      _error = null;
    });
    try {
      final path = await AppUpdateService.downloadApk(
        widget.release,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      final installError = await AppUpdateService.installApk(path);
      if (!mounted) return;
      if (installError == null) {
        Navigator.of(context).pop(); // Android installer takes over
      } else {
        setState(() {
          _downloading = false;
          _error = installError;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = e is Exception
            ? e.toString().replaceFirst(RegExp(r'^\w*Exception: '), '')
            : 'Download failed. Please try again.';
      });
    }
  }

  Future<void> _skip() async {
    await AppUpdateService.skipVersion(widget.release.tagName);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openReleasePage() async {
    final uri = Uri.parse(widget.release.pageUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final sizeMb = release.apkSize > 0
        ? ' • ${(release.apkSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';
    final notes = _plainNotes(release.notes);

    return PopScope(
      canPop: !_downloading,
      child: AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppDesign.screenHorizontalPadding,
          vertical: AppDesign.screenVerticalPadding,
        ),
        title: const Text('Update available'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${release.version} is available. '
                'You have ${widget.currentVersion}.',
                style: AppTextStyles.bodyMediumOf(context),
              ),
              const Gap(4),
              Text(
                '${release.apkName}$sizeMb',
                style: AppTextStyles.captionOf(context),
              ),
              if (notes.isNotEmpty) ...[
                const Gap(12),
                Text(
                  "WHAT'S NEW",
                  style: AppTextStyles.captionOf(context).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const Gap(6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Text(notes, style: AppTextStyles.bodySmallOf(context)),
                  ),
                ),
              ],
              if (_downloading) ...[
                const Gap(16),
                LinearProgressIndicator(value: _progress),
                const Gap(6),
                Text(
                  _progress == null
                      ? 'Starting download…'
                      : 'Downloading… ${(_progress! * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.captionOf(context),
                ),
              ],
              if (_error != null) ...[
                const Gap(12),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmallOf(context).copyWith(
                    color: AppDesign.error,
                  ),
                ),
                TextButton(
                  onPressed: _openReleasePage,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Download from GitHub instead'),
                ),
              ],
            ],
          ),
        ),
        actions: _downloading
            ? const []
            : [
                TextButton(onPressed: _skip, child: const Text('Skip version')),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Later'),
                ),
                FilledButton(
                  onPressed: _update,
                  child: Text(_error == null ? 'Update' : 'Retry'),
                ),
              ],
      ),
    );
  }

  /// Release notes are Markdown; show them as readable plain text.
  static String _plainNotes(String markdown) {
    final lines = <String>[];
    for (var line in markdown.replaceAll('\r', '').split('\n')) {
      line = line.trim();
      if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(line)) continue;
      line = line
          .replaceFirst(RegExp(r'^#{1,6}\s*'), '')
          .replaceFirst(RegExp(r'^[-*+]\s+'), '• ')
          .replaceAll(RegExp(r'\*\*|__|`'), '')
          .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!);
      if (line.isEmpty && (lines.isEmpty || lines.last.isEmpty)) continue;
      lines.add(line);
    }
    return lines.join('\n').trim();
  }
}
