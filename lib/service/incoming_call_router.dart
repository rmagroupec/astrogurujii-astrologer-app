// lib/service/incoming_call_router.dart
//
// SINGLE SOURCE OF TRUTH — routes incoming call/chat in every app state:
//
//   APP STATE           FLOW
//   ─────────────────────────────────────────────────────────────────────────
//   Foreground          FCM → _AppRoot._onForegroundMessage
//                       → showIncomingCall (notification fullScreenIntent)
//                       → IncomingCallRouter.handlePending() shows IncomingScreen
//
//   Background          FCM background isolate → firebaseMessagingBackgroundHandler
//                       → persist(data) + showIncomingCall (silent fullscreen)
//                       → user taps notification → app resumes → handlePending()
//                       → IncomingScreen shown
//
//   Killed              Same as background, but app cold-starts on tap
//                       → _AppRoot.initState → handlePending()
//
//   Lock screen         fullScreenIntent wakes screen, user sees notification
//                       Accept button → onNotificationAction persist(accept:true)
//                       → app resumes → handlePending(autoAccept:true)
//                       → directly opens call screen
//
//   Notification body   _plugin.getNotificationAppLaunchDetails or
//   tap (killed)        handlePending reads launchPayload

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:astrologer_app/service/localNotificationService.dart';

class IncomingCallRouter {
  IncomingCallRouter._();

  static const _pendingKey = 'pending_incoming_call';
  static const _actionKey  = 'pending_call_action';   // 'accept' when set
  static const _callTtlMs  = 90000;                   // 90 s TTL for pending call

  static final _status = CallStatusService();

  // Re-entrancy guard — prevents double-navigation when both
  // launchPayload AND pendingKey fire on the same cold start.
  static bool _routing = false;

  // ─────────────────────────────────────────────────────────────────────────
  // TYPE CHECK
  // ─────────────────────────────────────────────────────────────────────────
  static bool isCallData(Map<String, dynamic> d) {
    final t = (d['type']              ?? '').toString().toLowerCase();
    final n = (d['notification_type'] ?? '').toString().toLowerCase();
    return n == 'initiate' || t == 'audio' || t == 'video' || t == 'chat';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERSIST / CLEAR
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> persist(
    Map<String, dynamic> data, {
    bool accept = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode({
        ...data.map((k, v) => MapEntry(k, v.toString())),
        '_ts': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    if (accept) {
      await prefs.setString(_actionKey, 'accept');
    } else {
      await prefs.remove(_actionKey);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
    await prefs.remove(_actionKey);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FOREGROUND ENTRY POINT
  // Called from _AppRoot._onForegroundMessage — DO NOT play ringtone here.
  // The IncomingCallScreen plays ringtone via LocalNotificationService.playRingtone().
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> handleForeground(RemoteMessage message) async {
    final data = message.data;
    if (!isCallData(data)) return;
    if ((data['channel_id'] ?? '').toString().isEmpty) return;

    // Persist so handlePending() can navigate when the frame is ready
    await persist(data.map((k, v) => MapEntry(k, v.toString())));

    // Show fullscreen notification — this is what wakes the lock screen
    // and brings the app forward. The actual incoming screen is shown
    // by handlePending() in _AppRoot.initState / didChangeAppLifecycleState.
    await LocalNotificationService.showIncomingCall(
      title  : data['title']     ?? 'Incoming Call',
      body   : '${data['user_name'] ?? 'Someone'} is calling',
      payload: data.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESUME / COLD-START ENTRY POINT
  // Called from _AppRoot.initState (first frame) AND didChangeAppLifecycleState.
  // Safe to call multiple times — re-entrancy guard prevents double navigation.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> handlePending() async {
    if (_routing) return;

    final prefs = await SharedPreferences.getInstance();

    // Priority 1: app launched by notification tap
    Map<String, String>? data = await LocalNotificationService.launchPayload();

    // Priority 2: call persisted by background/foreground isolate
    if (data == null) {
      final raw = prefs.getString(_pendingKey);
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final ts      = (decoded['_ts'] as num?)?.toInt() ?? 0;
          final age     = DateTime.now().millisecondsSinceEpoch - ts;
          if (age < _callTtlMs) {
            data = decoded.map((k, v) => MapEntry(k, v.toString()));
          }
        } catch (_) {}
      }
    }

    if (data == null) return;

    final autoAccept = prefs.getString(_actionKey) == 'accept';

    _routing = true;
    try {
      // ✅ Clear BEFORE routing — if the app is killed mid-call, the pending
      // data is already gone so a restart won't re-show the incoming screen.
      await clear();
      await _route(data, autoAccept: autoAccept);
    } finally {
      _routing = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CORE ROUTING — determines which screen to open
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _route(
    Map<String, String> data, {
    bool autoAccept = false,
  }) async {
    final type      = (data['type'] ?? '').toLowerCase();
    final channelId = data['channel_id'] ?? '';
    final token     = data['agora_token'] ?? '';
    final userName  = data['user_name']  ?? '';
    final userImage = data['user_image'] ?? '';
    final userId    = data['user_id']    ?? '';

    if (channelId.isEmpty) return;

    // Cancel the system notification — IncomingScreen takes over UI
    await LocalNotificationService.cancelCall(channelId);

    // Reset any stale navigation locks from a previous session
    NavigationManager().reset();

    final prefs   = await SharedPreferences.getInstance();
    final astroId = prefs.getString('astro_id') ?? '';

    if (autoAccept) {
      // User tapped Accept on the lock-screen / notification — skip IncomingScreen
      await _status.updateCallStatus(channelId: channelId, status: 'accept_astro');
      switch (type) {
        case 'audio':
          await NavigationManager().openAudioCallScreen(
            channelId : channelId, token: token,
            userName  : userName,  userAvatar: userImage);
        case 'video':
          await NavigationManager().openVideoCallScreen(
            channelId : channelId, token: token,
            userName  : userName,  userAvatar: userImage);
        case 'chat':
          await NavigationManager().openChatScreen(
            channelId : channelId, astroId: astroId, userId: userId,
            userName  : userName,  userAvatar: userImage);
      }
      return;
    }

    // Show the full incoming screen so the astrologer can accept/reject
    switch (type) {
      case 'audio':
        await NavigationManager().showIncomingAudioCall(
          token     : token,     channelId: channelId,
          userName  : userName,  userAvatar: userImage);
      case 'video':
        await NavigationManager().showIncomingVideoCall(
          token     : token,     channelId: channelId,
          userName  : userName,  userAvatar: userImage);
      case 'chat':
        await NavigationManager().showIncomingChatRequest(
          requestId     : channelId,
          userName      : userName,
          userAvatar    : userImage,
          messagePreview: 'Incoming chat request',
          channelId     : channelId,
          userId        : userId,
          astroId       : astroId);
    }
  }
}