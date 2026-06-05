// lib/features/service/provider/audio_call_provider.dart
//
// Fixes from doc 7 (current code):
// 1. _getToken() was using 'token' key — astrologer app uses 'auth_token'
// 2. _updateCallStatus() was hitting /user_api/ — must be /astrologer_api/
// 3. Added VoidCallback? onRemoteDisconnected to init() — screen wires rating dialog
// Everything else identical to doc 7.

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

  Timer?   _durationTimer;
  Duration _callDuration = Duration.zero;
  String   _channelId    = '';

  // ✅ FIX 3: callback so AudioCallScreen can show rating when remote leaves
  VoidCallback? _onRemoteDisconnected;

  bool   get joined       => _joined;
  bool   get remoteJoined => _remoteJoined;
  bool   get muted        => _muted;
  bool   get speakerOn    => _speakerOn;
  bool   get onHold       => _onHold;

  String get duration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ FIX 1: astrologer app stores JWT as 'auth_token', not 'token'
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _updateCallStatus(String status) async {
    if (_channelId.isEmpty) return;
    try {
      final auth = await _getToken();
      final res  = await http.post(
        // ✅ FIX 2: was /user_api/ — this is the ASTROLOGER app
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
    VoidCallback?     onRemoteDisconnected,  // ✅ FIX 3
  }) async {
    if (_engine != null) return;
    _channelId            = channelId;
    _onRemoteDisconnected = onRemoteDisconnected;

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
          // ✅ FIX 3: notify screen — shows rating dialog
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
      uid      : 2,    // ✅ uid=2 for astrologer (user uses uid=1)
      options  : const ChannelMediaOptions(
        publishMicrophoneTrack        : true,
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

  Future<void> end() async {
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