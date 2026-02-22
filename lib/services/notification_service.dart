import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _plugin;

  static Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    _plugin = plugin;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
  }

  static Future<void> showProgress({
    required String title,
    required String body,
    required int progress,
    int id = 1,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'pdf_operations',
      'PDF Operations',
      channelDescription: 'Shows progress of PDF operations',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      ongoing: progress < 100,
    );

    await _plugin?.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showComplete({
    required String title,
    required String body,
    int id = 1,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pdf_operations',
      'PDF Operations',
      channelDescription: 'Shows progress of PDF operations',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin?.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancel(int id) async {
    await _plugin?.cancel(id);
  }
}
