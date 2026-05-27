import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AudioCallProvider extends ChangeNotifier {
  // ================= AGORA =================
  RtcEngine? _engine;

  bool _joined   = false;
  bool _disposed = false;

  // ================= CALL STATES =================
  bool _muted     = false;
  bool _speakerOn = true;
  bool _onHold    = false;

  // ── KEY: drives the UI — true only when remote user is heard ─────────────
  bool _remoteJoined = false;

  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;

  // ── stored for API calls ──────────────────────────────────────────────────
  String _channelId = '';

  // ================= GETTERS =================
  bool get joined       => _joined;
  bool get remoteJoined => _remoteJoined; // use THIS to switch "Connecting" → "Connected"
  bool get muted        => _muted;
  bool get speakerOn    => _speakerOn;
  bool get onHold       => _onHold;

  String get duration {
    final m = _callDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ================= AUTH TOKEN ===========================================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ================= CALL STATUS UPDATE API ================================
  // Tells backend the call state changed — user web polls this every 2s
  Future<void> _updateCallStatus(String status) async {
    if (_channelId.isEmpty) return;
    try {
      final auth = await _getToken();
      final res  = await http.post(
        Uri.parse('https://admin.astrogurujii.com/user_api/call_status_update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $auth',
        },
        body: jsonEncode({'channel_id': _channelId, 'status': status}),
      );
      debugPrint('📡 call_status_update($status): ${jsonDecode(res.body)['message']}');
    } catch (e) {
      debugPrint('❌ call_status_update error: $e');
    }
  }

  // ================= INIT =================================================
  Future<void> init({
    required String channelId,
    required String token,
  }) async {
    if (_engine != null) return;
    _channelId = channelId;

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(
      const RtcEngineContext(
        appId: '8782e154141a4c0bbc8acaa3004d21f2',
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        // ── Astrologer joined Agora ────────────────────────────────────────
        onJoinChannelSuccess: (_, __) async {
          _joined = true;

          await _engine?.enableAudio();
          await _engine?.setAudioProfile(
            profile: AudioProfileType.audioProfileDefault,
            scenario: AudioScenarioType.audioScenarioChatroom,
          );
          await _engine?.muteAllRemoteAudioStreams(false);

          // ── KEY FIX ──────────────────────────────────────────────────────
          // Tell backend astrologer accepted — user web polls this every 2s.
          // Without this, user side stays "Connecting..." forever.
          await _updateCallStatus('accept_astro');

          _safeNotify();
        },

        // ── User (web) joined or was already present ───────────────────────
        onUserJoined: (_, uid, __) async {
          debugPrint('👤 Remote user joined: $uid');

          // ── KEY FIX ──────────────────────────────────────────────────────
          // Explicitly unmute this specific remote uid.
          // autoSubscribeAudio is not always reliable alone.
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

        // ── Fires for users ALREADY in channel when astrologer joins ───────
        // The web user joins first and waits — onUserJoined won't fire for them.
        // onRemoteAudioStateChanged fires for ALL existing remote users.
        onRemoteAudioStateChanged: (_, uid, state, reason, __) async {
          debugPrint('🔊 Remote audio uid=$uid state=$state reason=$reason');

          if (state == RemoteAudioState.remoteAudioStateDecoding) {
            // Explicitly unmute — autoSubscribeAudio can miss existing users
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
          } else if (
            state  == RemoteAudioState.remoteAudioStateStopped &&
            reason == RemoteAudioStateReason.remoteAudioReasonRemoteOffline
          ) {
            _remoteJoined = false;
            _durationTimer?.cancel();
            _safeNotify();
          }
        },

        // ── Remote user left ───────────────────────────────────────────────
        onUserOffline: (_, __, ___) {
          _remoteJoined = false;
          _durationTimer?.cancel();
          _durationTimer = null;
          _callDuration  = Duration.zero;
          _safeNotify();
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
     token: token.isEmpty ? '' : token, 
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
        enableAudioRecordingOrPlayout: true,
      ),
    );
  }

  // ================= DURATION =============================================
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      _safeNotify();
    });
  }

  // ================= CONTROLS =============================================
  Future<void> toggleMute() async {
    _muted = !_muted;
    await _engine?.muteLocalAudioStream(_muted);
    _safeNotify();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try {
      await _engine?.setEnableSpeakerphone(_speakerOn);
    } catch (e) {
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

  // ================= END CALL =============================================
  Future<void> end() async {
    _durationTimer?.cancel();
    _durationTimer = null;

    // Tell backend call ended — user web shows rating dialog
    await _updateCallStatus('end_astro');

    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}

    _engine       = null;
    _joined       = false;
    _remoteJoined = false;
    _muted        = false;
    _speakerOn    = true;
    _onHold       = false;
    _callDuration = Duration.zero;

    _safeNotify();
  }

  // ================= SAFE NOTIFY ==========================================
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ================= DISPOSE ==============================================
  @override
  void dispose() {
    _disposed = true;
    _durationTimer?.cancel();
    _engine?.release();
    _engine = null;
    super.dispose();
  }
}