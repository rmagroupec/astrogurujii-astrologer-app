// lib/service/notificationService.dart
//
// FIXES:
// 1. ✅ _handleOpenedApp — retry loop waits for navigator before navigating
//       (fixes background/killed: notification body tap doing nothing)
// 2. ✅ Removed stale null-guard `if (nav == null) return` that fired immediately

import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _generateFCMToken();
      _fcm.onTokenRefresh.listen(_handleTokenRefresh);

      // ── Foreground handled by _AppRoot._onForegroundMessage() in app.dart ─
      // Do NOT add FirebaseMessaging.onMessage here — would show duplicate

      // ── Background: user tapped notification BODY (not action button) ─────
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

      // ── Killed: app opened via notification ──────────────────────────────
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        // Small delay so the Flutter engine finishes booting
        await Future.delayed(const Duration(milliseconds: 800));
        _handleOpenedApp(initial);
      }
    }
  }

  // ── Background / killed: notification body tapped → show IncomingCallScreen ─
  // ✅ FIX: retry loop waits up to 5s for navigator before navigating
 Future<void> _handleOpenedApp(RemoteMessage message) async {
  final data       = message.data;
  final type       = data['type'] ?? '';
  final channelId  = data['channel_id'] ?? '';
  final agoraToken = data['agora_token'] ?? '';
  final userName   = data['user_name']   ?? '';
  final userImage  = data['user_image']  ?? '';
  final userId     = data['user_id']     ?? '';

  debugPrint('📨 _handleOpenedApp: type=$type channel=$channelId');

  if (channelId.isEmpty) return;

  final prefs   = await SharedPreferences.getInstance();
  final astroId = prefs.getString('astro_id') ?? '';

  // ✅ Wait for navigator — app waking from background/killed
  int retries = 0;
  while (NavigationManager().navigatorKey.currentState == null && retries < 25) {
    await Future.delayed(const Duration(milliseconds: 200));
    retries++;
  }

  if (NavigationManager().navigatorKey.currentState == null) {
    debugPrint('❌ Navigator never ready in _handleOpenedApp');
    return;
  }

  // ✅ Reset stale locks so navigation is never blocked
  NavigationManager().reset();

  // ✅ Go DIRECTLY to incoming screen — not call screen
  if (type == 'video') {
    NavigationManager().showIncomingVideoCall(
      token     : agoraToken,
      channelId : channelId,
      userName  : userName,
      userAvatar: userImage,
    );
  } else if (type == 'audio') {
    NavigationManager().showIncomingAudioCall(
      token     : agoraToken,
      channelId : channelId,
      userName  : userName,
      userAvatar: userImage,
    );
  } else if (type == 'chat') {
    NavigationManager().showIncomingChatRequest(
      requestId     : channelId,
      userName      : userName,
      userAvatar    : userImage,
      messagePreview: 'Incoming chat request',
      channelId     : channelId,
      userId        : userId,
      astroId       : astroId,
    );
  }
}
  // ── Token management ──────────────────────────────────────────────────────
  Future<String?> _generateFCMToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');
        await _saveTokenLocally(_fcmToken!);
        await _sendTokenToBackend(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      print('❌ Error generating FCM token: $e');
      return null;
    }
  }

  void _handleTokenRefresh(String token) async {
    _fcmToken = token;
    await _saveTokenLocally(token);
    await _sendTokenToBackend(token);
  }

  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    await prefs.setInt(
        'fcm_token_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _sendTokenToBackend(String token) async {
    // Your existing implementation
    print('📤 Token to backend: $token');
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    await prefs.remove('fcm_token_timestamp');
    _fcmToken = null;
  }

  Future<String?> refreshToken() async {
    await _fcm.deleteToken();
    return await _generateFCMToken();
  }

  Future<void> subscribeToTopic(String topic) async =>
      _fcm.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) async =>
      _fcm.unsubscribeFromTopic(topic);
}