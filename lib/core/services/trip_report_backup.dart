import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/repositories/trip_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../models/trip.dart';
import 'export_service.dart';

/// Whether a trip's Excel and PDF reports exist on the device.
class TripReportStatus {
  final Trip trip;
  final DateTime? excelSavedAt;
  final DateTime? pdfSavedAt;

  const TripReportStatus(this.trip, {this.excelSavedAt, this.pdfSavedAt});

  bool get hasExcel => excelSavedAt != null;
  bool get hasPdf => pdfSavedAt != null;
  bool get hasBoth => hasExcel && hasPdf;
}

/// What the user should back up before updating the app.
class ReportBackupAdvice {
  /// Active trips: always worth exporting fresh, since they still change.
  final List<TripReportStatus> activeTrips;

  /// Submitted trips (In-process / Settled) missing an Excel or PDF report.
  /// Only relevant when there are no active trips.
  final List<TripReportStatus> submittedMissing;

  const ReportBackupAdvice(this.activeTrips, this.submittedMissing);

  bool get hasActiveTrips => activeTrips.isNotEmpty;
  bool get isEmpty => activeTrips.isEmpty && submittedMissing.isEmpty;

  /// Trips the "Generate reports" action should export.
  List<Trip> get tripsToExport => hasActiveTrips
      ? activeTrips.map((s) => s.trip).toList()
      : submittedMissing.map((s) => s.trip).toList();
}

/// Checks for and generates the Excel/PDF trip reports, e.g. as a safety copy
/// before installing an app update.
class TripReportBackup {
  TripReportBackup._();

  static Future<ReportBackupAdvice> assess() async {
    final trips = await TripRepository().getTrips();
    final dirs = await _candidateDirectories();

    final active = <TripReportStatus>[];
    final submittedMissing = <TripReportStatus>[];
    for (final trip in trips) {
      final status = TripReportStatus(
        trip,
        excelSavedAt: await _savedAt(dirs, '${trip.name}_report.xlsx'),
        pdfSavedAt: await _savedAt(dirs, '${trip.name}_report.pdf'),
      );
      if (trip.status == 'Active') {
        active.add(status);
      } else if (!status.hasBoth) {
        submittedMissing.add(status);
      }
    }
    return ReportBackupAdvice(
      active,
      active.isEmpty ? submittedMissing : const [],
    );
  }

  /// Generates the Excel and PDF report for each trip.
  /// Returns the saved file paths; throws if every export failed.
  static Future<List<String>> generate(
    List<Trip> trips, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      // Same as exporting from a trip: lets reports go to Internal storage > Expenza.
      await Permission.manageExternalStorage.request();
    }
    final repository = TripRepository();
    final profile = await UserRepository().getUserProfile();
    final service = ExportService();

    final total = trips.length * 2;
    var done = 0;
    final saved = <String>[];
    Object? lastError;
    for (final trip in trips) {
      final expenses = await repository.getExpenses(trip.id!);
      final advances = await repository.getAdvances(trip.id!);
      for (final isExcel in [true, false]) {
        try {
          final path = isExcel
              ? await service.exportToExcel(
                  trip,
                  expenses,
                  userProfile: profile,
                  advances: advances,
                )
              : await service.exportToPdf(trip, expenses, userProfile: profile);
          if (path != null) saved.add(path);
        } catch (e) {
          lastError = e;
          debugPrint('TripReportBackup: export failed for ${trip.name}: $e');
        }
        onProgress?.call(++done, total);
      }
    }
    if (saved.isEmpty && lastError != null) throw lastError;
    return saved;
  }

  /// Human-readable folder of a saved report, e.g. "Internal storage › Expenza".
  static String folderLabel(String filePath) {
    final folder = File(filePath).parent.path;
    const internal = '/storage/emulated/0/';
    return folder.startsWith(internal)
        ? 'Internal storage › ${folder.substring(internal.length).replaceAll('/', ' › ')}'
        : folder;
  }

  /// All folders ExportService may have written reports to, most likely first.
  static Future<List<Directory>> _candidateDirectories() async {
    final dirs = <Directory>[];
    if (!kIsWeb && Platform.isAndroid) {
      dirs.add(Directory('/storage/emulated/0/Expenza'));
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) dirs.add(Directory('${downloads.path}/Expenza'));
      } catch (_) {}
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) dirs.add(Directory('${ext.path}/Expenza'));
      } catch (_) {}
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      dirs.add(Directory('${docs.path}/Expenza'));
    } catch (_) {}
    return dirs;
  }

  static Future<DateTime?> _savedAt(List<Directory> dirs, String fileName) async {
    DateTime? newest;
    for (final dir in dirs) {
      try {
        final file = File('${dir.path}/$fileName');
        if (await file.exists()) {
          final modified = await file.lastModified();
          if (newest == null || modified.isAfter(newest)) newest = modified;
        }
      } catch (_) {}
    }
    return newest;
  }
}
