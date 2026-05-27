import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class VideoCallProvider extends ChangeNotifier {
  // ================= AGORA =================
  RtcEngine? _engine;

  int? _localUid;
  int? _remoteUid;

  bool _isJoined = false;
  bool _isDisposed = false;

  Timer? _deductTimer;
  Timer? _durationTimer;

  // ================= CALL STATES =================
  bool _muted = false;
  bool _speakerOn = true;
  bool _isVideoOn = true;

  Duration _callDuration = Duration.zero;

  // ================= GETTERS =================
  RtcEngine? get engine => _engine;
  int? get localUid => _localUid;
  int? get remoteUid => _remoteUid;
  bool get isJoined => _isJoined;

  bool get muted => _muted;
  bool get speakerOn => _speakerOn;
  bool get isVideoOn => _isVideoOn;

  String get duration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ================= INIT AGORA =================
  // Future<void> initAgora({
  //   required String channelId,
  //   required String token,
  // }) async {
  //   if (_engine != null) return;

    
  //   _localUid = 0;


  //   _engine = createAgoraRtcEngine();

  //   await _engine!.initialize(
  //     const RtcEngineContext(
  //       appId: "8782e154141a4c0bbc8acaa3004d21f2",
  //       channelProfile: ChannelProfileType.channelProfileCommunication,
  //     ),
  //   );

  //   _engine!.registerEventHandler(
  //     RtcEngineEventHandler(
  //       onJoinChannelSuccess: (RtcConnection connection, int uid) {
  //         _isJoined = true;
  //         _startDurationTimer();
  //         _safeNotify();
  //       },
  //       onUserJoined: (RtcConnection connection, int uid, int elapsed) {
  //         _remoteUid = uid;
  //         _safeNotify();
  //       },
  //       onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
  //         _remoteUid = null;
  //         _safeNotify();
  //       },
  //       onLeaveChannel: (_, __) {
  //         _isJoined = false;
  //         _safeNotify();
  //       },
  //       onError: (error, msg) {
  //         debugPrint("❌ AGORA ERROR: $error | $msg");
  //       },
  //     ),
  //   );

  //   await _engine!.setClientRole(
  //     role: ClientRoleType.clientRoleBroadcaster,
  //   );

  //   await _engine!.enableAudio();
  //   await _engine!.enableVideo();
  //   await _engine!.startPreview();

  //   await _engine!.joinChannel(
  //     token: token,
  //     channelId: channelId,
  //     uid: 0,
  //     options: const ChannelMediaOptions(
  //       publishCameraTrack: true,
  //       publishMicrophoneTrack: true,
  //       autoSubscribeVideo: true,
  //       autoSubscribeAudio: true,
  //     ),
  //   );
  // }

  Future<void> initAgora({
  required String channelId,
  required String token,
}) async {
  if (_engine != null) return;

  _localUid = 0; // 🔥 MUST be 0

  _engine = createAgoraRtcEngine();

  await _engine!.initialize(
    const RtcEngineContext(
      appId: "8782e154141a4c0bbc8acaa3004d21f2",
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ),
  );

  _engine!.registerEventHandler(
    RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int uid) async {
        debugPrint("✅ Joined channel uid=$uid");

        _isJoined = true;
        _startDurationTimer();

        // 🔥 START LOCAL PREVIEW HERE (CRITICAL)
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();

        debugPrint("🎥 Local preview started");
        _safeNotify();
      },

      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        debugPrint("👤 Remote joined uid=$uid");
        _remoteUid = uid;
        _safeNotify();
      },

      onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        _remoteUid = null;
        _safeNotify();
      },

      onLeaveChannel: (_, __) {
        _isJoined = false;
        _safeNotify();
      },

      onError: (error, msg) {
        debugPrint("❌ AGORA ERROR: $error | $msg");
      },
    ),
  );

  await _engine!.setClientRole(
    role: ClientRoleType.clientRoleBroadcaster,
  );

  await _engine!.enableAudio();
  await _engine!.enableVideo();

  // ❌ DO NOT call startPreview() here anymore

  await _engine!.joinChannel(
    token: token,
    channelId: channelId,
    uid: 0, // 🔥 must match local preview
    options: const ChannelMediaOptions(
      publishCameraTrack: true,
      publishMicrophoneTrack: true,
      autoSubscribeVideo: true,
      autoSubscribeAudio: true,
    ),
  );
}


  // ================= DURATION =================
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      _safeNotify();
    });
  }

  // ================= BILLING =================
  void startDeduction({
    required String channelId,
    required Future<void> Function(String channelId) deductApi,
  }) {
    _deductTimer?.cancel();
    _deductTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => deductApi(channelId),
    );
  }

  // ================= CONTROLS =================
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

  // ================= END CALL =================
  Future<void> endLocalCall() async {
    _deductTimer?.cancel();
    _durationTimer?.cancel();

    try {
      await _engine?.leaveChannel();
      await _engine?.stopPreview();
      await _engine?.release();
    } catch (_) {}

    _engine = null;
    _localUid = null;
    _remoteUid = null;
    _isJoined = false;
    _muted = false;
    _speakerOn = true;
    _isVideoOn = true;
    _callDuration = Duration.zero;

    _safeNotify();
  }

  // ================= SAFE NOTIFY =================
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _isDisposed = true;
    _deductTimer?.cancel();
    _durationTimer?.cancel();
    _engine?.release();
    _engine = null;
    super.dispose();
  }
}
