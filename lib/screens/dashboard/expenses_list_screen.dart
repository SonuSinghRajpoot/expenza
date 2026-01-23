import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../providers/trip_provider.dart';
import '../../models/trip.dart';
import 'trip_card.dart';
import 'widgets/trip_form_dialog.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/premium_icon.dart';
import '../../core/services/error_handler.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  // Expansion state: Active expanded by default, others collapsed
  bool _activeExpanded = true;
  bool _submittedExpanded = false;
  bool _settledExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tripListAsync = ref.watch(tripListProvider);

    return Scaffold(
      backgroundColor: AppDesign.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100.0,
            floating: true,
            pinned: true,
            backgroundColor: AppDesign.surfaceElevated,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: AppDesign.screenHorizontalPadding,
                bottom: AppDesign.smallSpacing,
              ),
              title: Text(
                'Expenses',
                style: AppTextStyles.headline1,
              ),
              background: Container(color: AppDesign.surfaceElevated),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDesign.screenHorizontalPadding,
                AppDesign.smallSpacing,
                AppDesign.screenHorizontalPadding,
                AppDesign.smallSpacing, // Reduced from sectionSpacing to normalize gap
              ),
              child: _buildQuickStats(context, ref, tripListAsync),
            ),
          ),

          tripListAsync.when(
            data: (trips) {
              if (trips.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.luggage_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        Gap(16),
                        Text(
                          'No trips yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group trips by status
              final groupedTrips = _groupTripsByStatus(trips);

              // Build list of collapsible panels (only show non-empty statuses)
              final slivers = <Widget>[];
              
              // Active panel (expanded by default)
              if (groupedTrips['Active']?.isNotEmpty ?? false) {
                slivers.add(_CollapsibleStatusPanel(
                  status: 'Active',
                  statusLabel: 'Active Trips',
                  trips: groupedTrips['Active']!,
                  isExpanded: _activeExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _activeExpanded = expanded);
                  },
                  color: AppDesign.primary,
                  startIndex: 0,
                ));
              }

              // Submitted/In-process panel (collapsed by default)
              if (groupedTrips['In-process']?.isNotEmpty ?? false) {
                final activeCount = groupedTrips['Active']?.length ?? 0;
                slivers.add(_CollapsibleStatusPanel(
                  status: 'In-process',
                  statusLabel: 'Submitted Trips',
                  trips: groupedTrips['In-process']!,
                  isExpanded: _submittedExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _submittedExpanded = expanded);
                  },
                  color: AppDesign.textSecondary,
                  startIndex: activeCount,
                ));
              }

              // Settled panel (collapsed by default)
              if (groupedTrips['Settled']?.isNotEmpty ?? false) {
                final activeCount = groupedTrips['Active']?.length ?? 0;
                final submittedCount = groupedTrips['In-process']?.length ?? 0;
                slivers.add(_CollapsibleStatusPanel(
                  status: 'Settled',
                  statusLabel: 'Settled Trips',
                  trips: groupedTrips['Settled']!,
                  isExpanded: _settledExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _settledExpanded = expanded);
                  },
                  color: AppDesign.success,
                  startIndex: activeCount + submittedCount,
                ));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.screenHorizontalPadding,
                  vertical: AppDesign.screenVerticalPadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    slivers.map((widget) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDesign.sectionSpacing,
                        ),
                        child: widget,
                      );
                    }).toList(),
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text(ErrorHandler.getUserFriendlyMessage(err)))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTripDialog(context, ref);
        },
        backgroundColor: AppDesign.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Trip', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Trip>> tripsAsync,
  ) {
    return tripsAsync.maybeWhen(
      data: (trips) {
        final activeCount = trips.where((t) => t.status == 'Active').length;
        final inProcessCount = trips
            .where((t) => t.status == 'In-process')
            .length;
        final settledCount = trips.where((t) => t.status == 'Settled').length;

        return _GroupedStatCard(
          activeCount: activeCount,
          inProcessCount: inProcessCount,
          settledCount: settledCount,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  /// Group trips by status
  Map<String, List<Trip>> _groupTripsByStatus(List<Trip> trips) {
    final grouped = <String, List<Trip>>{
      'Active': [],
      'In-process': [],
      'Settled': [],
    };

    for (final trip in trips) {
      final status = trip.status;
      if (grouped.containsKey(status)) {
        grouped[status]!.add(trip);
      } else {
        // Handle unexpected statuses - add to appropriate category or default
        grouped['Active']!.add(trip);
      }
    }

    return grouped;
  }

  void _showAddTripDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => const TripFormDialog());
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String svgPath;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.svgPath,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: AppDesign.cardDecoration(
        borderRadius: AppDesign.itemBorderRadius,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius + 2),
            ),
            child: PremiumIcon(svgPath: svgPath, color: color, size: 20),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.headline2.copyWith(
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedStatCard extends StatelessWidget {
  final int activeCount;
  final int inProcessCount;
  final int settledCount;

  const _GroupedStatCard({
    required this.activeCount,
    required this.inProcessCount,
    required this.settledCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDesign.cardDecoration(
        borderRadius: AppDesign.itemBorderRadius,
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
              value: activeCount.toString(),
              label: 'Active',
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
              value: inProcessCount.toString(),
              label: 'Submitted',
              color: AppDesign.textSecondary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppDesign.borderDefault,
          ),
          Expanded(
            child: _buildStatItem(
              value: settledCount.toString(),
              label: 'Settled',
              color: AppDesign.success,
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

/// Collapsible panel for each trip status
class _CollapsibleStatusPanel extends StatelessWidget {
  final String status;
  final String statusLabel;
  final List<Trip> trips;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Color color;
  final int startIndex; // For maintaining animation index

  const _CollapsibleStatusPanel({
    required this.status,
    required this.statusLabel,
    required this.trips,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.color,
    required this.startIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(AppDesign.smallSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - clickable to expand/collapse
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
              ),
              child: Row(
                children: [
                  Text(
                    statusLabel,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      trips.length.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Content - animated expand/collapse with smooth vertical animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppDesign.smallSpacing),
                    child: Column(
                      children: trips.asMap().entries.map((entry) {
                        final index = entry.key;
                        final trip = entry.value;
                        final isLast = index == trips.length - 1;
                        // Remove bottom margin from last card to match container padding (8px)
                        // TripCard has bottom margin of 16px, so we pass margin: null and use EdgeInsets.zero
                        return TripCard(
                          trip: trip,
                          index: startIndex + index,
                          showStatusBadge: false, // Hide badge since trips are grouped by status
                          margin: isLast ? EdgeInsets.zero : null, // Remove margin for last card
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                            .slideX(begin: 0.1, end: 0);
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
