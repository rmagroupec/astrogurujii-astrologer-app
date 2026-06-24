// lib/features/service/provider/VideoCallProvider.dart
//
// FIX: minimize() now uses _safeNotifyDeferred() so the overlay's setState
// is never called during the build phase — same pattern as AudioCallProvider.
// This was why the video floating overlay never appeared after minimizing.

import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:astrologer_app/features/service/active_call_store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnCallEnded = void Function(String reason);

class VideoCallProvider extends ChangeNotifier {
  static const _appId   = '8782e154141a4c0bbc8acaa3004d21f2';
  static const _baseUrl = 'https://admin.astrogurujii.com';
  final _storage        = const FlutterSecureStorage();

  RtcEngine? _engine;
  int?       _remoteUid;
  bool       _isJoined   = false;
  bool       _isDisposed = false;

  bool _remoteVideoOn = true;
  bool get remoteVideoOn => _remoteVideoOn;
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

  StreamSubscription<DatabaseEvent>? _callSessionSub;

  // ── Getters ──────────────────────────────────────────────────────────────
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

  // ── Safe notify ───────────────────────────────────────────────────────────
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // ✅ FIX: Deferred notify — safe to call from build/dispose/didChangeDependencies
  void _safeNotifyDeferred() {
    if (_isDisposed) return;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ── Re-wire callback ──────────────────────────────────────────────────────
  void rewireCallback({required OnCallEnded onEnded}) {
    _onCallEnded = onEnded;
    debugPrint('📹 VideoCallProvider: callback re-wired for resumed screen');
  }

  // ── Init Agora ────────────────────────────────────────────────────────────
  Future<void> initAgora({
    required String channelId,
    required String token,
    String       name    = '',
    String       image   = '',
    OnCallEnded? onEnded,
  }) async {
    if (_engine != null) {
      if (onEnded != null) _onCallEnded = onEnded;
      debugPrint('📹 initAgora skipped — engine already active');
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
    } on AgoraRtcException catch (e) {
      debugPrint('❌ [VIDEO] initialize failed: ${e.code} ${e.message}');
      return;
    }

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) => debugPrint('❌ [VIDEO] error: $err $msg'),

      onJoinChannelSuccess: (connection, uid) async {
        debugPrint('✅ [VIDEO] joined uid=$uid');
        _isJoined = true;
        _safeNotify();
        await _updateCallStatus('accept_astro');
      },

      onUserJoined: (connection, uid, elapsed) {
        debugPrint('👤 [VIDEO] remote joined uid=$uid');
        _remoteUid     = uid;
        _remoteVideoOn = true;
        _startDurationTimer();
        _engine?.setEnableSpeakerphone(true);
        _safeNotify();
      },

      onRemoteVideoStateChanged: (connection, uid, state, reason, elapsed) {
        _remoteVideoOn = state == RemoteVideoState.remoteVideoStateDecoding ||
                         state == RemoteVideoState.remoteVideoStateStarting;
        _safeNotify();
      },

      onUserOffline: (connection, uid, reason) {
        debugPrint('👤 [VIDEO] remote offline uid=$uid');
        _remoteUid = null;
        _durationTimer?.cancel();
        _safeNotify();
        _onCallEnded?.call('The user has ended the call.');
      },

      onLeaveChannel: (connection, stats) {
        _isJoined = false;
        _safeNotify();
      },

      onConnectionStateChanged: (connection, state, reason) {
        debugPrint('🔗 [VIDEO] connection state=$state reason=$reason');
      },

      onTokenPrivilegeWillExpire: (connection, token) {
        debugPrint('⚠️ [VIDEO] token will expire');
      },
    ));

    try {
      await _engine!.enableAudio();
      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions     : VideoDimensions(width: 640, height: 480),
          frameRate      : 24,
          bitrate        : 800,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
      await _engine!.startPreview();
      _safeNotify();

      await _engine!.joinChannel(
        token    : token,
        channelId: channelId,
        uid      : 2,
        options  : const ChannelMediaOptions(
          channelProfile        : ChannelProfileType.channelProfileCommunication,
          clientRoleType        : ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack    : true,
          autoSubscribeAudio    : true,
          autoSubscribeVideo    : true,
        ),
      );
    } on AgoraRtcException catch (e) {
      if (e.code == -17) {
        debugPrint('⚠️ [VIDEO] joinChannel -17: already in channel — ignoring');
      } else {
        debugPrint('❌ [VIDEO] setup failed: ${e.code} ${e.message}');
      }
    }
  }

  // ── Deduction + Firebase ──────────────────────────────────────────────────
  void startDeduction({
    required String channelId,
    required Future<void> Function(String) deductApi,
  }) {
    _deductTimer?.cancel();
    _deductTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => deductApi(channelId),
    );
    listenCallSession(channelId);
  }

  void listenCallSession(String channelId) {
    _callSessionSub?.cancel();
    final ref = FirebaseDatabase.instanceFor(
      app        : Firebase.app(),
      databaseURL: 'https://astrogurujii-production-default-rtdb.firebaseio.com/',
    ).ref().child('CallSession').child(channelId);

    _callSessionSub = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;
      final map    = Map<String, dynamic>.from(data as Map);
      final status = (map['status'] ?? '') as String;
      if (['end_user', 'end_astro', 'wallet_empty'].contains(status) && !_isEnded) {
        endLocalCall();
        _onCallEnded?.call('Call ended');
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      _safeNotify();
    });
  }

  // ── Controls ──────────────────────────────────────────────────────────────
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

  // ── Minimize ──────────────────────────────────────────────────────────────
  // ✅ FIX: use _safeNotifyDeferred so overlay setState is never called
  // during the build phase (which silently prevented the pill from appearing)
  void minimize() {
    _isMinimized = true;
    _engine?.muteLocalVideoStream(true);
    _safeNotifyDeferred();
  }

  // ── Expand ────────────────────────────────────────────────────────────────
  void expand() {
    _isMinimized = false;
    if (_isVideoOn) _engine?.muteLocalVideoStream(false);
    if (_remoteUid != null) _remoteVideoOn = true;
    _safeNotifyDeferred();
  }

  // ── End call ──────────────────────────────────────────────────────────────
  Future<void> endLocalCall() async {
    if (_isEnded) return;
    _isEnded     = true;
    _isMinimized = false;
    _deductTimer?.cancel();
    _callSessionSub?.cancel();
    _durationTimer?.cancel();
    await ActiveCallStore.clear();
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

  Future<void> _updateCallStatus(String status) async {
    if (_channelId.isEmpty) return;
    try {
      final token = await _storage.read(key: 'auth_token') ?? '';
      await http.post(
        Uri.parse('$_baseUrl/astrologer_api/call_status_update'),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'channel_id': _channelId, 'status': status}),
      );
    } catch (e) {
      debugPrint('❌ _updateCallStatus($status): $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _deductTimer?.cancel();
    _callSessionSub?.cancel();
    _durationTimer?.cancel();
    try { _engine?.release(); } catch (_) {}
    _engine = null;
    super.dispose();
  }
}