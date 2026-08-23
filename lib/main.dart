import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/biometric_service.dart';
import 'core/services/export_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/permission_utils.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'widgets/biometric_lock_gate.dart';
import 'widgets/sharing_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Modern Android Edge-to-Edge System UI mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await ExportNotificationService().initialize();
  final isLockEnabled = await BiometricService.isAppLockEnabled();

  runApp(
    ProviderScope(
      overrides: [
        appLockEnabledProvider.overrideWith(
          (ref) => AppLockNotifier(isLockEnabled),
        ),
      ],
      child: const FieldExpenseApp(),
    ),
  );
}

class FieldExpenseApp extends ConsumerWidget {
  const FieldExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Expenza',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.getSystemUiOverlayStyle(brightness),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SharingListener(
        child: BiometricLockGate(
          child: MainNavigationScreen(),
        ),
      ),
    );
  }
}
