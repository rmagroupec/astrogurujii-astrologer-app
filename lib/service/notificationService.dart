// lib/core/providers/NotificationService.dart
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Set<String> _processedNotifications = {};

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permissions');

      // Get FCM token
      await _generateFCMToken();

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_handleTokenRefresh);

      // Set up message listeners
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        print("inside initial messgae");
        _handleNotificationTap(initialMessage);
      }
    } else {
      print('⚠️ User declined notification permissions');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    print('🔥🔥🔥 FCM FOREGROUND RECEIVED 🔥🔥🔥');
    print('📦 Message data: ${message.data}');
    final data = message.data;
    final messageId = data['channel_id']; // ✅ USE CHANNEL ID

    print(data['notification_type']);
    if (data['notification_type'] == 'end_user' ||
        data['notification_type'] == 'reject_user') {
      print("inside this");
      NavigationManager().handleChatEndFromNotification(data["body"]);
    }
    if (messageId == null) return;
    if (_processedNotifications.contains(messageId)) return;
    _processedNotifications.add(messageId);

    if (data['type'] == 'chat' && data['notification_type'] == 'initiate') {
      NavigationManager().showIncomingChatRequest(
        requestId: messageId,
        userName: data['user_name'] ?? 'User',
        userAvatar: data['user_image'] ?? 'https://i.pravatar.cc/150',
        messagePreview: 'Incoming chat request',
        channelId: messageId,
        userId: data['user_id'] ?? '',
        astroId: prefs.getString('astro_id') ?? '',
      );
    }
    print("inside this");
    if (data['type'] == 'video' && data['notification_type'] == 'initiate') {
      NavigationManager().showIncomingVideoCall(
        channelId: data['channel_id'],
        userName: data['user_name'] ?? 'User',
        userAvatar: data['user_image'] ?? 'https://i.pravatar.cc/150',
        token: data['agora_token'] ?? ""
      );
    }
    print("token ${data['fb_channel_id']}");
    if (data['type'] == 'audio' && data['notification_type'] == 'initiate') {
      NavigationManager().showIncomingAudioCall(
        channelId: data['channel_id'],
        userName: data['user_name'] ?? 'User',
        userAvatar: data['user_image'] ?? 'https://i.pravatar.cc/150',
        token: data['agora_token'] ?? ""
      );
    }
  }

  /// Generate and store FCM token
  Future<String?> _generateFCMToken() async {
    try {
      // Get the token
      _fcmToken = await _fcm.getToken();

      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');

        // Save token locally
        await _saveTokenLocally(_fcmToken!);

        // Send token to your backend
        await _sendTokenToBackend(_fcmToken!);

        return _fcmToken;
      } else {
        print('❌ Failed to get FCM token');
        return null;
      }
    } catch (e) {
      print('❌ Error generating FCM token: $e');
      return null;
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String newToken) async {
    print('🔄 Token refreshed: $newToken');
    _fcmToken = newToken;

    await _saveTokenLocally(newToken);
    await _sendTokenToBackend(newToken);
  }

  /// Save token to local storage
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      await prefs.setInt(
        'fcm_token_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      print('💾 Token saved locally');
    } catch (e) {
      print('❌ Error saving token locally: $e');
    }
  }

  /// Send token to your backend server
  Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Replace with your actual API endpoint
      // Example:
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/api/fcm-token'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'fcm_token': token,
      //     'user_id': 'YOUR_USER_ID', // Get from your auth service
      //     'platform': Platform.isIOS ? 'ios' : 'android',
      //     'timestamp': DateTime.now().toIso8601String(),
      //   }),
      // );
      //
      // if (response.statusCode == 200) {
      //   print('✅ Token sent to backend successfully');
      // } else {
      //   print('❌ Failed to send token: ${response.statusCode}');
      // }

      print('📤 Token should be sent to backend: $token');
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }

  /// Get stored FCM token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('❌ Error getting stored token: $e');
      return null;
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      await prefs.remove('fcm_token_timestamp');
      _fcmToken = null;
      print('🗑️ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }

  /// Refresh token manually
  Future<String?> refreshToken() async {
    try {
      await _fcm.deleteToken();
      return await _generateFCMToken();
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return null;
    }
  }

  final callStatusService = CallStatusService();

  void _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;

    if (data['type'] != 'chat') return;

    final channelId = data['channel_id'];
    if (channelId == null) return;

    await callStatusService.updateCallStatus(
      channelId: channelId,
      status: 'accept_astro',
    );

    NavigationManager().openChatScreen(
      channelId: channelId,
      astroId: data['astro_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userAvatar: data['user_image'] ?? '',
    );
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  void dispose() {
    _processedNotifications.clear();
  }
}
