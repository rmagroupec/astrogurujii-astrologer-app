// lib/features/service/provider/audio_call_provider.dart
//
// Changes from previous version:
// 1. Fixed end() — now properly clears engine even when _engine is null guard was skipping
// 2. Added isMinimized state + minimize()/expand() methods
// 3. toggleHold() already existed — exposed getter properly
// 4. Caller info stored in provider for overlay widget to access

import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AudioCallProvider extends ChangeNotifier {
  RtcEngine? _engine;
  bool _joined   = false;
  bool _disposed = false;

  bool _muted        = false;
  bool _speakerOn    = true;
  bool _onHold       = false;
  bool _remoteJoined = false;
  bool _isMinimized  = false;   // ✅ NEW: for floating overlay
  bool _isEnded      = false;   // ✅ NEW: track end state

  Timer?   _durationTimer;
  Duration _callDuration = Duration.zero;
  String   _channelId    = '';

  // ✅ Caller info stored so overlay can display it
  String callerName  = '';
  String callerImage = '';

  VoidCallback? _onRemoteDisconnected;

  bool   get joined       => _joined;
  bool   get remoteJoined => _remoteJoined;
  bool   get muted        => _muted;
  bool   get speakerOn    => _speakerOn;
  bool   get onHold       => _onHold;
  bool   get isMinimized  => _isMinimized;
  bool   get isEnded      => _isEnded;
  bool   get isActive     => _joined && !_isEnded;
  String get channelId    => _channelId;

  String get duration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _updateCallStatus(String status) async {
    if (_channelId.isEmpty) return;
    try {
      final auth = await _getToken();
      final res  = await http.post(
        Uri.parse('https://admin.astrogurujii.com/astrologer_api/call_status_update'),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $auth',
        },
        body: jsonEncode({'channel_id': _channelId, 'status': status}),
      );
      debugPrint('📡 call_status_update($status): ${jsonDecode(res.body)['message']}');
    } catch (e) {
      debugPrint('❌ call_status_update error: $e');
    }
  }

  Future<void> init({
    required String   channelId,
    required String   token,
    required String   name,       // ✅ NEW: store caller info
    required String   image,      // ✅ NEW: store caller info
    VoidCallback?     onRemoteDisconnected,
  }) async {
    if (_engine != null) return;
    _channelId            = channelId;
    _onRemoteDisconnected = onRemoteDisconnected;
    callerName            = name;
    callerImage           = image;
    _isEnded              = false;

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(
      const RtcEngineContext(
        appId         : '8782e154141a4c0bbc8acaa3004d21f2',
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) async {
          _joined = true;
          await _engine?.enableAudio();
          await _engine?.setAudioProfile(
            profile : AudioProfileType.audioProfileDefault,
            scenario: AudioScenarioType.audioScenarioChatroom,
          );
          await _engine?.muteAllRemoteAudioStreams(false);
          await _updateCallStatus('accept_astro');
          _safeNotify();
        },

        onUserJoined: (_, uid, __) async {
          debugPrint('👤 Remote user joined: $uid');
          await _engine?.muteRemoteAudioStream(uid: uid, mute: false);
          _remoteJoined = true;
          _startDurationTimer();
          Future.delayed(const Duration(milliseconds: 300), () async {
            try {
              await _engine?.setEnableSpeakerphone(true);
              _speakerOn = true;
              _safeNotify();
            } catch (e) {
              debugPrint('⚠️ Speaker routing failed: $e');
            }
          });
          _safeNotify();
        },

        onRemoteAudioStateChanged: (_, uid, state, reason, __) async {
          debugPrint('🔊 Remote audio uid=$uid state=$state reason=$reason');
          if (state == RemoteAudioState.remoteAudioStateDecoding) {
            await _engine?.muteRemoteAudioStream(uid: uid, mute: false);
            if (!_remoteJoined) {
              _remoteJoined = true;
              _startDurationTimer();
              Future.delayed(const Duration(milliseconds: 300), () async {
                try {
                  await _engine?.setEnableSpeakerphone(true);
                  _speakerOn = true;
                  _safeNotify();
                } catch (_) {}
              });
              _safeNotify();
            }
          } else if (state  == RemoteAudioState.remoteAudioStateStopped &&
                     reason == RemoteAudioStateReason.remoteAudioReasonRemoteOffline) {
            _remoteJoined = false;
            _durationTimer?.cancel();
            _safeNotify();
          }
        },

        onUserOffline: (_, __, ___) {
          _remoteJoined = false;
          _durationTimer?.cancel();
          _durationTimer = null;
          _callDuration  = Duration.zero;
          _safeNotify();
          _onRemoteDisconnected?.call();
        },

        onLeaveChannel: (_, __) {
          _joined = false;
          _safeNotify();
        },

        onError: (err, msg) {
          debugPrint('❌ AGORA ERROR: $err | $msg');
        },
      ),
    );

    await _engine!.enableAudio();

    await _engine!.joinChannel(
      token    : token,
      channelId: channelId,
      uid      : 2,
      options  : const ChannelMediaOptions(
        publishMicrophoneTrack        : true,
        clientRoleType                : ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio            : true,
        autoSubscribeVideo            : false,
        enableAudioRecordingOrPlayout : true,
      ),
    );
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      _safeNotify();
    });
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    await _engine?.muteLocalAudioStream(_muted);
    _safeNotify();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try { await _engine?.setEnableSpeakerphone(_speakerOn); } catch (e) {
      debugPrint('⚠️ toggleSpeaker failed: $e');
    }
    _safeNotify();
  }

  Future<void> toggleHold() async {
    _onHold = !_onHold;
    await _engine?.muteLocalAudioStream(_onHold);
    await _engine?.muteAllRemoteAudioStreams(_onHold);
    _safeNotify();
  }

  // ✅ Minimize — hides the full screen, shows floating overlay
  void minimize() {
    _isMinimized = true;
    _safeNotify();
  }

  // ✅ Expand — bring back full screen
  void expand() {
    _isMinimized = false;
    _safeNotify();
  }

  // ✅ FIXED end() — was guarded by _engine != null check at top
  Future<void> end() async {
    if (_isEnded) return;                 // ✅ prevent double-end
    _isEnded = true;
    _isMinimized = false;
    _durationTimer?.cancel();
    _durationTimer = null;
    await _updateCallStatus('end_astro');
    try { await _engine?.leaveChannel(); } catch (_) {}
    try { await _engine?.release(); }     catch (_) {}
    _engine       = null;
    _joined       = false;
    _remoteJoined = false;
    _muted        = false;
    _speakerOn    = true;
    _onHold       = false;
    _callDuration = Duration.zero;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _durationTimer?.cancel();
    try { _engine?.release(); } catch (_) {}
    _engine = null;
    super.dispose();
  }
}