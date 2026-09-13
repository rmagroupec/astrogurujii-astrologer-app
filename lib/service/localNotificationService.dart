// lib/service/localNotificationService.dart
//
// PRODUCTION-GRADE: handles all 3 app states correctly
//
// ARCHITECTURE RULES (never break these):
//   1. Ringtone + vibration are owned NATIVELY by astro_call_kit's
//      CallRingtoneService (a real Android foreground service), NOT by
//      Dart — that's what lets ringing survive foreground, background,
//      AND fully-killed states identically. See packages/astro_call_kit.
//   2. Background isolate: persist data + show fullscreen notification,
//      then hand off to astro_call_kit so ringing keeps going after this
//      isolate is torn down a few seconds later.
//   3. Notification channel has NO sound/vibration (astro_call_kit owns
//      both, tied to the actual ring lifecycle instead of a one-shot
//      channel sound)
//   4. One notification ID per channel_id (hash) — prevents duplicates.
//      astro_call_kit's foreground service ADOPTS this exact notification
//      (same ID) instead of posting a second one.
//   5. cancelCall() always stops ringtone + cancels notification atomically

import 'dart:convert';
import 'dart:typed_data';

import 'package:astro_call_kit/astro_call_kit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  // ── Ringtone guard ────────────────────────────────────────────────────────
  // Local, best-effort mirror of native ring state for this isolate only —
  // the real source of truth is CallRingtoneService.isRinging on the native
  // side (see AstroCallKit.isRinging()), since ringing must be correct even
  // across isolates that don't share this static field.
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
          const AndroidNotificationChannel(
            _callChannelId,
            _callChannelName,
            description    : 'Audio, video, and chat calls from users',
            importance     : Importance.max,
            // ✅ Channel itself has NO sound — astro_call_kit's native
            //    foreground service owns the actual ringtone/vibration
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

    // One-shot pattern for the notification's own (silent-channel) buzz on
    // first post — continuous vibration for the full ring duration is
    // owned by astro_call_kit's native foreground service.
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
      // ✅ playSound: false — ringtone handled natively by astro_call_kit
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
  // RINGTONE + VIBRATION — now owned NATIVELY by astro_call_kit
  //
  // These are called from every app state: the main isolate (Incoming
  // screens' initState/dispose), the FCM background isolate
  // (firebaseMessagingBackgroundHandler), AND the notification-action
  // background isolate (onNotificationAction / onDidReceiveBackground-
  // NotificationResponse). All three isolates have astro_call_kit's
  // MethodChannel available because it is registered as a real Flutter
  // plugin (GeneratedPluginRegistrant attaches it to every FlutterEngine,
  // headless ones included) — a bare MethodChannel wired only in
  // MainActivity would NOT be reachable from the background isolates.
  //
  // The actual ringing/vibrating/auto-timeout lives in
  // packages/astro_call_kit's CallRingtoneService, a real Android
  // foreground service, so it survives long after whichever Dart isolate
  // triggered it has been torn down.
  // ─────────────────────────────────────────────────────────────────────────

  /// ✅ Start ringing for [channelId] — bypasses silent mode the same way a
  /// real phone call does (native `USAGE_NOTIFICATION_RINGTONE` + a CALL-
  /// category notification). Idempotent: safe to call again while already
  /// ringing for the same call (e.g. the Incoming screen re-confirming
  /// after the app resumes to the foreground).
  static Future<void> playRingtone(
    String channelId, {
    String title = 'Incoming Call',
    String body  = 'is calling',
  }) async {
    if (channelId.isEmpty) return;
    _ringing = true;
    await AstroCallKit.startRinging(
      channelId: channelId,
      notifId  : _notifId(channelId),
      title    : title,
      body     : body,
    );
  }

  /// Stop ringing + vibration. Safe to call multiple times, and safe to
  /// call from any isolate (see note above).
  static Future<void> stopRingtone() async {
    _ringing = false;
    await AstroCallKit.stopRinging();
  }

  /// Alias kept for existing call sites — stopping the native foreground
  /// service is inherently isolate-independent, so there is no longer a
  /// meaningful difference between "stop" and "force stop".
  static Future<void> forceStopRingtone() => stopRingtone();

  /// True if astro_call_kit currently believes it is ringing.
  static Future<bool> isRinging() => AstroCallKit.isRinging();

  // ─────────────────────────────────────────────────────────────────────────
  // VIBRATION — kept as no-op call-site shims.
  //
  // Vibration is now driven natively by CallRingtoneService for the exact
  // duration of the ring (tied to the same lifecycle as the ringtone
  // itself, including surviving app kill). These methods are kept so
  // existing call sites (IncomingCallScreen.initState/dispose) don't need
  // to change, but they intentionally do nothing anymore.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> startVibration() async {}
  static Future<void> stopVibration() async {}

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cancelCall(String channelId) async {
    await _plugin.cancel(_notifId(channelId));
    // Always stop native ringing alongside the notification — otherwise a
    // foreground-service-owned notification can outlive a plain cancel()
    // (Android won't let a plain NotificationManager.cancel() dismiss a
    // notification an active foreground service has adopted via
    // startForeground(); only that service calling stopForeground() can).
    await stopRingtone();
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