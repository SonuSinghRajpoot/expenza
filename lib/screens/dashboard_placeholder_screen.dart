import 'package:flutter/material.dart';
import '../core/theme/app_design.dart';
import '../core/theme/app_text_styles.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surfaceOf(context),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: AppTextStyles.headline1Of(context).copyWith(fontSize: 20),
        ),
        backgroundColor: AppDesign.surfaceElevatedOf(context),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Dashboard Coming Soon',
              style: AppTextStyles.headline2Of(context).copyWith(
                color: AppDesign.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Summary and analytics will appear here.',
              style: AppTextStyles.bodyMediumOf(context).copyWith(
                color: AppDesign.textTertiaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
