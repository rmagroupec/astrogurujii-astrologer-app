import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String acceptAction = 'ACCEPT_CALL';
  static const String rejectAction = 'REJECT_CALL';
  static Future<void> initialize(
    Function(NotificationResponse) onAction,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onAction,
      onDidReceiveBackgroundNotificationResponse: onAction, // 🔥 REQUIRED
    );
  }

  static Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'incoming_chat',
      'Incoming Chat',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      ticker: 'ticker',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, notificationDetails);
  }

  static Future<void> showIncomingCall({
    required String title,
    required String body,
    required Map<String, String> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'incoming_call',
      'Incoming Call',
      channelDescription: 'Incoming chat/call requests',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      actions: [
        AndroidNotificationAction(
          acceptAction,
          'Accept',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          rejectAction,
          'Reject',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload.entries.map((e) => '${e.key}=${e.value}').join('&'),
    );
  }
}
