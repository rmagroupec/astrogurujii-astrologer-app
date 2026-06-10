// lib/service/incoming_call_router.dart
//
// SINGLE SOURCE OF TRUTH for routing an incoming call/chat in EVERY app state:
//   - foreground            -> handleForeground()
//   - background / killed    -> background isolate persists, app replays on show
//   - cold start / resume    -> handlePending()
//
// Why "persist + replay" instead of navigating from the notification:
//   A full-screen-intent LOCAL notification cold-starts the app to its normal
//   launch route. It does NOT fire FCM's getInitialMessage / onMessageOpenedApp
//   (those are only for FCM *notification* messages). So the first push used to
//   just open the app and do nothing -> user needed a 2nd push. We fix this by
//   having the background isolate persist the call, and the app reads + routes
//   it the moment it becomes visible (first frame AND on resume).

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:astrologer_app/service/localNotificationService.dart';

class IncomingCallRouter {
  static const _pendingKey = 'pending_incoming_call';
  static const _actionKey  = 'pending_call_action'; // 'accept' (or unset)
  static final _status     = CallStatusService();

  static bool _routing = false; // re-entrancy guard

  static bool isCallData(Map<String, dynamic> d) {
    final t = (d['type'] ?? '').toString();
    final n = (d['notification_type'] ?? '').toString();
    return n == 'initiate' || t == 'audio' || t == 'video' || t == 'chat';
  }

  // ── persistence ───────────────────────────────────────────────────────────
  static Future<void> persist(Map<String, dynamic> data,
      {bool accept = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode({
        ...data.map((k, v) => MapEntry(k, v.toString())),
        '_ts': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    if (accept) await prefs.setString(_actionKey, 'accept');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
    await prefs.remove(_actionKey);
  }

  // ── foreground ──────────────────────────────────────────────────────────--
  static Future<void> handleForeground(RemoteMessage message) async {
    final data = message.data;
    if (!isCallData(data)) return;
    if ((data['channel_id'] ?? '').toString().isEmpty) return;
    await route(data.map((k, v) => MapEntry(k, v.toString())));
  }

  // ── cold start / resume: replay a pending call ─────────────────────────────
  static Future<void> handlePending() async {
    if (_routing) return;

    final prefs = await SharedPreferences.getInstance();

    // (a) tapped the local notification body?
    Map<String, String>? data = await LocalNotificationService.launchPayload();

    // (b) or a call persisted by the background isolate?
    if (data == null) {
      final raw = prefs.getString(_pendingKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final ts = (decoded['_ts'] ?? 0) as int;
        if (DateTime.now().millisecondsSinceEpoch - ts < 60000) {
          data = decoded.map((k, v) => MapEntry(k, v.toString()));
        }
      }
    }

    if (data == null) return;

    final autoAccept = prefs.getString(_actionKey) == 'accept';

    _routing = true;
    try {
      await route(data, autoAccept: autoAccept);
    } finally {
      _routing = false;
      await clear();
    }
  }

  // ── the ONE routing function ───────────────────────────────────────────────
  static Future<void> route(
    Map<String, String> data, {
    bool autoAccept = false,
  }) async {
    final type      = data['type'] ?? '';
    final channelId = data['channel_id'] ?? '';
    final token     = data['agora_token'] ?? '';
    final userName  = data['user_name'] ?? '';
    final userImage = data['user_image'] ?? '';
    final userId    = data['user_id'] ?? '';

    if (channelId.isEmpty) return;

    final prefs   = await SharedPreferences.getInstance();
    final astroId = prefs.getString('astro_id') ?? '';

    // banner no longer needed once we have UI
    await LocalNotificationService.cancelCall(channelId);
    // never let a stale lock block navigation
    NavigationManager().reset();

    if (autoAccept) {
      await _status.updateCallStatus(channelId: channelId, status: 'accept_astro');
      switch (type) {
        case 'audio':
          await NavigationManager().openAudioCallScreen(
              channelId: channelId, token: token,
              userName: userName, userAvatar: userImage);
          break;
        case 'video':
          await NavigationManager().openVideoCallScreen(
              channelId: channelId, token: token,
              userName: userName, userAvatar: userImage);
          break;
        case 'chat':
          await NavigationManager().openChatScreen(
              channelId: channelId, astroId: astroId, userId: userId,
              userName: userName, userAvatar: userImage);
          break;
      }
      return;
    }

    switch (type) {
      case 'audio':
        await NavigationManager().showIncomingAudioCall(
            token: token, channelId: channelId,
            userName: userName, userAvatar: userImage);
        break;
      case 'video':
        await NavigationManager().showIncomingVideoCall(
            token: token, channelId: channelId,
            userName: userName, userAvatar: userImage);
        break;
      case 'chat':
        await NavigationManager().showIncomingChatRequest(
            requestId: channelId, userName: userName, userAvatar: userImage,
            messagePreview: 'Incoming chat request', channelId: channelId,
            userId: userId, astroId: astroId);
        break;
    }
  }
}