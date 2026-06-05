// lib/features/service/provider/VideoCallProvider.dart
//
// Fixes from current code in project knowledge:
// 1. startPreview() called BEFORE joinChannel (was inside onJoinChannelSuccess — too late)
// 2. initAgora() accepts OnCallEnded? onEnded callback (VideoCallScreen needs it for rating)
// 3. onUserOffline fires onCallEnded so rating sheet shows when remote leaves
// 4. endLocalCall() method present (VideoCallScreen end button calls it)
// 5. toggleVideo() / muteLocalVideoForBackground() present (VideoCallScreen calls them)

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnCallEnded = void Function(String reason);

class VideoCallProvider extends ChangeNotifier {
  static const _appId = '8782e154141a4c0bbc8acaa3004d21f2';

  RtcEngine? _engine;
  int?       _localUid;
  int?       _remoteUid;
  bool       _isJoined   = false;
  bool       _isDisposed = false;

  bool _muted     = false;
  bool _speakerOn = true;
  bool _isVideoOn = true;

  Timer?   _deductTimer;
  Timer?   _durationTimer;
  Duration _callDuration = Duration.zero;

  OnCallEnded? onCallEnded;

  RtcEngine? get engine    => _engine;
  int?       get localUid  => _localUid;
  int?       get remoteUid => _remoteUid;
  bool       get isJoined  => _isJoined;
  bool       get muted     => _muted;
  bool       get speakerOn => _speakerOn;
  bool       get isVideoOn => _isVideoOn;

  String get duration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> initAgora({
    required String  channelId,
    required String  token,
    OnCallEnded?     onEnded,       // ✅ FIX 2
  }) async {
    if (_engine != null) return;
    onCallEnded = onEnded;
    _localUid   = 0;

    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId         : _appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) => debugPrint('❌ Agora: $err | $msg'),

      onJoinChannelSuccess: (connection, uid) {
        debugPrint('✅ Joined uid=$uid');
        _isJoined = true;
        _safeNotify();
        // ✅ FIX 1: preview already started below — just notify here
      },

      onUserJoined: (connection, uid, elapsed) {
        debugPrint('👤 Remote joined uid=$uid');
        _remoteUid = uid;
        _startDurationTimer();
        _engine?.setEnableSpeakerphone(true);
        _safeNotify();
      },

      onUserOffline: (connection, uid, reason) {
        debugPrint('👤 Remote offline uid=$uid');
        _remoteUid = null;
        _durationTimer?.cancel();
        _safeNotify();
        // ✅ FIX 3: fires rating sheet
        onCallEnded?.call('The user has ended the call.');
      },

      onLeaveChannel: (connection, stats) {
        _isJoined = false;
        _safeNotify();
      },

      onRemoteVideoStateChanged: (connection, uid, state, reason, elapsed) {
        _safeNotify();
      },
    ));

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
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

    // ✅ FIX 1: startPreview BEFORE joinChannel
    await _engine!.startPreview();
    _safeNotify(); // lets UI render local VideoView before joining

    await _engine!.joinChannel(
      token    : token,
      channelId: channelId,
      uid      : 2,    // ✅ uid=2 for astrologer (user uses uid=1)
      options  : const ChannelMediaOptions(
        channelProfile        : ChannelProfileType.channelProfileCommunication,
        clientRoleType        : ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack    : true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo    : true,
        autoSubscribeAudio    : true,
      ),
    );

    await _engine!.setEnableSpeakerphone(true);
  }

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

  // ✅ FIX 5: VideoCallScreen bottom controls call this
  Future<void> toggleVideo() async {
    _isVideoOn = !_isVideoOn;
    await _engine?.muteLocalVideoStream(!_isVideoOn);
    _safeNotify();
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  // ✅ FIX 5: VideoCallScreen lifecycle calls this
  Future<void> muteLocalVideoForBackground(bool mute) async {
    await _engine?.muteLocalVideoStream(mute);
  }

  // ✅ FIX 4: VideoCallScreen end button and WillPopScope call this
  Future<void> endLocalCall() async {
    _deductTimer?.cancel();
    _durationTimer?.cancel();

    try { await _engine?.leaveChannel(); }  catch (_) {}
    try { await _engine?.stopPreview(); }   catch (_) {}
    try { await _engine?.release(); }       catch (_) {}

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