// lib/features/service/provider/audio_call_provider.dart

import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

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

  Timer?   _deductTimer;
  Timer?   _durationTimer;
  Duration _callDuration = Duration.zero;

  String _channelId  = '';
  String callerName  = '';
  String callerImage = '';

  OnAudioCallEnded? _onCallEnded;

  StreamSubscription<DatabaseEvent>? _callSessionSub;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool   get joined       => _joined;
  bool   get remoteJoined => _remoteJoined;
  bool   get isTimerReady => _remoteJoined;  // alias used by AudioCallScreen
  bool   get muted        => _muted;
  bool   get speakerOn    => _speakerOn;
  bool   get onHold       => _onHold;
  bool   get isMinimized  => _isMinimized;
  bool   get isEnded      => _isEnded;
  bool   get isActive     => !_isEnded;
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
        Uri.parse('https://admin.vaidikguru.com/astrologer_api/call_status_update'),
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

  // ── Safe notify ───────────────────────────────────────────────────────────
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _notifyDeferred() {
    if (_disposed) return;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ── Re-wire callback only — NO engine changes ─────────────────────────────
  // Call this when screen is resumed from floating overlay.
  // Engine is still running, remote is still joined — just re-attach callback.
  void rewireCallback({required OnAudioCallEnded onEnded}) {
    _onCallEnded = onEnded;
    debugPrint('📞 AudioCallProvider: callback re-wired for resumed screen');
  }

  // ── Minimize ──────────────────────────────────────────────────────────────
  void minimize() {
    _isMinimized = true;
    _notifyDeferred();
  }

  // ── Expand ────────────────────────────────────────────────────────────────
  // Restores timer if remote was already joined while minimized.
  void expand() {
    _isMinimized = false;
    if (_remoteJoined && (_durationTimer == null || !_durationTimer!.isActive)) {
      debugPrint('📞 expand(): remote already joined — restarting timer');
      _restartTimer();
    }
    _notifyDeferred();
  }

  // ── INIT ──────────────────────────────────────────────────────────────────
  // ✅ GUARD: if engine already exists, ONLY re-wire the callback and return.
  // This prevents the -17 "already in channel" crash when init() is called
  // on a resumed screen (e.g. if didChangeDependencies fires twice).
  Future<void> init({
    required String        channelId,
    required String        token,
    String                 name    = '',
    String                 image   = '',
    OnAudioCallEnded?      onEnded,
  }) async {
    // ✅ KEY GUARD: engine already running means call is active.
    // Just re-wire the callback — never re-initialize or re-join.
    if (_engine != null) {
      debugPrint('📞 init() called but engine already active — rewiring callback only');
      if (onEnded != null) _onCallEnded = onEnded;
      // Restart timer if remote is joined but timer died
      if (_remoteJoined && (_durationTimer == null || !_durationTimer!.isActive)) {
        _restartTimer();
      }
      _notifyDeferred();
      return;
    }

    if (onEnded != null) _onCallEnded = onEnded;

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
        _restartTimer();
        Future.delayed(const Duration(milliseconds: 300), () async {
          try {
            await _engine?.setEnableSpeakerphone(true);
            _speakerOn = true;
            _notify();
          } catch (_) {}
        });
        _notify();
      },

      onUserOffline: (_, uid, reason) {
        debugPrint('👤 Audio remote offline uid=$uid reason=$reason');
        _remoteJoined = false;
        _durationTimer?.cancel();
        _durationTimer = null;
        _notify();
        Future.microtask(() => _onCallEnded?.call('User disconnected'));
      },

      onRemoteAudioStateChanged: (_, uid, state, reason, __) {
        if (state == RemoteAudioState.remoteAudioStateDecoding && !_remoteJoined) {
          _remoteJoined = true;
          _restartTimer();
          _notify();
        } else if (state == RemoteAudioState.remoteAudioStateStopped &&
                   reason == RemoteAudioStateReason.remoteAudioReasonRemoteOffline) {
          if (_remoteJoined) {
            _remoteJoined = false;
            _durationTimer?.cancel();
            _durationTimer = null;
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
          _durationTimer = null;
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

    try {
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
    } on AgoraRtcException catch (e) {
      // -17 = already in channel — safe to ignore, engine is running fine
      if (e.code == -17) {
        debugPrint('⚠️ joinChannel -17: already in channel — ignoring');
      } else {
        debugPrint('❌ joinChannel failed: ${e.code} ${e.message}');
      }
    }
  }

  // ── Deduction + Firebase session listener ─────────────────────────────────
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
        end();
        _onCallEnded?.call('Call ended');
      }
    });
  }

  // ── Timer — does NOT reset _callDuration so elapsed time is preserved ─────
  void _restartTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      _notify();
    });
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

  // ── END ──────────────────────────────────────────────────────────────────
  Future<void> end() async {
    if (_isEnded) return;
    _isEnded     = true;
    _isMinimized = false;

    _durationTimer?.cancel();
    _deductTimer?.cancel();
    _callSessionSub?.cancel();
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
    _deductTimer?.cancel();
    _callSessionSub?.cancel();
    try { _engine?.release(); } catch (_) {}
    _engine = null;
    super.dispose();
  }
}