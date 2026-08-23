import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';

class AdvanceTrackerScreen extends StatelessWidget {
  const AdvanceTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surfaceOf(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            backgroundColor: AppDesign.surfaceElevatedOf(context),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: AppDesign.screenHorizontalPadding,
                bottom: AppDesign.elementSpacing,
              ),
              title: Text(
                'Advance',
                style: AppTextStyles.headline1Of(context),
              ),
              background: Container(color: AppDesign.surfaceElevatedOf(context)),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Gap(32),
                    Text(
                      'Advance Tracking coming soon',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline2Of(context),
                    ),
                    const Gap(12),
                    Text(
                      'Track cash advances and settlements across all your business trips.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMediumOf(context).copyWith(
                        color: AppDesign.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
