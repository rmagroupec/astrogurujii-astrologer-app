// lib/features/service/service/navigationManager.dart
//
// FIXES:
// 1. ✅ showIncomingAudioCall / showIncomingVideoCall / showIncomingChatRequest
//       — retry loop waits up to 5s for navigator to be ready (background/killed wake-up)
//       — finally block ALWAYS resets the lock so it never gets stuck
// 2. ✅ openAudioCallScreen / openVideoCallScreen / openChatScreen
//       — same retry loop so Accept action from notification works too

import 'package:astrologer_app/features/service/AudioCallScreen.dart';
import 'package:astrologer_app/features/service/ChatScreen.dart';
import 'package:astrologer_app/features/service/IncomingAudioCallScreen.dart';
import 'package:astrologer_app/features/service/IncomingChatScreen.dart';
import 'package:astrologer_app/features/service/IncomingVideoCallScreen.dart';
import 'package:astrologer_app/features/service/VideoCallScreen.dart';
import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationManager {
  static final NavigationManager _instance = NavigationManager._internal();
  factory NavigationManager() => _instance;
  NavigationManager._internal();

  AudioCallProvider? activeAudioProvider;
  VideoCallProvider? activeVideoProvider;
  ChatProvider?      activeChatProvider;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool    _isShowingIncomingChat  = false;
  String? _currentChatRequestId;
  bool    _isShowingIncomingVideo = false;
  String? _currentVideoChannelId;
  bool    _isShowingIncomingAudio = false;
  String? _currentAudioChannelId;

  final callStatusService = CallStatusService();

  // ── Helper: wait for navigator to be ready (handles background/killed wake) ──
  Future<NavigatorState?> _waitForNavigator({int maxRetries = 25}) async {
    int retries = 0;
    while (navigatorKey.currentState == null && retries < maxRetries) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }
    if (navigatorKey.currentState == null) {
      debugPrint('❌ Navigator never became ready after ${maxRetries * 200}ms');
    }
    return navigatorKey.currentState;
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  Future<void> showIncomingChatRequest({
    required String requestId,
    required String userName,
    required String userAvatar,
    required String messagePreview,
    required String channelId,
    required String userId,
    required String astroId,
  }) async {
    if (_isShowingIncomingChat || _currentChatRequestId == requestId) {
      debugPrint('⚠️ Already showing chat request: $requestId');
      return;
    }
    _isShowingIncomingChat = true;
    _currentChatRequestId  = requestId;

    try {
      // ✅ Wait for navigator — handles background/killed app wake-up
      final nav = await _waitForNavigator();
      if (nav == null) return;

      final result = await nav.push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingChatRequestScreen(
            userName     : userName,
            userAvatar   : userAvatar,
            messagePreview: messagePreview,
          ),
        ),
      );

      if (result == 'accept') {
        await callStatusService.updateCallStatus(
            channelId: channelId, status: 'accept_astro');
        openChatScreen(
          channelId : channelId,
          astroId   : astroId,
          userId    : userId,
          userName  : userName,
          userAvatar: userAvatar,
        );
      }
    } finally {
      // ✅ Always reset — even if navigator was null or an error occurred
      _isShowingIncomingChat = false;
      _currentChatRequestId  = null;
    }
  }

  // ── Video call ─────────────────────────────────────────────────────────────
  Future<void> showIncomingVideoCall({
    required String token,
    required String channelId,
    required String userName,
    required String userAvatar,
  }) async {
    if (_isShowingIncomingVideo || _currentVideoChannelId == channelId) {
      debugPrint('⚠️ Already showing incoming video call: $channelId');
      return;
    }
    _isShowingIncomingVideo = true;
    _currentVideoChannelId  = channelId;

    try {
      // ✅ Wait for navigator — handles background/killed app wake-up
      final nav = await _waitForNavigator();
      if (nav == null) return;

      final result = await nav.push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingVideoCallScreen(
            channelId: channelId,
            userName : userName,
            profile  : userAvatar,
            token    : token,
          ),
        ),
      );

      if (result == 'accept') {
        await callStatusService.updateCallStatus(
            channelId: channelId, status: 'accept_astro');
        openVideoCallScreen(
          channelId : channelId,
          token     : token,
          userName  : userName,
          userAvatar: userAvatar,
        );
      }
    } finally {
      // ✅ Always reset — even if navigator was null or an error occurred
      _isShowingIncomingVideo = false;
      _currentVideoChannelId  = null;
    }
  }

  // ── Audio call ─────────────────────────────────────────────────────────────
  Future<void> showIncomingAudioCall({
    required String token,
    required String channelId,
    required String userName,
    required String userAvatar,
  }) async {
    if (_isShowingIncomingAudio || _currentAudioChannelId == channelId) {
      debugPrint('⚠️ Already showing incoming audio call: $channelId');
      return;
    }
    _isShowingIncomingAudio = true;
    _currentAudioChannelId  = channelId;

    try {
      // ✅ Wait for navigator — handles background/killed app wake-up
      final nav = await _waitForNavigator();
      if (nav == null) return;

      final result = await nav.push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingAudioCallScreen(
            channelId: channelId,
            userName : userName,
            profile  : userAvatar,
            token    : token,
          ),
        ),
      );

      if (result == 'audio_accept') {
        await callStatusService.updateCallStatus(
            channelId: channelId, status: 'accept_astro');
        openAudioCallScreen(
          channelId : channelId,
          token     : token,
          userName  : userName,
          userAvatar: userAvatar,
        );
      }
    } finally {
      // ✅ Always reset — even if navigator was null or an error occurred
      _isShowingIncomingAudio = false;
      _currentAudioChannelId  = null;
    }
  }

  // ── Open screens ───────────────────────────────────────────────────────────
Future<void> openVideoCallScreen({
  required String channelId,
  required String token,
  String userName   = '',
  String userAvatar = '',
}) async {
  final navigator = await _waitForNavigator();
  if (navigator == null) return;

  final provider = VideoCallProvider();
  activeVideoProvider = provider;

  navigator.push(MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider<VideoCallProvider>.value(
      value: provider,
      child: VideoCallScreen(
        channelId : channelId,
        token     : token,
        userName  : userName,
        userAvatar: userAvatar,
      ),
    ),
  ));
}

Future<void> openChatScreen({
  required String channelId,
  required String astroId,
  required String userId,
  required String userName,
  required String userAvatar,
}) async {
  final navigator = await _waitForNavigator();
  if (navigator == null) return;

  final provider = ChatProvider();
  activeChatProvider = provider;

  navigator.push(MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider<ChatProvider>.value(
      value: provider,
      child: ChatScreen(
        channelId : channelId,
        astroId   : astroId,
        userId    : userId,
        userName  : userName,
        userAvatar: userAvatar,
      ),
    ),
  ));
}
 Future<void> openAudioCallScreen({
  required String channelId,
  required String token,
  String userName   = '',
  String userAvatar = '',
}) async {
  final navigator = await _waitForNavigator();   // <- was: navigatorKey.currentState
  if (navigator == null) return;

  final provider = AudioCallProvider();
  activeAudioProvider = provider;
  navigator.push(MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider<AudioCallProvider>.value(
      value: provider,
      child: AudioCallScreen(
        channelId  : channelId,
        token      : token,
        callerName : userName,
        callerImage: userAvatar,
      ),
    ),
  ));
}

  
  void handleChatEndFromNotification(String reason) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ Context not available for handleChatEndFromNotification');
      return;
    }
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    debugPrint('Chat ended: $reason');
    chatProvider.handleChatEnded(reason);
  }

  void reset() {
    _isShowingIncomingChat  = false;
    _currentChatRequestId   = null;
    _isShowingIncomingVideo = false;
    _currentVideoChannelId  = null;
    _isShowingIncomingAudio = false;
    _currentAudioChannelId  = null;
  }
}