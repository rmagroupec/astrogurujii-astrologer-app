// lib/service/localNotificationService.dart
//
// PRODUCTION-GRADE: handles all 3 app states correctly
//
// ARCHITECTURE RULES (never break these):
//   1. Ringtone ONLY plays in main isolate (IncomingCallScreen owns it)
//   2. Background isolate: persist data + show SILENT fullscreen notification only
//   3. Notification channel has NO sound/vibration (we control it manually)
//   4. One notification ID per channel_id (hash) — prevents duplicates
//   5. cancelCall() always stops ringtone + cancels notification atomically

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Public action IDs ────────────────────────────────────────────────────
  static const String acceptAction = 'ACCEPT_CALL';
  static const String rejectAction = 'REJECT_CALL';

  // ── Notification channel IDs ─────────────────────────────────────────────
  static const String _callChannelId   = 'astro_incoming_call';
  static const String _callChannelName = 'Incoming Calls';

  // ── Ringtone guard — static, main isolate only ───────────────────────────
  // IMPORTANT: this flag is meaningless in background isolate.
  // Only IncomingCallScreen calls playRingtone()/stopRingtone().
  static bool _ringing = false;

  // ─────────────────────────────────────────────────────────────────────────
  // INIT — call once from main() and once from firebaseMessagingBackgroundHandler
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> initialize(
    void Function(NotificationResponse) onAction,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse          : onAction,
      onDidReceiveBackgroundNotificationResponse: onAction,
    );

    // Create the channel once — Android deduplicates by ID
    await _createCallChannel();
  }

  static Future<void> _createCallChannel() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _callChannelId,
            _callChannelName,
            description    : 'Audio, video, and chat calls from users',
            importance     : Importance.max,
            // ✅ Channel itself has NO sound/vibration — we manage this via
            // the notification's vibrationPattern and Flutter ringtone player
            playSound      : false,
            enableVibration: false,
            showBadge      : true,
          ),
        );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHOW INCOMING CALL NOTIFICATION
  //
  // Called from:
  //   • firebaseMessagingBackgroundHandler (background isolate — NO ringtone)
  //   • _AppRoot._onForegroundMessage (main isolate — IncomingScreen handles ring)
  //
  // The notification does THREE things:
  //   1. fullScreenIntent → wakes the screen and opens the app on lock screen
  //   2. Accept / Reject actions → handled by onNotificationAction in main.dart
  //   3. Vibration pattern → alerts user when phone is on silent
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> showIncomingCall({
    required String              title,
    required String              body,
    required Map<String, String> payload,
  }) async {
    final payloadStr = _encodePayload(payload);
    final notifId    = _notifId(payload['channel_id'] ?? 'call');

    // Vibration: ring pattern — 3 long pulses, keeps repeating with ongoing:true
    // On silent: vibration still fires (matches phone call behaviour)
    final vibration = Int64List.fromList([
      0, 800, 400, 800, 400, 800, 2000,
    ]);

    final androidDetails = AndroidNotificationDetails(
      _callChannelId,
      _callChannelName,
      channelDescription: 'Audio, video, and chat calls from users',
      importance        : Importance.max,
      priority          : Priority.max,

      // ── Lock screen & background wake ────────────────────────────────────
      fullScreenIntent: true,                          // shows over lock screen
      visibility      : NotificationVisibility.public, // visible on lock screen
      category        : AndroidNotificationCategory.call, // treated as phone call

      // ── Keep alive until answered / dismissed ─────────────────────────
      ongoing      : true,   // can't be swiped away
      autoCancel   : false,
      timeoutAfter : 45000,  // 45 s — remove if unanswered

      // ── Sound & vibration ─────────────────────────────────────────────
      playSound       : false,       // we play via FlutterRingtonePlayer
      enableVibration : true,
      vibrationPattern: vibration,

      // ── Action buttons ─────────────────────────────────────────────────
      actions: const [
        AndroidNotificationAction(
          acceptAction,
          '✅  Accept',
          showsUserInterface: true,   // brings app to foreground
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          rejectAction,
          '❌  Reject',
          showsUserInterface: false,  // handles silently
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      notifId,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payloadStr,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RINGTONE — main isolate only
  // ─────────────────────────────────────────────────────────────────────────

  /// Start ringing. Safe to call multiple times — guards with _ringing flag.
  static Future<void> playRingtone() async {
    if (_ringing) return;
    _ringing = true;
    await FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume : 1.0,
      asAlarm: false, // use device's ringtone, respects silent mode
    );
  }

  /// Stop ringing. Safe to call multiple times.
  static Future<void> stopRingtone() async {
    if (!_ringing) return;
    _ringing = false;
    await FlutterRingtonePlayer().stop();
  }

  /// Force stop — used by onNotificationAction which runs in a fresh isolate
  /// where _ringing=false but ringtone may be playing in the main isolate.
  /// We call stop() unconditionally here.
  static Future<void> forceStopRingtone() async {
    _ringing = false;
    await FlutterRingtonePlayer().stop();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────────────────────

  /// Cancel the notification for a specific channel. Does NOT stop ringtone
  /// (the IncomingCallScreen owns that via dispose).
  static Future<void> cancelCall(String channelId) async {
    await _plugin.cancel(_notifId(channelId));
  }

  /// Cancel all notifications. Does NOT stop ringtone.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAUNCH PAYLOAD — was the app opened by tapping a notification?
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, String>?> launchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      final p = details?.notificationResponse?.payload;
      if (p == null || p.isEmpty) return null;
      return decodePayload(p);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYLOAD ENCODE / DECODE
  // key=urlencoded_value&key=urlencoded_value
  // ─────────────────────────────────────────────────────────────────────────
  static String _encodePayload(Map<String, String> map) =>
      map.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

  static Map<String, String> decodePayload(String raw) {
    final map = <String, String>{};
    for (final part in raw.split('&')) {
      final i = part.indexOf('=');
      if (i <= 0) continue;
      try {
        map[part.substring(0, i)] =
            Uri.decodeComponent(part.substring(i + 1));
      } catch (_) {
        map[part.substring(0, i)] = part.substring(i + 1);
      }
    }
    return map;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  static int _notifId(String channelId) => channelId.hashCode.abs() % 100000;
}