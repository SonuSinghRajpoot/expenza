import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility for requesting Android-standard permissions before camera/gallery/file access.
class PermissionUtils {
  /// Request camera permission. Returns true if granted, false otherwise.
  /// On non-Android or web, returns true (no permission needed).
  static Future<bool> requestCamera(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    final status = await Permission.camera.request();
    return _handleResult(context, status, 'Camera access is needed to scan documents.');
  }

  /// Request gallery/photos permission. Returns true if granted.
  /// Uses Permission.photos (Android 13+) or storage on older devices.
  static Future<bool> requestGallery(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    final status = await Permission.photos.request();
    return _handleResult(context, status, 'Gallery access is needed to select images.');
  }

  /// Request storage permission for file browsing (e.g. PDF).
  /// On Android 13+, photos permission covers media; storage may still be needed for some file types.
  static Future<bool> requestStorageForFiles(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    // Try photos first (Android 13+), then storage for older devices
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return _handleResult(context, status, 'Storage access is needed to select files.');
  }

  static bool _handleResult(
    BuildContext context,
    PermissionStatus status,
    String deniedMessage,
  ) {
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied && context.mounted) {
      _showOpenSettingsDialog(context, deniedMessage);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deniedMessage),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return false;
  }

  static void _showOpenSettingsDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$message\n\nPlease enable it in app settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
