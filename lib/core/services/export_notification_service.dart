import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

/// Handles notifications for export completion. Tapping opens the file.
class ExportNotificationService {
  static final ExportNotificationService _instance =
      ExportNotificationService._internal();
  factory ExportNotificationService() => _instance;

  ExportNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'expenza_export';
  static const String _channelName = 'Export Notifications';

  /// Initialize. Call from main() before runApp.
  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: 'Notifications when Excel or PDF export completes.',
              importance: Importance.defaultImportance,
            ),
          );
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      OpenFilex.open(payload);
    }
  }

  /// Show notification that export completed. Tap to open file.
  Future<void> showExportReady({
    required String filePath,
    required String fileType,
  }) async {
    if (!_initialized) return;
    if (kIsWeb) return;

    final fileName = filePath.replaceAll('\\', '/').split('/').last;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Tap to open exported file.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      '$fileType Export Ready',
      'Tap to open $fileName',
      details,
      payload: filePath,
    );
  }
}
