import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../screens/expense_form/expense_form.dart';
import '../screens/expense_form/add_expense_options_dialog.dart';
import '../core/constants/expense_constants.dart';
import '../core/services/biometric_service.dart';
import '../core/theme/app_design.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/permission_utils.dart';

class SharingListener extends ConsumerStatefulWidget {
  final Widget child;

  const SharingListener({super.key, required this.child});

  @override
  ConsumerState<SharingListener> createState() => _SharingListenerState();
}

class _SharingListenerState extends ConsumerState<SharingListener> {
  /// The same intent can be reported twice in quick succession (initial media
  /// plus stream on some devices). Identical shares inside this window are dropped.
  static const Duration _duplicateShareWindow = Duration(seconds: 3);

  StreamSubscription? _intentDataStreamSubscription;
  List<SharedMediaFile>? _pendingSharedFiles;

  /// Shares are processed strictly one after another so dialogs never stack.
  Future<void> _shareQueue = Future.value();
  String? _lastShareSignature;
  DateTime? _lastShareAt;

  bool _initialShareChecked = false;
  bool _launchedWithShare = false;
  bool _launchPermissionsRequested = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _initialShareChecked = true;
    } else {
      // For sharing files coming from outside the app while the app is in memory
      _intentDataStreamSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(
            _onSharedFiles,
            onError: (err) {
              debugPrint('SharingListener: getMediaStream error: $err');
            },
          );

      // For sharing files coming from outside the app while the app is closed
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((files) {
            _launchedWithShare = files.isNotEmpty;
            _onSharedFiles(files);
            // Mark the launch intent as consumed so it is never reported again.
            ReceiveSharingIntent.instance.reset();
          })
          .catchError((Object e) {
            debugPrint('SharingListener: getInitialMedia error: $e');
          })
          .whenComplete(() {
            _initialShareChecked = true;
            _maybeRequestLaunchPermissions();
          });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestLaunchPermissions();
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  bool get _isLocked =>
      ref.read(appLockEnabledProvider) && !ref.read(isAppUnlockedProvider);

  /// Launch-time permission prompts are deferred until the app is unlocked and
  /// no share is being handled. A permission dialog pauses the activity, which
  /// cancels an in-progress biometric prompt and competes with share dialogs.
  /// When the app was opened through a share we skip them for this session.
  void _maybeRequestLaunchPermissions() {
    if (!mounted || _launchPermissionsRequested) return;
    if (!_initialShareChecked || _launchedWithShare || _isLocked) return;
    _launchPermissionsRequested = true;
    _shareQueue = _shareQueue.then((_) async {
      if (mounted) await PermissionUtils.requestLaunchPermissions();
    });
  }

  void _onSharedFiles(List<SharedMediaFile> files) {
    if (!mounted) return;
    final validFiles = files.where((f) => f.path.isNotEmpty).toList();
    if (validFiles.isEmpty) return;

    final signature = (validFiles.map((f) => f.path).toList()..sort()).join('|');
    final now = DateTime.now();
    if (signature == _lastShareSignature &&
        _lastShareAt != null &&
        now.difference(_lastShareAt!) < _duplicateShareWindow) {
      debugPrint('SharingListener: Ignoring duplicate delivery of the same share.');
      return;
    }
    _lastShareSignature = signature;
    _lastShareAt = now;

    // If app lock is enabled and session is currently locked, queue files for post-unlock
    if (_isLocked) {
      debugPrint(
        'SharingListener: App is locked. Holding ${validFiles.length} shared files until unlock.',
      );
      _pendingSharedFiles = validFiles;
      return;
    }

    _enqueueShare(validFiles);
  }

  void _enqueueShare(List<SharedMediaFile> files) {
    _shareQueue = _shareQueue.then((_) => _handleSharedFiles(files));
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (!mounted) return;
    try {
      // 1. Check for Active Trips
      final trips = await _loadTrips();
      final activeTrips = trips.where((t) => t.status == 'Active').toList();

      if (activeTrips.isEmpty) {
        _showSnackBar('No active trips found to add expense to.');
        return;
      }

      Trip? selectedTrip;
      if (activeTrips.length == 1) {
        selectedTrip = activeTrips.first;
      } else if (mounted) {
        selectedTrip = await _showTripSelectionDialog(activeTrips);
      }

      if (selectedTrip == null) return; // User cancelled

      // Copy shared files to persistent storage so they survive app updates.
      // PDFs are always stored with a .pdf extension, even if shared without one.
      final persistentPaths = await ImageUtils.copyToBillsDir(
        files.map((f) => f.path).toList(),
      );

      if (mounted) {
        await _showAddExpenseOptionsFromShare(selectedTrip, persistentPaths);
      }
    } catch (e, st) {
      debugPrint('SharingListener: Failed to handle shared files: $e\n$st');
      _showSnackBar(
        'Could not open the shared file. Please try sharing it again.',
        isError: true,
      );
    }
  }

  /// Reads trips, retrying once with a fresh load if the provider is in an
  /// error state (e.g. the database failed to open during cold start).
  Future<List<Trip>> _loadTrips() async {
    try {
      return await ref.read(tripListProvider.future);
    } catch (e) {
      debugPrint('SharingListener: Trip load failed ($e). Retrying once.');
      ref.invalidate(tripListProvider);
      return await ref.read(tripListProvider.future);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : null,
      ),
    );
  }

  Future<Trip?> _showTripSelectionDialog(List<Trip> trips) async {
    return showDialog<Trip>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppDesign.screenHorizontalPadding,
          vertical: AppDesign.screenVerticalPadding,
        ),
        title: const Text('Select Trip'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final dateStr = DateFormat('MMM dd, yyyy').format(trip.startDate);
              return ListTile(
                title: Text(trip.name),
                subtitle: Text(dateStr),
                onTap: () => Navigator.pop(ctx, trip),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseOptionsFromShare(
    Trip trip,
    List<String> filePaths,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AddExpenseOptionsDialog(
        heads: ExpenseConstants.heads,
        onOptionSelected: (head, subHead, isAiScan) {
          if (!mounted) return;
          // For AI scan the form converts PDFs to page images itself, behind its
          // progress indicator, so the screen opens immediately.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExpenseFormScreen(
                tripId: trip.id!,
                initialData: isAiScan
                    ? {'billPaths': filePaths, 'autoAnalyze': true}
                    : {
                        'billPaths': filePaths,
                        'head': head,
                        'subHead': subHead,
                      },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for biometric unlock: if there are pending shared files, process them immediately
    ref.listen<bool>(isAppUnlockedProvider, (previous, isUnlocked) {
      if (!isUnlocked) return;
      final pending = _pendingSharedFiles;
      _pendingSharedFiles = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (pending != null && pending.isNotEmpty) {
          _enqueueShare(pending);
        }
        _maybeRequestLaunchPermissions();
      });
    });

    return widget.child;
  }
}
