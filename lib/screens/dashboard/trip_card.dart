import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/trip.dart';
import '../trip_details/trip_details_screen.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/premium_icon.dart';
import '../../providers/trip_provider.dart';
import 'package:flutter/foundation.dart';

class TripCard extends ConsumerStatefulWidget {
  final Trip trip;
  final int? index; // Optional index for alternating colors
  final bool showStatusBadge; // Show/hide status badge
  final EdgeInsets? margin; // Optional margin override

  const TripCard({
    super.key,
    required this.trip,
    this.index,
    this.showStatusBadge = true, // Default to showing badge for backward compatibility
    this.margin,
  });

  @override
  ConsumerState<TripCard> createState() => _TripCardState();
}

class _TripCardState extends ConsumerState<TripCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isDark = context.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered && kIsWeb ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: widget.margin ??
              const EdgeInsets.only(bottom: AppDesign.elementSpacing),
          decoration: BoxDecoration(
            color: _getCardBackgroundColor(context, widget.trip),
            borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.black.withValues(alpha: isDark ? 0.25 : 0.08)
                    : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isHovered
                  ? AppDesign.primary.withValues(alpha: 0.3)
                  : AppDesign.borderOf(context),
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailsScreen(trip: widget.trip),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
            child: Padding(
              padding: AppDesign.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.trip.name,
                          style: AppTextStyles.headline2Of(context).copyWith(
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.showStatusBadge)
                        _StatusBadge(status: widget.trip.status)
                      else if (widget.trip.id != null)
                        _TripTotalAmount(tripId: widget.trip.id!),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      _buildInfoItem(
                        context,
                        AppIcons.calendar,
                        '${dateFormat.format(widget.trip.startDate)}${widget.trip.endDate != null ? ' - ${dateFormat.format(widget.trip.endDate!)}' : ''}',
                      ),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      _buildInfoItem(
                        context,
                        AppIcons.location,
                        widget.trip.cities.isNotEmpty
                            ? widget.trip.cities.join(', ')
                            : 'No cities',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get a subtle background color for the card based on trip status in Light and Dark modes
  Color _getCardBackgroundColor(BuildContext context, Trip trip) {
    final isDark = context.isDarkMode;

    if (isDark) {
      switch (trip.status) {
        case 'Active':
          return const Color(0xFF1B231F); // subtle neutral dark emerald
        case 'In-process':
          return AppDesign.darkSurfaceElevated; // neutral dark charcoal
        case 'Settled':
          return AppDesign.darkSurfaceElevated; // neutral dark charcoal
        default:
          return AppDesign.darkSurfaceElevated;
      }
    } else {
      switch (trip.status) {
        case 'Active':
          return const Color(0xFFF6FEF9);
        case 'In-process':
          return const Color(0xFFF7F9FD);
        case 'Settled':
          return const Color(0xFFF8F9FA);
        default:
          return const Color(0xFFFAFBFC);
      }
    }
  }

  Widget _buildInfoItem(BuildContext context, String svgPath, String text) {
    final textColor = AppDesign.textSecondaryOf(context);

    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumIcon(
            svgPath: svgPath,
            size: 16,
            color: textColor,
          ),
          const Gap(8),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.bodyMediumOf(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTotalAmount extends ConsumerWidget {
  final int tripId;

  const _TripTotalAmount({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = ref.watch(tripTotalAmountProvider(tripId));
    final isZero = totalAmount == 0.0;

    // Use textSecondary for zero, default primary text for non-zero
    final amountColor = isZero ? AppDesign.textSecondaryOf(context) : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '₹',
          style: AppTextStyles.headline2Of(context).copyWith(
            fontSize: 16,
            color: amountColor ?? AppDesign.textPrimaryOf(context),
          ),
        ),
        const Gap(4),
        Text(
          NumberFormat('#,##,##0').format(totalAmount),
          style: AppTextStyles.headline2Of(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case 'Active':
        color = AppDesign.success;
        break;
      case 'In-process':
        color = AppDesign.primary;
        break;
      case 'Settled':
        color = AppDesign.textSecondaryOf(context);
        break;
      default:
        color = AppDesign.textSecondaryOf(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmallOf(context).copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
