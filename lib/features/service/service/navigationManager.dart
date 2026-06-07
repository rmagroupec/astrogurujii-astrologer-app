// lib/features/service/service/navigationManager.dart
//
// Fix: openAudioCallScreen now accepts and passes userName + userAvatar
// so AudioCallScreen shows caller name/image and rating dialog is populated.
// Everything else identical to current code.

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

 ChatProvider? activeChatProvider;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool    _isShowingIncomingChat  = false;
  String? _currentChatRequestId;
  bool    _isShowingIncomingVideo = false;
  String? _currentVideoChannelId;
  bool    _isShowingIncomingAudio = false;
  String? _currentAudioChannelId;

  final callStatusService = CallStatusService();

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
      print('⚠️ Already showing chat request: $requestId');
      return;
    }
    _isShowingIncomingChat    = true;
    _currentChatRequestId     = requestId;

    try {
      final result = await navigatorKey.currentState?.push<String>(
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
      final result = await navigatorKey.currentState?.push<String>(
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
        // ✅ FIX 1: still call accept_astro here for the user app to know
        //    astrologer accepted the screen (not yet joined Agora).
        //    Provider will call it AGAIN on onJoinChannelSuccess (Agora joined).
        //    Backend should handle duplicate — or remove this one entirely
        //    if your backend deduplicates on channel_id+status.
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
      print('⚠️ Already showing incoming audio call: $channelId');
      return;
    }
    _isShowingIncomingAudio = true;
    _currentAudioChannelId  = channelId;

    try {
      final result = await navigatorKey.currentState?.push<String>(
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

        // ✅ FIX: pass userName + userAvatar so AudioCallScreen shows
        //        caller info and rating dialog is populated
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
 void openVideoCallScreen({
    required String channelId,
    required String token,
    String userName   = '',
    String userAvatar = '',
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('❌ Navigator not ready');
      return;
    }
 
    // ✅ FIX 2: create + store provider, use .value so it survives screen pops
    final provider = VideoCallProvider();
    activeVideoProvider = provider;
 
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<VideoCallProvider>.value(
          value: provider,
          child: VideoCallScreen(
            channelId : channelId,
            token     : token,
            userName  : userName,
            userAvatar: userAvatar,
          ),
        ),
      ),
    );
  }
 

void openAudioCallScreen({
    required String channelId,
    required String token,
    String userName   = '',
    String userAvatar = '',
  }) {
    // ✅ Create provider and store reference for overlay to access
    final provider = AudioCallProvider();
    activeAudioProvider = provider;
 
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AudioCallProvider>.value(
          value: provider,
          child: AudioCallScreen(
            channelId  : channelId,
            token      : token,
            callerName : userName,
            callerImage: userAvatar,
          ),
        ),
      ),
    );
  }

  void openChatScreen({
    required String channelId,
    required String astroId,
    required String userId,
    required String userName,
    required String userAvatar,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) { debugPrint('❌ Navigator not ready'); return; }
 
    // ✅ Create provider and store reference — overlay polls this
    final provider = ChatProvider();
    activeChatProvider = provider;
 
    navigator.push(
      MaterialPageRoute(
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
      ),
    );
  }
  

  void handleChatEndFromNotification(String reason) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('⚠️ Context not available');
      return;
    }
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    print(reason);
    chatProvider.handleChatEnded(reason);
  }

  void reset() {
    _isShowingIncomingChat = false;
    _currentChatRequestId  = null;
  }
}