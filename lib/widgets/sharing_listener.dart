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
  StreamSubscription? _intentDataStreamSubscription;
  bool _launchPermissionsRequested = false;
  List<SharedMediaFile>? _pendingSharedFiles;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_launchPermissionsRequested) {
        _launchPermissionsRequested = true;
        PermissionUtils.requestLaunchPermissions();
      }
    });

    if (!kIsWeb) {
      // For sharing images coming from outside the app while the app is in the memory
      _intentDataStreamSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(
            (List<SharedMediaFile> value) {
              if (mounted) {
                _handleSharedFiles(value);
              }
            },
            onError: (err) {
              debugPrint("getMediaStream error: $err");
            },
          );

      // For sharing images coming from outside the app while the app is closed
      ReceiveSharingIntent.instance.getInitialMedia().then((
        List<SharedMediaFile> value,
      ) {
        if (mounted) {
          _handleSharedFiles(value);
        }
      });
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    // Filter for valid files (Image/PDF)
    final validFiles = files.where((f) => f.path.isNotEmpty).toList();
    if (validFiles.isEmpty) return;

    // If app lock is enabled and session is currently locked, queue files for post-unlock
    final isLockEnabled = ref.read(appLockEnabledProvider);
    final isUnlocked = ref.read(isAppUnlockedProvider);
    if (isLockEnabled && !isUnlocked) {
      debugPrint('SharingListener: App is locked. Holding ${validFiles.length} shared files until unlock.');
      _pendingSharedFiles = validFiles;
      return;
    }

    // 1. Check for Active Trips
    // We use ref.read(tripListProvider.future) to ensure we get the latest data
    final trips = await ref.read(tripListProvider.future);

    final activeTrips = trips.where((t) => t.status == 'Active').toList();

    if (activeTrips.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active trips found to add expense to.'),
          ),
        );
      }
      return;
    }

    Trip? selectedTrip;

    if (activeTrips.length == 1) {
      selectedTrip = activeTrips.first;
    } else {
      if (mounted) {
        selectedTrip = await _showTripSelectionDialog(activeTrips);
      }
    }

    if (selectedTrip == null) return; // User cancelled

    // Copy shared files to persistent storage so they survive app updates
    final persistentPaths = await ImageUtils.copyToBillsDir(
      validFiles.map((f) => f.path).toList(),
    );

    if (mounted) {
      _showAddExpenseOptionsFromShare(selectedTrip, persistentPaths);
    }
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

  void _showAddExpenseOptionsFromShare(Trip trip, List<String> filePaths) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AddExpenseOptionsDialog(
        heads: ExpenseConstants.heads,
        onOptionSelected: (head, subHead, isAiScan) async {
          if (isAiScan) {
            await _navigateToExpenseFormWithAiScan(trip, filePaths);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExpenseFormScreen(
                  tripId: trip.id!,
                  initialData: {
                    'billPaths': filePaths,
                    'head': head,
                    'subHead': subHead,
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// Converts shared PDFs to images and navigates to expense form with AI analysis.
  /// Ensures parity with Add Expense button flow where PDFs are converted before AI.
  Future<void> _navigateToExpenseFormWithAiScan(
    Trip trip,
    List<String> filePaths,
  ) async {
    // Convert PDFs to images so Gemini can analyze (same as Add Expense + PDF flow)
    final pathsForAi = await ImageUtils.convertPdfPathsToImages(filePaths);
    if (pathsForAi.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid images to analyze.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(
          tripId: trip.id!,
          initialData: {
            'billPaths': pathsForAi,
            'autoAnalyze': true,
          },
        ),
      ),
    );
  }

  void _requestLaunchPermissions() {
    if (_launchPermissionsRequested) return;
    _launchPermissionsRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionUtils.requestLaunchPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    _requestLaunchPermissions();

    // Listen for biometric unlock: if there are pending shared files, process them immediately
    ref.listen<bool>(isAppUnlockedProvider, (previous, isUnlocked) {
      if (isUnlocked &&
          _pendingSharedFiles != null &&
          _pendingSharedFiles!.isNotEmpty) {
        final filesToProcess = List<SharedMediaFile>.from(_pendingSharedFiles!);
        _pendingSharedFiles = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleSharedFiles(filesToProcess);
          }
        });
      }
    });

    return widget.child;
  }
}
