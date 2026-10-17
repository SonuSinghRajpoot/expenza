import 'dart:async';

/// Tracks files being shared into the app, so other startup prompts (such as
/// the update check) never interrupt a share.
class ShareSession {
  ShareSession._();

  static final Completer<void> _initialShareChecked = Completer<void>();
  static bool _launchedWithShare = false;
  static int _activeShares = 0;
  static bool _hasPendingShare = false;

  /// Completes once the app knows whether it was launched by a share.
  static Future<void> get initialShareChecked => _initialShareChecked.future;

  /// True when this app launch was started by sharing a file into the app.
  static bool get launchedWithShare => _launchedWithShare;

  /// True while a share is being handled or is waiting for the app to unlock.
  static bool get isHandlingShare => _activeShares > 0 || _hasPendingShare;

  static void markInitialShareChecked({required bool launchedWithShare}) {
    if (_initialShareChecked.isCompleted) return;
    _launchedWithShare = launchedWithShare;
    _initialShareChecked.complete();
  }

  static void begin() => _activeShares++;

  static void end() {
    if (_activeShares > 0) _activeShares--;
  }

  static set hasPendingShare(bool value) => _hasPendingShare = value;
}
