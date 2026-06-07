// lib/features/service/provider/VideoCallProvider.dart  (ASTROLOGER APP)
//
// FIXES:
// 1. ✅ REMOVED setClientRole() separate call — throws AgoraRtcException in SDK v6
//       Communication profile — was silently stopping execution before joinChannel
// 2. ✅ uid: 2 — backend builds astro_agora_token for uid=2, must match
// 3. ✅ All other logic preserved (minimize, expand, status updates, overlay)

import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

typedef OnCallEnded = void Function(String reason);

class VideoCallProvider extends ChangeNotifier {
  static const _appId    = '8782e154141a4c0bbc8acaa3004d21f2';
  static const _baseUrl  = 'https://admin.astrogurujii.com';
  final _storage         = const FlutterSecureStorage();

  RtcEngine? _engine;
  int?       _remoteUid;
  bool       _isJoined   = false;
  bool       _isDisposed = false;

  bool _muted       = false;
  bool _speakerOn   = true;
  bool _isVideoOn   = true;
  bool _isMinimized = false;
  bool _isEnded     = false;

  String callerName  = '';
  String callerImage = '';
  String _channelId  = '';

  Timer?   _deductTimer;
  Timer?   _durationTimer;
  Duration _callDuration = Duration.zero;

  OnCallEnded? _onCallEnded;

  // ── Getters ──────────────────────────────────────────────────────────────────
  RtcEngine? get engine      => _engine;
  int?       get remoteUid   => _remoteUid;
  bool       get isJoined    => _isJoined;
  bool       get muted       => _muted;
  bool       get speakerOn   => _speakerOn;
  bool       get isVideoOn   => _isVideoOn;
  bool       get isMinimized => _isMinimized;
  bool       get isEnded     => _isEnded;
  bool       get isActive    => !_isEnded;
  String     get channelId   => _channelId;

  String get duration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Call status API ──────────────────────────────────────────────────────────
  Future<void> _updateCallStatus(String status) async {
    if (_channelId.isEmpty) return;
    try {
      final token = await _storage.read(key: 'auth_token') ?? '';
      final res = await http.post(
        Uri.parse('$_baseUrl/astrologer_api/call_status_update'),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'channel_id': _channelId, 'status': status}),
      );
      debugPrint('📡 video call_status_update($status): ${res.body}');
    } catch (e) {
      debugPrint('❌ video call_status_update error: $e');
    }
  }

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> initAgora({
    required String  channelId,
    required String  token,
    String           name      = '',
    String           image     = '',
    OnCallEnded?     onEnded,
  }) async {
    if (_engine != null) {
      _onCallEnded = onEnded;
      return;
    }

    _channelId   = channelId;
    callerName   = name;
    callerImage  = image;
    _onCallEnded = onEnded;
    _isEnded     = false;

    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();

    try {
      await _engine!.initialize(const RtcEngineContext(
        appId         : _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      debugPrint('✅ [ASTRO VIDEO] initialize OK');
    } on AgoraRtcException catch (e) {
      debugPrint('❌ [ASTRO VIDEO] initialize failed: ${e.code} ${e.message}');
      return;
    }

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) {
        debugPrint('❌ [ASTRO VIDEO] Agora error: code=$err | $msg');
      },

      onJoinChannelSuccess: (connection, uid) async {
        debugPrint('✅ [ASTRO VIDEO] Joined ch=${connection.channelId} uid=$uid');
        _isJoined = true;
        _safeNotify();
        // Tell backend astrologer has joined Agora
        await _updateCallStatus('accept_astro');
      },

      onUserJoined: (connection, uid, elapsed) {
        debugPrint('👤 [ASTRO VIDEO] Remote joined uid=$uid');
        _remoteUid = uid;
        _startDurationTimer();
        _engine?.setEnableSpeakerphone(true);
        _safeNotify();
      },

      onUserOffline: (connection, uid, reason) {
        debugPrint('👤 [ASTRO VIDEO] Remote offline uid=$uid reason=$reason');
        _remoteUid = null;
        _durationTimer?.cancel();
        _safeNotify();
        _onCallEnded?.call('The user has ended the call.');
      },

      onLeaveChannel: (connection, stats) {
        debugPrint('📴 [ASTRO VIDEO] Left channel');
        _isJoined = false;
        _safeNotify();
      },

      onRemoteVideoStateChanged: (connection, uid, state, reason, elapsed) {
        debugPrint('📹 [ASTRO VIDEO] Remote video uid=$uid state=$state reason=$reason');
        _safeNotify();
      },

      onConnectionStateChanged: (connection, state, reason) {
        debugPrint('🔗 [ASTRO VIDEO] Connection state=$state reason=$reason');
      },

      onTokenPrivilegeWillExpire: (connection, token) {
        debugPrint('⚠️ [ASTRO VIDEO] Token will expire soon');
      },
    ));

    try {
      // ✅ FIX 1: NO setClientRole() here — removed entirely
      // It throws AgoraRtcException in SDK v6 Communication profile
      // Role is set ONLY inside ChannelMediaOptions below

      await _engine!.enableAudio();
      debugPrint('✅ [ASTRO VIDEO] enableAudio OK');

      await _engine!.enableVideo();
      debugPrint('✅ [ASTRO VIDEO] enableVideo OK');

      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions     : VideoDimensions(width: 640, height: 480),
          frameRate      : 24,
          bitrate        : 800,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
      debugPrint('✅ [ASTRO VIDEO] setVideoEncoderConfig OK');

      await _engine!.startPreview();
      debugPrint('✅ [ASTRO VIDEO] startPreview OK');
      _safeNotify();

      debugPrint('▶ [ASTRO VIDEO] joinChannel ch=$channelId uid=2');
      await _engine!.joinChannel(
        token    : token,
        channelId: channelId,
        uid      : 2,   // ✅ FIX 2: matches astro_agora_token built for uid=2
        options  : const ChannelMediaOptions(
          channelProfile        : ChannelProfileType.channelProfileCommunication,
          clientRoleType        : ClientRoleType.clientRoleBroadcaster, // role set HERE
          publishCameraTrack    : true,
          publishMicrophoneTrack: true,
          autoSubscribeVideo    : true,
          autoSubscribeAudio    : true,
        ),
      );
      debugPrint('▶ [ASTRO VIDEO] joinChannel sent — waiting for onJoinChannelSuccess...');

      await _engine!.setEnableSpeakerphone(true);

    } on AgoraRtcException catch (e) {
      debugPrint('❌ [ASTRO VIDEO] AgoraRtcException: code=${e.code} msg=${e.message}');
    } catch (e) {
      debugPrint('❌ [ASTRO VIDEO] Unknown error: $e');
    }
  }

  // ── Deduction timer ──────────────────────────────────────────────────────────
  void startDeduction({
    required String channelId,
    required Future<void> Function(String) deductApi,
  }) {
    _deductTimer?.cancel();
    _deductTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => deductApi(channelId),
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

  // ── Controls ─────────────────────────────────────────────────────────────────
  Future<void> toggleMute() async {
    _muted = !_muted;
    await _engine?.muteLocalAudioStream(_muted);
    _safeNotify();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await _engine?.setEnableSpeakerphone(_speakerOn);
    _safeNotify();
  }

  Future<void> toggleVideo() async {
    _isVideoOn = !_isVideoOn;
    await _engine?.muteLocalVideoStream(!_isVideoOn);
    _safeNotify();
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> muteLocalVideoForBackground(bool mute) async {
    await _engine?.muteLocalVideoStream(mute);
  }

  // ── Minimize / Expand ────────────────────────────────────────────────────────
  void minimize() {
    _isMinimized = true;
    _engine?.muteLocalVideoStream(true);
    _safeNotify();
  }

  void expand() {
    _isMinimized = false;
    if (_isVideoOn) _engine?.muteLocalVideoStream(false);
    _safeNotify();
  }

  // ── End call ──────────────────────────────────────────────────────────────────
  Future<void> endLocalCall() async {
    if (_isEnded) return;
    _isEnded     = true;
    _isMinimized = false;
    _deductTimer?.cancel();
    _durationTimer?.cancel();

    await _updateCallStatus('end_astro');

    try { await _engine?.leaveChannel(); }  catch (e) { debugPrint('leaveChannel: $e'); }
    try { await _engine?.stopPreview(); }   catch (e) { debugPrint('stopPreview: $e'); }
    try { await _engine?.release(); }       catch (e) { debugPrint('release: $e'); }

    _engine       = null;
    _remoteUid    = null;
    _isJoined     = false;
    _muted        = false;
    _speakerOn    = true;
    _isVideoOn    = true;
    _callDuration = Duration.zero;

    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _deductTimer?.cancel();
    _durationTimer?.cancel();
    try { _engine?.release(); } catch (_) {}
    _engine = null;
    super.dispose();
  }
}