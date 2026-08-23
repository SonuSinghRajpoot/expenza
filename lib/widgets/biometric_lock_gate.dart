import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../core/services/biometric_service.dart';
import '../core/theme/app_design.dart';
import '../core/theme/app_text_styles.dart';

import 'app_logo.dart';

class BiometricLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const BiometricLockGate({super.key, required this.child});

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAuthenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Re-lock when app goes to background if lock is enabled
      final isLockEnabled = ref.read(appLockEnabledProvider);
      if (isLockEnabled) {
        ref.read(isAppUnlockedProvider.notifier).state = false;
      }
    } else if (state == AppLifecycleState.resumed) {
      final isLockEnabled = ref.read(appLockEnabledProvider);
      final isUnlocked = ref.read(isAppUnlockedProvider);
      if (isLockEnabled && !isUnlocked) {
        _checkAndAuthenticate();
      }
    }
  }

  Future<void> _checkAndAuthenticate() async {
    final isLockEnabled = ref.read(appLockEnabledProvider);
    if (!isLockEnabled) {
      ref.read(isAppUnlockedProvider.notifier).state = true;
      return;
    }

    if (_isAuthenticating) return;
    _isAuthenticating = true;

    final success = await BiometricService.authenticate();
    _isAuthenticating = false;

    if (mounted && success) {
      ref.read(isAppUnlockedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLockEnabled = ref.watch(appLockEnabledProvider);
    final isUnlocked = ref.watch(isAppUnlockedProvider);

    if (!isLockEnabled || isUnlocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: AppDesign.surfaceOf(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.screenHorizontalPadding * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 84),
                const Gap(24),
                Text(
                  'Expenza is Locked',
                  style: AppTextStyles.headline1Of(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(8),
                Text(
                  'Biometric authentication is required to access your expenses and financial logs.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMediumOf(context).copyWith(
                    color: AppDesign.textSecondaryOf(context),
                  ),
                ),
                const Gap(36),
                FilledButton.icon(
                  onPressed: _checkAndAuthenticate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppDesign.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDesign.buttonBorderRadius,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint, size: 22, color: Colors.white),
                  label: const Text(
                    'Unlock Expenza',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
