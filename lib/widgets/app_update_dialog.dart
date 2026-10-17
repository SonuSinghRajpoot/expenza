import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/app_update_service.dart';
import '../core/services/share_session.dart';
import '../core/services/trip_report_backup.dart';
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
  bool _backupChecked = false;
  bool _checkingBackup = false;
  bool _downloading = false;
  double? _progress;
  String? _error;

  /// Before the first download, suggest saving Excel/PDF reports. Returns
  /// false if the user cancelled.
  Future<bool> _confirmBackup() async {
    if (_backupChecked) return true;
    setState(() => _checkingBackup = true);
    ReportBackupAdvice? advice;
    try {
      advice = await TripReportBackup.assess();
    } catch (e) {
      debugPrint('AppUpdateDialog: could not check reports: $e');
    }
    if (!mounted) return false;
    setState(() => _checkingBackup = false);
    if (advice == null || advice.isEmpty) {
      _backupChecked = true;
      return true;
    }
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackupBeforeUpdateDialog(advice: advice!),
    );
    if (proceed == true) _backupChecked = true;
    return proceed == true;
  }

  Future<void> _update() async {
    if (!await _confirmBackup() || !mounted) return;
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
              if (_checkingBackup) ...[
                const Gap(16),
                const LinearProgressIndicator(),
                const Gap(6),
                Text(
                  'Checking your trip reports…',
                  style: AppTextStyles.captionOf(context),
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
        actions: _downloading || _checkingBackup
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

/// Suggests saving Excel and PDF reports before updating, and can generate
/// them. Pops true to continue with the update, false to cancel.
class BackupBeforeUpdateDialog extends StatefulWidget {
  final ReportBackupAdvice advice;

  const BackupBeforeUpdateDialog({super.key, required this.advice});

  @override
  State<BackupBeforeUpdateDialog> createState() =>
      _BackupBeforeUpdateDialogState();
}

class _BackupBeforeUpdateDialogState extends State<BackupBeforeUpdateDialog> {
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy, h:mm a');

  bool _generating = false;
  int _done = 0;
  int _total = 0;
  List<String>? _savedPaths;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
      _done = 0;
      _total = widget.advice.tripsToExport.length * 2;
    });
    try {
      final paths = await TripReportBackup.generate(
        widget.advice.tripsToExport,
        onProgress: (done, total) {
          if (mounted) setState(() => _done = done);
        },
      );
      if (!mounted) return;
      setState(() {
        _generating = false;
        _savedPaths = paths;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = 'Could not generate the reports. You can export them from '
            'each trip, or update without a backup.';
      });
    }
  }

  String _statusLine(TripReportStatus s) {
    String saved(DateTime? at) =>
        at == null ? 'missing' : _dateFormat.format(at);
    if (widget.advice.hasActiveTrips) {
      if (!s.hasExcel && !s.hasPdf) return 'No reports saved yet';
      return 'Excel: ${saved(s.excelSavedAt)} · PDF: ${saved(s.pdfSavedAt)}';
    }
    final missing = [if (!s.hasExcel) 'Excel', if (!s.hasPdf) 'PDF'];
    return '${s.trip.status} · Missing: ${missing.join(' and ')}';
  }

  @override
  Widget build(BuildContext context) {
    final advice = widget.advice;
    final items =
        advice.hasActiveTrips ? advice.activeTrips : advice.submittedMissing;
    final saved = _savedPaths;

    final intro = advice.hasActiveTrips
        ? 'Updating keeps your data, but it is safest to have a copy. '
              'Generate the Excel and PDF reports of your active '
              '${items.length == 1 ? 'trip' : 'trips'} before updating.'
        : 'You have no active trips. Make a backup copy of the Excel and PDF '
              'reports of these submitted trips, which have not been '
              'generated yet.';

    return PopScope(
      canPop: false,
      child: AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppDesign.screenHorizontalPadding,
          vertical: AppDesign.screenVerticalPadding,
        ),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: const Text('Back up your reports first'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intro, style: AppTextStyles.bodyMediumOf(context)),
              const Gap(12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.trip.name,
                              style: AppTextStyles.bodyMediumOf(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _statusLine(s),
                              style: AppTextStyles.captionOf(context),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (_generating) ...[
                const Gap(8),
                LinearProgressIndicator(
                  value: _total == 0 ? null : _done / _total,
                ),
                const Gap(6),
                Text(
                  'Generating reports… $_done of $_total',
                  style: AppTextStyles.captionOf(context),
                ),
              ],
              if (saved != null) ...[
                const Gap(8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        saved.isEmpty
                            ? 'No reports were saved.'
                            : 'Saved ${saved.length} '
                                  '${saved.length == 1 ? 'file' : 'files'} to '
                                  '${TripReportBackup.folderLabel(saved.first)}.',
                        style: AppTextStyles.bodySmallOf(context),
                      ),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const Gap(8),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmallOf(
                    context,
                  ).copyWith(color: AppDesign.error),
                ),
              ],
            ],
          ),
        ),
        actions: _generating
            ? const []
            : saved != null
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue update'),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Update without backup'),
                ),
                FilledButton(
                  onPressed: _generate,
                  child: const Text('Generate reports'),
                ),
              ],
      ),
    );
  }
}
