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
          margin: widget.margin ?? const EdgeInsets.only(bottom: AppDesign.elementSpacing),
          decoration: BoxDecoration(
              color: _getCardBackgroundColor(widget.trip),
              borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isHovered
                  ? AppDesign.primary.withValues(alpha: 0.2)
                  : AppDesign.borderDefault,
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
                          style: AppTextStyles.headline2.copyWith(
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
                        AppIcons.calendar,
                        '${dateFormat.format(widget.trip.startDate)}${widget.trip.endDate != null ? ' - ${dateFormat.format(widget.trip.endDate!)}' : ''}',
                      ),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      _buildInfoItem(
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

  /// Get a subtle background color for the card based on trip status
  /// Uses industry-standard subtle tints for better visual hierarchy
  /// Industry standard: very light tints (hex values like #F8FAFC, #FAFBFC) that add
  /// visual depth without compromising readability or appearing overcolored
  Color _getCardBackgroundColor(Trip trip) {
    // Very subtle status-based tinting (industry standard approach)
    // These are barely perceptible tints that add depth without being distracting
    switch (trip.status) {
      case 'Active':
        // Subtle green tint - barely perceptible, maintains excellent contrast
        return const Color(0xFFF6FEF9);
      case 'In-process':
        // Subtle blue tint - barely perceptible, maintains excellent contrast
        return const Color(0xFFF7F9FD);
      case 'Settled':
        // Subtle gray tint for settled/archived trips
        return const Color(0xFFF8F9FA);
      default:
        // Base subtle tinted white (industry standard: very light blue-gray tint)
        return const Color(0xFFFAFBFC);
    }
  }

  Widget _buildInfoItem(String svgPath, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumIcon(
            svgPath: svgPath,
            size: 16,
            color: AppDesign.textSecondary,
          ),
          const Gap(8),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppDesign.textSecondary,
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
    
    // Use textSecondary for zero, default color for non-zero
    final amountColor = isZero ? AppDesign.textSecondary : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '₹',
          style: AppTextStyles.headline2.copyWith(
            fontSize: 16,
            color: amountColor ?? AppDesign.textPrimary,
          ),
        ),
        const Gap(4),
        Text(
          NumberFormat('#,##,##0').format(totalAmount),
          style: AppTextStyles.headline2.copyWith(
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
        color = AppDesign.textSecondary;
        break;
      default:
        color = AppDesign.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
