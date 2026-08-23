import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ExportDirectoryHelper {
  static String normalizeLocalPath(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('file://')) {
      try {
        return Uri.parse(path).toFilePath();
      } catch (_) {
        return path;
      }
    }
    return path;
  }

  /// Returns the Expenza folder for exports. Creates it if missing.
  /// - Android: tries Internal storage > Expenza (/storage/emulated/0/Expenza) first
  ///   when MANAGE_EXTERNAL_STORAGE is granted; else falls back to app-specific
  ///   downloads, external, or app documents/Expenza.
  /// - iOS / others: app documents/Expenza
  static Future<Directory> getDownloadDirectory() async {
    Directory base;
    if (Platform.isAndroid) {
      try {
        final root = Directory('/storage/emulated/0/Expenza');
        await root.create(recursive: true);
        base = root;
      } catch (_) {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          base = Directory('${downloads.path}/Expenza');
        } else {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            base = Directory('${ext.path}/Expenza');
          } else {
            final appDoc = await getApplicationDocumentsDirectory();
            base = Directory('${appDoc.path}/Expenza');
          }
        }
        if (!await base.exists()) {
          await base.create(recursive: true);
        }
      }
    } else {
      final appDoc = await getApplicationDocumentsDirectory();
      base = Directory('${appDoc.path}/Expenza');
      if (!await base.exists()) {
        await base.create(recursive: true);
      }
    }
    return base;
  }

  /// Clean up FlutterExcel.xlsx and old duplicate files
  static Future<void> cleanupOldFiles(
      Directory directory, String correctFileName) async {
    try {
      final targetFile = File("${directory.path}/$correctFileName");
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final flutterExcelFile = File("${directory.path}/FlutterExcel.xlsx");
      if (await flutterExcelFile.exists()) {
        await flutterExcelFile.delete();
      }

      if (await directory.exists()) {
        final files = directory.listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.xlsx')) {
            final fileName = file.path.split('/').last;
            if (fileName == 'FlutterExcel.xlsx' ||
                fileName.startsWith('FlutterExcel') ||
                (fileName != correctFileName &&
                    fileName.contains('FlutterExcel'))) {
              try {
                await file.delete();
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Comprehensively cleans up FlutterExcel.xlsx files from all possible locations
  static Future<void> cleanupFlutterExcelFiles() async {
    try {
      final directoriesToCheck = <Future<Directory?>>[];

      try {
        directoriesToCheck.add(getTemporaryDirectory());
      } catch (_) {}

      if (Platform.isAndroid) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directoriesToCheck.add(Future.value(externalDir));
          }
        } catch (_) {}

        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            directoriesToCheck.add(Future.value(downloadsDir));
          }
        } catch (_) {}
      }

      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        directoriesToCheck.add(Future.value(appDocDir));
      } catch (_) {}

      for (final dirFuture in directoriesToCheck) {
        try {
          final dir = await dirFuture;
          if (dir != null && await dir.exists()) {
            final flutterExcelFile = File('${dir.path}/FlutterExcel.xlsx');
            if (await flutterExcelFile.exists()) {
              await flutterExcelFile.delete();
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error cleaning up FlutterExcel files: $e');
    }
  }
}
