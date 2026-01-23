import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../models/trip.dart';
import '../../models/expense.dart';
import '../../models/advance.dart';
import '../../providers/trip_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/services/export_service.dart';

import '../dashboard/widgets/trip_form_dialog.dart';
import '../expense_form/expense_form.dart';
import '../expense_form/add_expense_options_dialog.dart';
import '../expense_form/expense_detail_view.dart';
import '../../services/gemini_service.dart';
import '../../providers/gemini_provider.dart';
import '../../core/utils/image_utils.dart';
import '../../core/constants/expense_constants.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/premium_icon.dart';
import 'package:permission_handler/permission_handler.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider(_trip.id!));
    final advancesAsync = ref.watch(advancesProvider(_trip.id!));
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            PremiumIcon(
              svgPath: AppIcons.map,
              size: 24,
              color: AppDesign.textPrimary,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                _trip.name,
                style: AppTextStyles.headline2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: AppDesign.appBarActionEndPadding),
              child: IconButton(
                icon: PremiumIcon(
                  svgPath: AppIcons.ellipsisVertical,
                  size: 24,
                  color: AppDesign.textPrimary,
                ),
                onPressed: () => _showActionsMenu(context),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(expensesProvider(_trip.id!).future),
        child: CustomScrollView(
          slivers: [
            // Trip Info Line
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.screenHorizontalPadding,
                  vertical: 12,
                ),
                color: AppDesign.surface,
                child: _buildTripInfoLine(dateFormat),
              ),
            ),
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppDesign.screenHorizontalPadding,
                  right: AppDesign.screenHorizontalPadding,
                  top: 12,
                  bottom: AppDesign.sectionSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(context),
                    if (_trip.status == 'In-process') const Gap(24),
                    _buildSummaryCard(context, expensesAsync, ref),
                    const Gap(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expenses and Advances',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                        ),
                        if (_trip.status == 'Active')
                          TextButton.icon(
                            onPressed: () => _showAddAdvanceDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Advance'),
                          ),
                        if (_trip.status == 'In-process' &&
                            _trip.submittedAt != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesign.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                const Gap(4),
                                Text(
                                  'Submitted ${dateFormat.format(_trip.submittedAt!)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_trip.status == 'Settled')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesign.textPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  color: Colors.blue,
                                  size: 14,
                                ),
                                const Gap(4),
                                Text(
                                  'Settled${_trip.submittedAt != null ? ' ${dateFormat.format(_trip.submittedAt!)}' : ''}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expenses and Advances List
            expensesAsync.when(
              data: (expenses) {
                return advancesAsync.when(
                  data: (advances) {
                    final allItems = <_ListItemWrapper>[];
                    if (_trip.status == 'Active') {
                      // Active: expenses first (display_order), then advances by date DESC — so drag reorder applies to expenses
                      for (final e in expenses) {
                        allItems.add(_ListItemWrapper.expense(e));
                      }
                      final sortedAdv = List<Advance>.from(advances)
                        ..sort((a, b) => b.date.compareTo(a.date));
                      for (final a in sortedAdv) {
                        allItems.add(_ListItemWrapper.advance(a));
                      }
                    } else {
                      // Non-Active: combined, sort by date (most recent first)
                      for (final e in expenses) {
                        allItems.add(_ListItemWrapper.expense(e));
                      }
                      for (final a in advances) {
                        allItems.add(_ListItemWrapper.advance(a));
                      }
                      allItems.sort((a, b) {
                        final aDate = a.isExpense ? a.expense!.startDate : a.advance!.date;
                        final bDate = b.isExpense ? b.expense!.startDate : b.advance!.date;
                        return bDate.compareTo(aDate);
                      });
                    }

                    if (allItems.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              Gap(16),
                              Text(
                                'No expenses or advances recorded yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_trip.status == 'Active') {
                      return SliverReorderableList(
                        itemCount: allItems.length,
                        onReorder: (oldIndex, newIndex) {
                          final n = expenses.length;
                          if (oldIndex >= n) return;
                          int newIdx = newIndex;
                          if (newIdx >= n) newIdx = n - 1;
                          if (newIdx < 0) newIdx = 0;
                          if (oldIndex < newIdx) newIdx--;
                          final reordered = List<Expense>.from(expenses);
                          final e = reordered.removeAt(oldIndex);
                          reordered.insert(newIdx, e);
                          ref.read(expensesProvider(_trip.id!).notifier).reorderExpenses(reordered);
                        },
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          if (item.isExpense) {
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('expense_${item.expense!.id}'),
                              index: index,
                              child: _ExpenseListItem(
                                expense: item.expense!,
                                onTap: () => _navigateToExpenseDetail(context, item.expense!),
                              ),
                            );
                          } else {
                            return _AdvanceListItem(
                              key: ValueKey('advance_${item.advance!.id}'),
                              advance: item.advance!,
                              onTap: () => _showAdvanceDialog(context, item.advance!),
                            );
                          }
                        },
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = allItems[index];
                        if (item.isExpense) {
                          return _ExpenseListItem(
                            key: ValueKey('expense_${item.expense!.id}'),
                            expense: item.expense!,
                            onTap: () => _navigateToExpenseDetail(context, item.expense!),
                          );
                        } else {
                          return _AdvanceListItem(
                            key: ValueKey('advance_${item.advance!.id}'),
                            advance: item.advance!,
                            onTap: () => _showAdvanceDialog(context, item.advance!),
                          );
                        }
                      }, childCount: allItems.length),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error loading advances: $err')),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
            const SliverGap(80), // Space for FAB if needed
          ],
        ),
      ),
      floatingActionButton: _trip.status == 'Active'
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddExpense(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
    );
  }

  void _showActionsMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
      ),
      color: AppDesign.surfaceElevated,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'EDIT',
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.smallSpacing,
            vertical: AppDesign.smallSpacing,
          ),
          child: Builder(
            builder: (context) {
              final textStyle = AppTextStyles.bodyMedium;
              final iconSize = textStyle.fontSize! + 2;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumIcon(
                    svgPath: AppIcons.edit,
                    size: iconSize,
                    color: AppDesign.textPrimary,
                  ),
                  const Gap(12),
                  Text(
                    'Edit Trip',
                    style: textStyle,
                  ),
                ],
              );
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'UPDATE_STATE',
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.smallSpacing,
            vertical: AppDesign.smallSpacing,
          ),
          child: Builder(
            builder: (context) {
              final textStyle = AppTextStyles.bodyMedium;
              final iconSize = textStyle.fontSize! + 2;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumIcon(
                    svgPath: AppIcons.clock,
                    size: iconSize,
                    color: AppDesign.textPrimary,
                  ),
                  const Gap(12),
                  Text(
                    'Update State',
                    style: textStyle,
                  ),
                ],
              );
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'EXCEL',
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.smallSpacing,
            vertical: AppDesign.smallSpacing,
          ),
          child: Builder(
            builder: (context) {
              final textStyle = AppTextStyles.bodyMedium;
              final iconSize = textStyle.fontSize! + 2;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: iconSize,
                    color: AppDesign.textPrimary,
                  ),
                  const Gap(12),
                  Text(
                    'Export Excel',
                    style: textStyle,
                  ),
                ],
              );
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'PDF',
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.smallSpacing,
            vertical: AppDesign.smallSpacing,
          ),
          child: Builder(
            builder: (context) {
              final textStyle = AppTextStyles.bodyMedium;
              final iconSize = textStyle.fontSize! + 2;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: iconSize,
                    color: AppDesign.textPrimary,
                  ),
                  const Gap(12),
                  Text(
                    'Export PDF',
                    style: textStyle,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'EDIT':
          _showEditDialog(context);
          break;
        case 'UPDATE_STATE':
          _showUpdateStateDialog(context);
          break;
        case 'EXCEL':
        case 'PDF':
          _handleExport(context, value);
          break;
      }
    });
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final updatedTrip = await showDialog<Trip>(
      context: context,
      builder: (ctx) => TripFormDialog(trip: _trip),
    );

    if (updatedTrip != null) {
      setState(() {
        _trip = updatedTrip;
      });
    }
  }

  Future<void> _showUpdateStateDialog(BuildContext context) async {
    // Map internal status to display status
    String getDisplayStatus(String internalStatus) {
      switch (internalStatus) {
        case 'Active':
          return 'Active';
        case 'In-process':
          return 'Submitted';
        case 'Settled':
          return 'Settled';
        default:
          return internalStatus;
      }
    }

    // Map display status to internal status
    String getInternalStatus(String displayStatus) {
      switch (displayStatus) {
        case 'Active':
          return 'Active';
        case 'Submitted':
          return 'In-process';
        case 'Settled':
          return 'Settled';
        default:
          return displayStatus;
      }
    }

    final currentDisplayStatus = getDisplayStatus(_trip.status);
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm:ss');

    final selectedStatus = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Trip State',
                style: AppTextStyles.headline2,
              ),
              const Gap(24),
              _StateTimeline(
                currentStatus: currentDisplayStatus,
                trip: _trip,
                dateFormat: dateFormat,
                onStatusSelected: (status) {
                  Navigator.pop(ctx, status);
                },
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedStatus != null && selectedStatus != currentDisplayStatus) {
      final newInternalStatus = getInternalStatus(selectedStatus);
      
      try {
        await ref.read(tripListProvider.notifier).updateTripStatus(
              _trip.id!,
              newInternalStatus,
            );

        // Refresh the trip
        final updatedTrips = await ref.read(tripListProvider.future);
        final updatedTrip = updatedTrips.firstWhere((t) => t.id == _trip.id);
        
        if (context.mounted) {
          setState(() {
            _trip = updatedTrip;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trip state updated to $selectedStatus'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating state: $e')),
          );
        }
      }
    }
  }

  Widget _buildTripInfoLine(DateFormat dateFormat) {
    // Map internal status to display status
    String getDisplayStatus(String internalStatus) {
      switch (internalStatus) {
        case 'Active':
          return 'Active';
        case 'In-process':
          return 'Submitted';
        case 'Settled':
          return 'Settled';
        default:
          return internalStatus;
      }
    }

    // Format date range
    final dateRange = _trip.endDate != null
        ? '${dateFormat.format(_trip.startDate)} - ${dateFormat.format(_trip.endDate!)}'
        : '${dateFormat.format(_trip.startDate)} • Ongoing';

    // Get number of locations
    final locationsCount = _trip.cities.length;
    final locationsText = locationsCount == 1 
        ? '1 Location'
        : '$locationsCount Locations';

    // Get current status
    final currentStatus = getDisplayStatus(_trip.status);

    return Row(
      children: [
        Text(
          dateRange,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesign.textSecondary,
          ),
        ),
        Text(
          ' | ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesign.textTertiary,
          ),
        ),
        Text(
          locationsText,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesign.textSecondary,
          ),
        ),
        Text(
          ' | ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesign.textTertiary,
          ),
        ),
        Text(
          currentStatus,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesign.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _handleExport(BuildContext context, String type) async {
    final expenses = ref.read(expensesProvider(_trip.id!)).value ?? [];
    final advances = ref.read(advancesProvider(_trip.id!)).value ?? [];

    try {
      if ((type == 'EXCEL' || type == 'PDF') && Platform.isAndroid) {
        await Permission.manageExternalStorage.request();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating $type...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Fetch fresh user profile data from repository (not cached)
      final userRepository = ref.read(userRepositoryProvider);
      final userProfile = await userRepository.getUserProfile();

      final service = ExportService();
      String? filePath;
      String fileType;
      
      if (type == 'EXCEL') {
        fileType = 'Excel';
        filePath = await service.exportToExcel(_trip, expenses, userProfile: userProfile, advances: advances);
      } else if (type == 'PDF') {
        fileType = 'PDF';
        filePath = await service.exportToPdf(_trip, expenses, userProfile: userProfile);
      } else if (type == 'REOPEN') {
        await _showReopenDialog(context);
        return;
      } else {
        return;
      }

      // Show success message
      if (context.mounted) {
        if (filePath != null) {
          final fileName = filePath.split('/').last;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fileType file saved: $fileName\nCheck Internal storage > Expenza (or app storage if access was denied)'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Web platform
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fileType file downloaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _showReopenDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reopen Trip?'),
        content: const Text(
          'This will allow you to add or edit expenses for this trip again. Submitting it again will update the submission date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(tripListProvider.notifier).reopenTrip(_trip.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip reopened successfully')),
          );
          Navigator.pop(context); // Go back to dashboard
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error reopening trip: $e')));
        }
      }
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_trip.status == 'In-process')
          _buildPillButton(
            context: context,
            icon: const Icon(Icons.settings_backup_restore, size: 18),
            label: 'Reopen',
            onPressed: () => _handleExport(context, 'REOPEN'),
          ),
      ],
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Pill button - keep 20 for rounded shape
        ),
        side: BorderSide(
          color: AppDesign.primary.withValues(alpha: 0.3),
        ),
        foregroundColor: AppDesign.primary,
      ),
    );
  }

  Widget _buildExportPillButton(BuildContext context) {
    return Builder(
      builder: (context) {
        return OutlinedButton.icon(
          onPressed: () {
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
            final RelativeRect position = RelativeRect.fromRect(
              Rect.fromPoints(
                button.localToGlobal(Offset.zero, ancestor: overlay),
                button.localToGlobal(button.size.bottomRight(Offset.zero),
                    ancestor: overlay),
              ),
              Offset.zero & overlay.size,
            );
            showMenu<String>(
              context: context,
              position: position,
              items: [
                const PopupMenuItem(
                  value: 'EXCEL',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart_outlined, size: 18),
                      Gap(8),
                      Text('Export Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'PDF',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 18),
                      Gap(8),
                      Text('Export PDF'),
                    ],
                  ),
                ),
              ],
            ).then((value) {
              if (value != null) {
                _handleExport(context, value);
              }
            });
          },
          icon: const PremiumIcon(svgPath: AppIcons.download),
          label: const Text('Export Report'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: AppDesign.primary.withValues(alpha: 0.3),
            ),
            foregroundColor: AppDesign.primary,
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    AsyncValue<List<Expense>> expensesAsync,
    WidgetRef ref,
  ) {
    final advancesAsync = ref.watch(advancesProvider(_trip.id!));

    final totalExpenses = expensesAsync.maybeWhen(
      data: (expenses) =>
          expenses.fold<double>(0, (sum, item) => sum + item.amount),
      orElse: () => 0.0,
    );

    final totalAdvances = advancesAsync.maybeWhen(
      data: (advances) =>
          advances.fold<double>(0, (sum, item) => sum + item.amount),
      orElse: () => 0.0,
    );

    // If no advances, show single card with only Expenses
    if (totalAdvances == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppDesign.cardDecoration(
          borderRadius: AppDesign.cardBorderRadius,
        ).copyWith(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppDesign.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: AppDesign.success,
                size: 28,
              ),
            ),
            const Gap(20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL SPENT',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              const Gap(4),
              Text(
                '₹ ${NumberFormat('#,##,##0').format(totalExpenses.round())}',
                style: AppTextStyles.headline1.copyWith(
                  fontSize: 28,
                ),
              ),
              ],
            ),
          ],
        ),
      );
    }

    // Show grouped card with Expenses, Advances, and Total Due
    final totalDue = totalExpenses - totalAdvances;
    return _GroupedSummaryCard(
      expenses: totalExpenses,
      advances: totalAdvances,
      totalDue: totalDue,
    );
  }

  void _showAddAdvanceDialog(BuildContext context) {
    final amountController = TextEditingController();
    final dateController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy');

    dateController.text = dateFormat.format(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppDesign.screenHorizontalPadding,
          vertical: AppDesign.screenVerticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppDesign.screenHorizontalPadding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Advance',
                style: AppTextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'Enter advance amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium,
              ),
              const Gap(16),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                  ),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: _trip.startDate.subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                    dateController.text = dateFormat.format(selectedDate);
                  }
                },
                style: AppTextStyles.bodyMedium,
              ),
              const Gap(16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                  ),
                ),
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
              ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            const Gap(8),
            FilledButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an amount'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Save advance
                try {
                  final advance = Advance(
                    tripId: _trip.id!,
                    amount: amount,
                    date: selectedDate,
                    notes: notesController.text.trim().isEmpty 
                        ? null 
                        : notesController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  await ref.read(advancesProvider(_trip.id!).notifier).addAdvance(advance);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Advance of ₹${amount.toStringAsFixed(2)} recorded for ${dateFormat.format(selectedDate)}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error saving advance: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Advance'),
            ),
          ],
        ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvanceDialog(BuildContext context, Advance advance) {
    final amountController = TextEditingController(text: advance.amount.toStringAsFixed(0));
    final dateController = TextEditingController();
    final notesController = TextEditingController(text: advance.notes ?? '');
    DateTime selectedDate = advance.date;
    final dateFormat = DateFormat('MMM dd, yyyy');

    dateController.text = dateFormat.format(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppDesign.screenHorizontalPadding,
          vertical: AppDesign.screenVerticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppDesign.screenHorizontalPadding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'View/Edit Advance',
                style: AppTextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          hintText: 'Enter advance amount',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMedium,
                        enabled: _trip.status == 'Active',
                      ),
                      const Gap(16),
                      TextField(
                        controller: dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                          ),
                        ),
                        readOnly: true,
                        onTap: _trip.status == 'Active' ? () async {
                          final pickedDate = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: _trip.startDate.subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            selectedDate = pickedDate;
                            dateController.text = dateFormat.format(selectedDate);
                          }
                        } : null,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const Gap(16),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Add any additional notes',
                          prefixIcon: const Icon(Icons.note_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                          ),
                        ),
                        maxLines: 3,
                        style: AppTextStyles.bodyMedium,
                        enabled: _trip.status == 'Active',
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_trip.status == 'Active')
                    TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: ctx,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Advance?'),
                            content: const Text(
                              'Are you sure you want to delete this advance entry?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && ctx.mounted) {
                          try {
                            await ref.read(advancesProvider(_trip.id!).notifier).deleteAdvance(advance.id!);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Advance deleted successfully')),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting advance: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                      if (_trip.status == 'Active') ...[
                        const Gap(8),
                        FilledButton(
                          onPressed: () async {
                            final amountText = amountController.text.trim();
                            if (amountText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter an amount'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final amount = double.tryParse(amountText);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid amount'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            // Update advance
                            try {
                              final updatedAdvance = advance.copyWith(
                                amount: amount,
                                date: selectedDate,
                                notes: notesController.text.trim().isEmpty 
                                    ? null 
                                    : notesController.text.trim(),
                              );

                              await ref.read(advancesProvider(_trip.id!).notifier).updateAdvance(updatedAdvance);
                              
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Advance updated successfully'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating advance: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddExpense(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AddExpenseOptionsDialog(
        heads: ExpenseConstants.heads,
        onOptionSelected: (head, subHead, isAiScan) async {
          if (isAiScan) {
            _processAiScan(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenseFormScreen(
                  tripId: _trip.id!,
                  initialHead: head,
                  initialSubHead: subHead,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _processAiScan(BuildContext context) async {
    final activeKeyAsync = ref.read(activeGeminiKeyProvider);
    final apiKey = activeKeyAsync.value?.apiKey;

    if (apiKey == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please configure an active Gemini API key in Profile settings first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show selection dialog for AI Scan source
    final List<String>? selectedPaths =
        await showModalBottomSheet<List<String>>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Gap(12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(12),
                Text(
                  'AI Scan Source',
                  style: AppTextStyles.headline2.copyWith(
                    fontSize: 18,
                  ),
                ),
                const Gap(16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesign.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius + 2),
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      color: AppDesign.primary,
                    ),
                  ),
                  title: Text(
                    'Smart Scan (Camera)',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () async {
                    final paths = await ImageUtils.scanDocument(context);
                    if (ctx.mounted) Navigator.pop(ctx, paths);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesign.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius + 2),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppDesign.primary,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () async {
                    final paths =
                        await ImageUtils.pickMultipleImagesFromGallery();
                    if (ctx.mounted) Navigator.pop(ctx, paths);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesign.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius + 2),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppDesign.primary,
                    ),
                  ),
                  title: Text(
                    'Upload PDF Document',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () async {
                    final paths = await ImageUtils.pickPdfAndConvert();
                    if (ctx.mounted) Navigator.pop(ctx, paths);
                  },
                ),
                const Gap(20),
              ],
            ),
          ),
        );

    if (selectedPaths == null || selectedPaths.isEmpty) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppDesign.screenHorizontalPadding * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const Gap(16),
                Text(
                  'AI Analyzing Bill...',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final geminiService = GeminiService();
    // Send first 2 pages (e.g. PDF) so from/to can be read from itinerary
    final result = await geminiService.analyzeBill(
      apiKey: apiKey,
      imagePaths: selectedPaths.take(2).toList(),
      availableHeads: ExpenseConstants.heads,
      availableSubHeads: ExpenseConstants.subHeads,
      tripLocations: _trip.cities,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Add image paths to result so it can be shown in form
    final initialData = result != null
        ? Map<String, dynamic>.from(result)
        : <String, dynamic>{};
    initialData['billPaths'] = selectedPaths;

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExpenseFormScreen(tripId: _trip.id!, initialData: initialData),
      ),
    );
  }

  void _navigateToExpenseDetail(BuildContext context, Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDetailViewScreen(
          expense: expense,
          trip: _trip,
        ),
      ),
    ).then((shouldEdit) {
      // If detail view returns true, navigate to edit
      if (shouldEdit == true && _trip.status == 'Active') {
        _navigateToEditExpense(context, expense);
      }
    });
  }

  void _navigateToEditExpense(BuildContext context, Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExpenseFormScreen(tripId: _trip.id!, expense: expense),
      ),
    );
  }
}

class _StateTimeline extends StatelessWidget {
  final String currentStatus;
  final Trip trip;
  final DateFormat dateFormat;
  final Function(String) onStatusSelected;

  const _StateTimeline({
    required this.currentStatus,
    required this.trip,
    required this.dateFormat,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get status index: Active=0, Submitted=1, Settled=2
    int getStatusIndex(String status) {
      switch (status) {
        case 'Active':
          return 0;
        case 'Submitted':
          return 1;
        case 'Settled':
          return 2;
        default:
          return 0;
      }
    }

    final currentIndex = getStatusIndex(currentStatus);
    final states = ['Active', 'Submitted', 'Settled'];

    // Get timestamp for each state
    DateTime? getStateTimestamp(String status) {
      switch (status) {
        case 'Active':
          return trip.lastModifiedAt;
        case 'Submitted':
          return trip.submittedAt;
        case 'Settled':
          // For settled, use submittedAt if available, otherwise lastModifiedAt
          return trip.submittedAt ?? trip.lastModifiedAt;
        default:
          return null;
      }
    }

    // Check if a state is selectable
    bool checkIsSelectable(int index) {
      // Can select next state (forward one step)
      if (index == currentIndex + 1) return true;
      // Can select any previous state (backward multiple steps)
      if (index < currentIndex) return true;
      return false;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shared vertical timeline line
        Column(
          children: states.asMap().entries.map((entry) {
            final index = entry.key;
            final isPast = index <= currentIndex;
            final isCurrent = states[index] == currentStatus;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast
                        ? AppDesign.primary
                        : AppDesign.borderDefault,
                    border: isCurrent
                        ? Border.all(color: AppDesign.primary, width: 3)
                        : null,
                  ),
                  child: isPast && !isCurrent
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (index < states.length - 1)
                  Container(
                    width: 2,
                    height: 60,
                    color: isPast ? AppDesign.primary : AppDesign.borderDefault,
                  ),
              ],
            );
          }).toList(),
        ),
        const Gap(16),
        // State details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: states.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isCurrent = status == currentStatus;
              final isSelectable = checkIsSelectable(index);
              final timestamp = getStateTimestamp(status);
              final isPast = index <= currentIndex;

              return InkWell(
                onTap: isSelectable ? () => onStatusSelected(status) : null,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 12,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  status,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelectable || isCurrent
                                        ? AppDesign.textPrimary
                                        : AppDesign.textTertiary,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const Gap(8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppDesign.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Current',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppDesign.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (timestamp != null) ...[
                              const Gap(4),
                              Text(
                                dateFormat.format(timestamp),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppDesign.textSecondary,
                                ),
                              ),
                            ] else if (!isPast) ...[
                              const Gap(4),
                              Text(
                                'Not yet updated',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppDesign.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelectable && !isCurrent)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppDesign.primary,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Helper class to combine expenses and advances in a single list
class _ListItemWrapper {
  final Expense? expense;
  final Advance? advance;
  final bool isExpense;

  _ListItemWrapper.expense(this.expense)
      : advance = null,
        isExpense = true;

  _ListItemWrapper.advance(this.advance)
      : expense = null,
        isExpense = false;
}

class _ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const _ExpenseListItem({
    required this.expense,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.head).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.head),
                    color: _getCategoryColor(expense.head),
                    size: 20,
                  ),
                ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense.subHead ?? expense.head,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      '${dateFormat.format(expense.startDate).toUpperCase()} • ${expense.city}${expense.toCity != null && expense.toCity != expense.city ? ' \u2192 ${expense.toCity}' : ''}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹ ${expense.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.headline2.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const Gap(2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (expense.notes != null &&
                          expense.notes!.isNotEmpty) ...[
                        Icon(
                          Icons.notes_rounded,
                          size: 12,
                          color: AppDesign.textTertiary,
                        ),
                        const Gap(4),
                      ],
                      _buildAttachmentIcon(expense.billPaths),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildAttachmentIcon(List<String> paths) {
    if (paths.isEmpty) {
      return Icon(
        Icons.file_open_outlined,
        size: 12,
        color: AppDesign.borderDefault,
      );
    }

    final path = paths.first;
    IconData icon;
    Color color;

    if (path.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf_outlined;
      color = AppDesign.error;
    } else {
      icon = paths.length > 1
          ? Icons.collections_outlined
          : Icons.image_outlined;
      color = AppDesign.primary;
    }

    return Icon(icon, size: 12, color: color);
  }

  IconData _getCategoryIcon(String head) {
    switch (head) {
      case 'Travel':
        return Icons.directions_car_outlined;
      case 'Accommodation':
        return Icons.hotel_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Event':
        return Icons.event_note_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _getCategoryColor(String head) {
    switch (head) {
      case 'Travel':
        return AppDesign.categoryTravel;
      case 'Accommodation':
        return AppDesign.categoryAccommodation;
      case 'Food':
        return AppDesign.categoryFood;
      case 'Event':
        return AppDesign.categoryEvent;
      default:
        return AppDesign.categoryMisc;
    }
  }
}

class _AdvanceListItem extends StatelessWidget {
  final Advance advance;
  final VoidCallback? onTap;

  const _AdvanceListItem({
    required this.advance,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppDesign.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: AppDesign.primary,
                  size: 20,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Advance',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      dateFormat.format(advance.date).toUpperCase(),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹ ${advance.amount.round()}',
                    style: AppTextStyles.headline2.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  if (advance.notes != null && advance.notes!.isNotEmpty) ...[
                    const Gap(2),
                    Icon(
                      Icons.notes_rounded,
                      size: 12,
                      color: AppDesign.textTertiary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupedSummaryCard extends StatelessWidget {
  final double expenses;
  final double advances;
  final double totalDue;

  const _GroupedSummaryCard({
    required this.expenses,
    required this.advances,
    required this.totalDue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDesign.cardDecoration(
        borderRadius: AppDesign.cardBorderRadius,
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              value: '₹ ${NumberFormat('#,##,##0').format(expenses.round())}',
              label: 'Expenses',
              color: AppDesign.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppDesign.borderDefault,
          ),
          Expanded(
            child: _buildStatItem(
              value: '₹ ${NumberFormat('#,##,##0').format(advances.round())}',
              label: 'Advances',
              color: AppDesign.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppDesign.borderDefault,
          ),
          Expanded(
            child: _buildStatItem(
              value: '₹ ${NumberFormat('#,##,##0').format(totalDue.round())}',
              label: 'Total Due',
              color: totalDue < 0 ? AppDesign.error : AppDesign.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.headline2.copyWith(
            fontSize: 20,
            height: 1.1,
            color: color,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppDesign.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
