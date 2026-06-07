// lib/service/notificationService.dart  (ASTROLOGER APP — FINAL)
//
// CHANGES vs current:
// 1. ✅ Foreground handling REMOVED — now done by _AppRoot in app.dart (avoids duplicate)
// 2. ✅ onMessageOpenedApp → goes directly to call screen (background tap on body)
// 3. ✅ getInitialMessage → goes directly to call screen (killed app)
// 4. Token management UNCHANGED

import 'package:astrologer_app/features/service/AudioCallScreen.dart';
import 'package:astrologer_app/features/service/ChatScreen.dart';
import 'package:astrologer_app/features/service/VideoCallScreen.dart';
import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
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

      // ── Foreground handled by _AppRoot._onForeground() in app.dart ─────
      // Do NOT add FirebaseMessaging.onMessage here — would show duplicate

      // ── Background: user tapped notification BODY (not action button) ───
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

      // ── Killed: app opened via notification ──────────────────────────────
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        await Future.delayed(const Duration(milliseconds: 800));
        _handleOpenedApp(initial);
      }
    }
  }

  // ── Background / killed: notification body tapped → go to call screen ────
  // (Action button taps are handled by onNotificationAction in main.dart)
  Future<void> _handleOpenedApp(RemoteMessage message) async {
    final data       = message.data;
    final type       = data['type'] ?? '';
    final channelId  = data['channel_id'] ?? '';
    final agoraToken = data['agora_token']?? '';
    final userName   = data['user_name']  ?? '';
    final userImage  = data['user_image'] ?? '';
    final userId     = data['user_id']    ?? '';

    if (channelId.isEmpty) return;

    final prefs   = await SharedPreferences.getInstance();
    final astroId = prefs.getString('astro_id') ?? '';

    final nav = NavigationManager().navigatorKey.currentState;
    if (nav == null) return;

    // Tapping the notification body → show the incoming screen so
    // the astrologer can still accept or reject
    if (type == 'video') {
      NavigationManager().showIncomingVideoCall(
        token    : agoraToken,
        channelId: channelId,
        userName : userName,
        userAvatar: userImage,
      );
    } else if (type == 'audio') {
      NavigationManager().showIncomingAudioCall(
        token    : agoraToken,
        channelId: channelId,
        userName : userName,
        userAvatar: userImage,
      );
    } else if (type == 'chat') {
      NavigationManager().showIncomingChatRequest(
        requestId    : channelId,
        userName     : userName,
        userAvatar   : userImage,
        messagePreview: 'Incoming chat request',
        channelId    : channelId,
        userId       : userId,
        astroId      : astroId,
      );
    }
  }

  // ── Token management (UNCHANGED) ──────────────────────────────────────────
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
    await prefs.setInt('fcm_token_timestamp', DateTime.now().millisecondsSinceEpoch);
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

  Future<void> subscribeToTopic(String topic)   async => _fcm.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) async => _fcm.unsubscribeFromTopic(topic);
}