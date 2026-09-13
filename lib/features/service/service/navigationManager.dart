// lib/features/service/service/navigationManager.dart
//
// CHANGES vs previous version:
// 1. ✅ openAudioCallScreen  → saves ActiveCallStore on open
// 2. ✅ openVideoCallScreen  → saves ActiveCallStore on open
// 3. ✅ openChatScreen       → saves ActiveCallStore on open
// 4. ✅ ActiveCallStore.clear() is called by each provider's end()/endLocalCall()
//    (add that call there — see audio_call_provider.dart / VideoCallProvider.dart)
//
// Everything else is unchanged.

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
import 'package:astrologer_app/features/service/active_call_store.dart';
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

  // ── Helper: wait for navigator to be ready ────────────────────────────────
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
      final nav = await _waitForNavigator();
      if (nav == null) return;

      final result = await nav.push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingChatRequestScreen(
            userName     : userName,
            userAvatar   : userAvatar,
            messagePreview: messagePreview,
            channelId    : channelId,
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
      _isShowingIncomingAudio = false;
      _currentAudioChannelId  = null;
    }
  }

  // ── Open screens ───────────────────────────────────────────────────────────
 Future<void> openAudioCallScreen({
    required String channelId,
    required String token,
    String userName   = '',
    String userAvatar = '',
  }) async {
    // ✅ FIX: If audio provider already active on this channel, just expand it.
    if (activeAudioProvider != null &&
        activeAudioProvider!.isActive &&
        activeAudioProvider!.channelId == channelId) {
      debugPrint('📞 openAudioCallScreen: call already active — expanding');
      activeAudioProvider!.expand();
      final navigator = await _waitForNavigator();
      navigator?.push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AudioCallProvider>.value(
          value: activeAudioProvider!,
          child: AudioCallScreen(
            channelId  : channelId,
            token      : '',
            callerName : activeAudioProvider!.callerName,
            callerImage: activeAudioProvider!.callerImage,
            resumed    : true,   // ← re-wire callback only, no re-init
          ),
        ),
      ));
      return;
    }
 
    final navigator = await _waitForNavigator();
    if (navigator == null) return;
 
    await ActiveCallStore.save(
      type      : ActiveCallType.audio,
      channelId : channelId,
      token     : token,
      userName  : userName,
      userAvatar: userAvatar,
    );
 
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

Future<void> openVideoCallScreen({
    required String channelId,
    required String token,
    String userName   = '',
    String userAvatar = '',
  }) async {
    // ✅ FIX: If video provider already active on this channel, just expand it.
    if (activeVideoProvider != null &&
        activeVideoProvider!.isActive &&
        activeVideoProvider!.channelId == channelId) {
      debugPrint('📹 openVideoCallScreen: call already active — expanding');
      activeVideoProvider!.expand();
      final navigator = await _waitForNavigator();
      navigator?.push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<VideoCallProvider>.value(
          value: activeVideoProvider!,
          child: VideoCallScreen(
            channelId : channelId,
            token     : '',
            userName  : activeVideoProvider!.callerName,
            userAvatar: activeVideoProvider!.callerImage,
            resumed   : true,   // ← re-wire callback only, no re-init
          ),
        ),
      ));
      return;
    }
 
    final navigator = await _waitForNavigator();
    if (navigator == null) return;
 
    await ActiveCallStore.save(
      type      : ActiveCallType.video,
      channelId : channelId,
      token     : token,
      userName  : userName,
      userAvatar: userAvatar,
    );
 
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

    // ✅ Persist so SplashScreen can restore if process is killed
    await ActiveCallStore.save(
      type      : ActiveCallType.chat,
      channelId : channelId,
      token     : '',
      userName  : userName,
      userAvatar: userAvatar,
      astroId   : astroId,
      userId    : userId,
    );

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