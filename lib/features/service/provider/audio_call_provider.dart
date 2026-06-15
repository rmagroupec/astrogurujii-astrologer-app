// lib/features/service/provider/audio_call_provider.dart
//
// KEY DESIGN CHANGE — mirrors VideoCallProvider exactly:
// Provider fires _onCallEnded callback (not _onRemoteDisconnected VoidCallback)
// so the screen can react to it reliably, the same way VideoCallScreen does.
// The screen listens via provider.watch() and calls _doEnd() when isEnded=true.

import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

typedef OnAudioCallEnded = void Function(String reason);

class AudioCallProvider extends ChangeNotifier {
  static const _appId = '8782e154141a4c0bbc8acaa3004d21f2';

  final _storage = const FlutterSecureStorage();

  RtcEngine? _engine;
  bool _disposed     = false;
  bool _joined       = false;
  bool _remoteJoined = false;
  bool _muted        = false;
  bool _speakerOn    = true;
  bool _onHold       = false;
  bool _isMinimized  = false;
  bool _isEnded      = false;

  Timer?   _durationTimer;
  Duration _callDuration = Duration.zero;

  String _channelId  = '';
  String callerName  = '';
  String callerImage = '';

  // Mirrors VideoCallProvider — callback instead of VoidCallback
  OnAudioCallEnded? _onCallEnded;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool   get joined       => _joined;
  bool   get remoteJoined => _remoteJoined;
  bool   get muted        => _muted;
  bool   get speakerOn    => _speakerOn;
  bool   get onHold       => _onHold;
  bool   get isMinimized  => _isMinimized;
  bool   get isEnded      => _isEnded;
  String get channelId    => _channelId;

  String get duration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<String> _getToken() async =>
      await _storage.read(key: 'auth_token') ?? '';

  Future<void> _updateStatus(String status) async {
    if (_channelId.isEmpty) return;
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse(
            'https://admin.astrogurujii.com/astrologer_api/call_status_update'),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'channel_id': _channelId, 'status': status}),
      );
    } catch (e) {
      debugPrint('❌ _updateStatus($status): $e');
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      _notify();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ── INIT ──────────────────────────────────────────────────────────────────
  Future<void> init({
    required String        channelId,
    required String        token,
    required String        name,
    required String        image,
    OnAudioCallEnded?      onEnded,
  }) async {
    // Always update callback — even if engine already exists
    if (onEnded != null) _onCallEnded = onEnded;

    if (_engine != null) return;

    _channelId  = channelId;
    callerName  = name;
    callerImage = image;
    _isEnded    = false;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId         : _appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(

      onJoinChannelSuccess: (_, __) async {
        _joined = true;
        await _engine?.enableAudio();
        await _engine?.setAudioProfile(
          profile : AudioProfileType.audioProfileDefault,
          scenario: AudioScenarioType.audioScenarioChatroom,
        );
        await _engine?.muteAllRemoteAudioStreams(false);
        await _updateStatus('accept_astro');
        _notify();
      },

      onUserJoined: (_, uid, __) async {
        debugPrint('👤 Audio remote joined uid=$uid');
        await _engine?.muteRemoteAudioStream(uid: uid, mute: false);
        _remoteJoined = true;
        _startTimer();
        Future.delayed(const Duration(milliseconds: 300), () async {
          try {
            await _engine?.setEnableSpeakerphone(true);
            _speakerOn = true;
            _notify();
          } catch (_) {}
        });
        _notify();
      },

      // Mirrors VideoCallProvider exactly — call _onCallEnded immediately
      onUserOffline: (_, uid, reason) {
        debugPrint('👤 Audio remote offline uid=$uid reason=$reason');
        _remoteJoined = false;
        _durationTimer?.cancel();
        _durationTimer = null;
        _notify();
        // Fire via microtask so Agora's native thread returns first
        Future.microtask(() => _onCallEnded?.call('User ended the call'));
      },

      onRemoteAudioStateChanged: (_, uid, state, reason, __) {
        if (state == RemoteAudioState.remoteAudioStateDecoding &&
            !_remoteJoined) {
          _remoteJoined = true;
          _startTimer();
          _notify();
        } else if (state  == RemoteAudioState.remoteAudioStateStopped &&
                   reason == RemoteAudioStateReason.remoteAudioReasonRemoteOffline) {
          debugPrint('⚠️ Audio remote offline via state change');
          if (_remoteJoined) {
            _remoteJoined = false;
            _durationTimer?.cancel();
            _notify();
            Future.microtask(() => _onCallEnded?.call('User disconnected'));
          }
        }
      },

      onConnectionStateChanged: (_, state, reason) {
        debugPrint('🔗 Audio connection state=$state reason=$reason');
        if ((state == ConnectionStateType.connectionStateDisconnected ||
             state == ConnectionStateType.connectionStateFailed) &&
            _remoteJoined) {
          _remoteJoined = false;
          _durationTimer?.cancel();
          _notify();
          Future.microtask(() => _onCallEnded?.call('Network disconnected'));
        }
      },

      onLeaveChannel: (_, __) {
        _joined = false;
        _notify();
      },

      onError: (err, msg) => debugPrint('❌ Agora audio error $err: $msg'),
    ));

    await _engine!.enableAudio();
    await _engine!.joinChannel(
      token    : token,
      channelId: channelId,
      uid      : 2,
      options  : const ChannelMediaOptions(
        publishMicrophoneTrack       : true,
        clientRoleType               : ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio           : true,
        autoSubscribeVideo           : false,
        enableAudioRecordingOrPlayout: true,
      ),
    );
  }

  // ── Controls ─────────────────────────────────────────────────────────────
  Future<void> toggleMute() async {
    _muted = !_muted;
    await _engine?.muteLocalAudioStream(_muted);
    _notify();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try { await _engine?.setEnableSpeakerphone(_speakerOn); } catch (_) {}
    _notify();
  }

  Future<void> toggleHold() async {
    _onHold = !_onHold;
    await _engine?.muteLocalAudioStream(_onHold);
    await _engine?.muteAllRemoteAudioStreams(_onHold);
    _notify();
  }

  void minimize() { _isMinimized = true;  _notify(); }
  void expand()   { _isMinimized = false; _notify(); }

  // ── END ──────────────────────────────────────────────────────────────────
  Future<void> end() async {
    if (_isEnded) return;
    _isEnded     = true;
    _isMinimized = false;

    _durationTimer?.cancel();
    _durationTimer = null;

    await _updateStatus('end_astro');

    if (_engine != null) {
      try { await _engine!.leaveChannel(); } catch (e) { debugPrint('leaveChannel: $e'); }
      try { await _engine!.release(); }      catch (e) { debugPrint('release: $e'); }
      _engine = null;
    }

    _joined       = false;
    _remoteJoined = false;
    _muted        = false;
    _speakerOn    = true;
    _onHold       = false;
    _callDuration = Duration.zero;

    _notify();
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