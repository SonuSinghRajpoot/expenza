import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const String _prefAppLockKey = 'expenza_app_lock_enabled';
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if hardware supports biometrics / PIN lock
  static Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (e) {
      debugPrint('BiometricService.isDeviceSupported error: $e');
      return false;
    }
  }

  /// Read persisted App Lock preference
  static Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAppLockKey) ?? false;
  }

  /// Save App Lock preference
  static Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAppLockKey, enabled);
  }

  /// Prompt for Biometric / Device PIN Authentication
  static Future<bool> authenticate({
    String reason = 'Authenticate to access your financial records',
  }) async {
    if (kIsWeb) return true;
    try {
      final isAvailable = await isDeviceSupported();
      if (!isAvailable) return true;

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService.authenticate error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('BiometricService.authenticate unexpected error: $e');
      return false;
    }
  }
}

/// Provider for persistent App Lock setting state
final appLockEnabledProvider =
    StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier();
});

class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier([bool initial = false]) : super(initial) {
    if (!initial) {
      _loadPreference();
    }
  }

  Future<void> _loadPreference() async {
    final enabled = await BiometricService.isAppLockEnabled();
    state = enabled;
  }

  Future<bool> toggle(bool enabled) async {
    if (enabled) {
      // Prompt auth once before enabling to verify ownership
      final success = await BiometricService.authenticate(
        reason: 'Confirm biometrics or device PIN to enable App Lock',
      );
      if (!success) {
        return false;
      }
    }
    await BiometricService.setAppLockEnabled(enabled);
    state = enabled;
    return true;
  }
}

/// Session unlock state provider (resets to false on fresh launch)
final isAppUnlockedProvider = StateProvider<bool>((ref) => false);
