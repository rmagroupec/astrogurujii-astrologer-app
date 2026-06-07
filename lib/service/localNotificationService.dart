// lib/service/localNotificationService.dart  (ASTROLOGER APP — FINAL)
//
// Shows full-screen notification with Accept/Reject when app is bg/killed.
// Payload stores ALL fields needed for navigation on Accept tap.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String acceptAction = 'ACCEPT_CALL';
  static const String rejectAction = 'REJECT_CALL';

  static Future<void> initialize(
    void Function(NotificationResponse) onAction,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse          : onAction,
      onDidReceiveBackgroundNotificationResponse: onAction, // ← killed/bg
    );
  }

  // ── Show full-screen incoming call notification ───────────────────────────
  // Called from firebaseMessagingBackgroundHandler in main.dart
  static Future<void> showIncomingCall({
    required String              title,
    required String              body,
    required Map<String, String> payload,
  }) async {
    // Build payload string — encode values so special chars survive
    final payloadStr = payload.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final androidDetails = AndroidNotificationDetails(
      'astro_incoming_call',
      'Incoming Calls',
      channelDescription: 'Incoming call & chat from users',
      importance        : Importance.max,
      priority          : Priority.high,
      fullScreenIntent  : true,       // ← shows over lock screen
      category          : AndroidNotificationCategory.call,
      ongoing           : true,       // ← can't be swiped away
      autoCancel        : false,
      timeoutAfter      : 45000,      // auto-dismiss after 45 s
      actions           : const [
        AndroidNotificationAction(
          acceptAction,
          'Accept ✅',
          showsUserInterface: true,   // ← brings app to foreground
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          rejectAction,
          'Reject ❌',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      (payload['channel_id'] ?? 'call').hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payloadStr,
    );
  }

  static Future<void> cancelCall(String channelId) async {
    await _plugin.cancel(channelId.hashCode);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}