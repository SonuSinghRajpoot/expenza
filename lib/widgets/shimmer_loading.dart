import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../core/theme/app_design.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppDesign.isDark(context);
    final baseColor = isDark ? const Color(0xFF222222) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF333333) : const Color(0xFFF1F5F9);

    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    // Skip infinite repeating timer when running flutter tests
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return box;
    }

    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: highlightColor,
        );
  }
}

class TripCardSkeleton extends StatelessWidget {
  const TripCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDesign.cardDecoration(
        context: context,
        borderRadius: AppDesign.cardBorderRadius,
      ),
      padding: const EdgeInsets.all(AppDesign.cardInternalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerBox(width: 140, height: 20, borderRadius: 6),
              const ShimmerBox(width: 70, height: 24, borderRadius: 12),
            ],
          ),
          const Gap(12),
          const ShimmerBox(width: 180, height: 14, borderRadius: 4),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerBox(width: 100, height: 22, borderRadius: 6),
              const ShimmerBox(width: 80, height: 16, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class ExpenseCardSkeleton extends StatelessWidget {
  const ExpenseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDesign.cardDecoration(
        context: context,
        borderRadius: AppDesign.itemBorderRadius,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, borderRadius: 12),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 120, height: 16, borderRadius: 4),
                const Gap(8),
                const ShimmerBox(width: 180, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const Gap(12),
          const ShimmerBox(width: 65, height: 20, borderRadius: 6),
        ],
      ),
    );
  }
}

class SummaryCardSkeleton extends StatelessWidget {
  const SummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDesign.cardDecoration(
        context: context,
        borderRadius: AppDesign.cardBorderRadius,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 100, height: 16, borderRadius: 4),
              ShimmerBox(width: 80, height: 16, borderRadius: 4),
            ],
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 90, height: 28, borderRadius: 6),
              ShimmerBox(width: 90, height: 28, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}
