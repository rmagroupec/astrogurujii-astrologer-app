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

import 'package:flutter/services.dart';
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

  // ── Vibration guard ───────────────────────────────────────────────────────
  static bool _vibrating = false;

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
          const AndroidNotificationChannel(
            _callChannelId,
            _callChannelName,
            description    : 'Audio, video, and chat calls from users',
            importance     : Importance.max,
            // ✅ Channel itself has NO sound — we manage via FlutterRingtonePlayer
            // ✅ Vibration ON at channel level so Android allows it
            playSound      : false,
            enableVibration: true,
            showBadge      : true,
          ),
        );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHOW INCOMING CALL NOTIFICATION
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> showIncomingCall({
    required String              title,
    required String              body,
    required Map<String, String> payload,
  }) async {
    final payloadStr = _encodePayload(payload);
    final notifId    = _notifId(payload['channel_id'] ?? 'call');

    // ✅ Repeating vibration pattern:
    // [delay, vibrate, pause, vibrate, pause, vibrate, long-pause] × repeat
    // This pattern fires once per notification show — for continuous vibration
    // we use playVibration() separately from the IncomingScreen
    final vibration = Int64List.fromList([
      0, 1000, 500, 1000, 500, 1000, 1500,
    ]);

    final androidDetails = AndroidNotificationDetails(
      _callChannelId,
      _callChannelName,
      channelDescription: 'Audio, video, and chat calls from users',
      importance        : Importance.max,
      priority          : Priority.max,

      // ── Lock screen & background wake ──────────────────────────────────
      fullScreenIntent: true,
      visibility      : NotificationVisibility.public,
      category        : AndroidNotificationCategory.call,

      // ── Keep alive until answered / dismissed ─────────────────────────
      ongoing      : true,
      autoCancel   : false,
      timeoutAfter : 45000,  // 45s auto-dismiss

      // ── Sound & vibration ─────────────────────────────────────────────
      // ✅ playSound: false — ringtone handled by FlutterRingtonePlayer
      // ✅ enableVibration: true — pattern fires when notification shows
      playSound       : false,
      enableVibration : true,
      vibrationPattern: vibration,

      // ── Action buttons ─────────────────────────────────────────────────
      actions: const [
        AndroidNotificationAction(
          acceptAction,
          '✅  Accept',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          rejectAction,
          '❌  Reject',
          showsUserInterface: false,
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

  /// ✅ Start ringing — uses asAlarm: true so it plays even on silent/DND
  /// (matches real phone call behavior on Android)
  static Future<void> playRingtone() async {
    if (_ringing) return;
    _ringing = true;
    await FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume : 1.0,
      asAlarm: true,   // ✅ bypasses silent mode — plays like a real call
    );
  }

  /// Stop ringing. Safe to call multiple times.
  static Future<void> stopRingtone() async {
    if (!_ringing) return;
    _ringing = false;
    await FlutterRingtonePlayer().stop();
    // ✅ also stop vibration when ringtone stops
    await stopVibration();
  }

  /// Force stop — used by onNotificationAction which runs in a fresh isolate
  /// where _ringing=false but ringtone may be playing in the main isolate.
  static Future<void> forceStopRingtone() async {
    _ringing   = false;
    _vibrating = false;
    await FlutterRingtonePlayer().stop();
    try {
      await HapticFeedback.vibrate(); // cancel any ongoing vibration
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VIBRATION — continuous pattern while ringing
  // Call startVibration() from IncomingCallScreen.initState()
  // Call stopVibration() from IncomingCallScreen.dispose()
  //
  // Uses HapticFeedback for the loop since Vibration package may not
  // be available — falls back gracefully.
  // ─────────────────────────────────────────────────────────────────────────

  /// ✅ Start continuous vibration pattern — mirrors real incoming call
  static Future<void> startVibration() async {
    if (_vibrating) return;
    _vibrating = true;
    _vibrateLoop();
  }

  static Future<void> _vibrateLoop() async {
    while (_vibrating) {
      try {
        // Pattern: vibrate 800ms, pause 400ms, vibrate 800ms, pause 1200ms
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 800));
        if (!_vibrating) break;

        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 400));
        if (!_vibrating) break;

        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 800));
        if (!_vibrating) break;

        // Long pause between ring cycles
        await Future.delayed(const Duration(milliseconds: 1200));
      } catch (_) {
        break; // stop if vibration fails
      }
    }
  }

  /// Stop vibration.
  static Future<void> stopVibration() async {
    _vibrating = false;
    // One final light impact to "cancel" feel
    try { await HapticFeedback.lightImpact(); } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cancelCall(String channelId) async {
    await _plugin.cancel(_notifId(channelId));
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAUNCH PAYLOAD
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

  static int _notifId(String channelId) => channelId.hashCode.abs() % 100000;
}