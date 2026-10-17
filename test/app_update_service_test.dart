import 'package:flutter_test/flutter_test.dart';
import 'package:field_expense_manager/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService.compareVersions', () {
    test('orders dotted versions numerically', () {
      expect(AppUpdateService.compareVersions('1.2.2', '1.2.1'), greaterThan(0));
      expect(AppUpdateService.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(AppUpdateService.compareVersions('1.2.0', '1.2.1'), lessThan(0));
      expect(AppUpdateService.compareVersions('2.0', '1.9.9'), greaterThan(0));
    });

    test('ignores the v prefix, build number and pre-release suffix', () {
      expect(AppUpdateService.compareVersions('v1.2.2', '1.2.2'), 0);
      expect(AppUpdateService.compareVersions('1.2.2+9', '1.2.2+8'), 0);
      expect(AppUpdateService.compareVersions('V1.2.3-beta', '1.2.3'), 0);
      expect(AppUpdateService.compareVersions('1.2', '1.2.0'), 0);
    });

    test('normalizeVersion strips decorations', () {
      expect(AppUpdateService.normalizeVersion(' v1.2.2+9 '), '1.2.2');
    });
  });

  group('AppUpdateService.pickApkAsset', () {
    Map<String, dynamic> asset(String name) => {'name': name};

    // Asset names as published on the v1.2.0 GitHub release.
    final splitAssets = [
      asset('app-arm64-v8a-release.apk'),
      asset('app-armeabi-v7a-release.apk'),
      asset('app-x86_64-release.apk'),
    ];

    test('picks the split APK for the device ABI', () {
      expect(
        AppUpdateService.pickApkAsset(splitAssets, ['arm64-v8a', 'armeabi-v7a', 'armeabi'])!['name'],
        'app-arm64-v8a-release.apk',
      );
      expect(
        AppUpdateService.pickApkAsset(splitAssets, ['armeabi-v7a', 'armeabi'])!['name'],
        'app-armeabi-v7a-release.apk',
      );
      expect(
        AppUpdateService.pickApkAsset(splitAssets, ['x86_64', 'x86'])!['name'],
        'app-x86_64-release.apk',
      );
    });

    test('x86 does not match the x86_64 APK', () {
      expect(AppUpdateService.pickApkAsset(splitAssets, ['x86']), isNull);
    });

    test('falls back to a universal APK', () {
      final assets = [asset('notes.txt'), asset('expenza.v1.0.3.apk')];
      expect(
        AppUpdateService.pickApkAsset(assets, ['arm64-v8a'])!['name'],
        'expenza.v1.0.3.apk',
      );
    });

    test('prefers the matching split over a universal APK', () {
      final assets = [asset('app-release.apk'), ...splitAssets];
      expect(
        AppUpdateService.pickApkAsset(assets, ['arm64-v8a'])!['name'],
        'app-arm64-v8a-release.apk',
      );
    });

    test('returns null when there is no APK', () {
      expect(AppUpdateService.pickApkAsset([asset('source.zip')], ['arm64-v8a']), isNull);
      expect(AppUpdateService.pickApkAsset([], const []), isNull);
    });

    test('uses any APK when device ABIs are unknown', () {
      expect(
        AppUpdateService.pickApkAsset(splitAssets, const [])!['name'],
        'app-arm64-v8a-release.apk',
      );
    });
  });
}
