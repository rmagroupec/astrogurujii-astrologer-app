// lib/features/live/PujaLiveScreen.dart
//
// The actual puja broadcast screen. This is what was missing entirely:
// "Start Live" previously just flipped a flag on the server (and even that
// was hitting the wrong endpoint), so the astrologer's camera never opened
// and nothing was ever published to Agora.
//
// Flow:
//   PoojaBookingScreen "Start Live"
//     → ApiService().PoojaStartLive(booking.id)      (server: is_live + token)
//     → Navigator.push(PujaLiveScreen(...))          (this screen)
//     → Agora joinChannel as broadcaster, camera live
//     → "End Live" → ApiService().PoojaEndLive(...)  → leave + release
//
// Modelled on the working GoLiveScreen's Agora setup (same App ID, same
// live-broadcasting profile, same broadcaster role) so behaviour is
// consistent with the existing regular-live feature.

import 'dart:async';
import 'dart:ui';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/modal/PujaLiveModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PujaLiveScreen extends StatefulWidget {
  /// Booking's Mongo _id — used for end/token calls.
  final String pujaId;

  /// Title shown in the header (puja type / name).
  final String pujaTitle;

  /// Everything the server handed back from puja_live_start.
  final PujaLiveResponse session;

  const PujaLiveScreen({
    super.key,
    required this.pujaId,
    required this.pujaTitle,
    required this.session,
  });

  @override
  State<PujaLiveScreen> createState() => _PujaLiveScreenState();
}

class _PujaLiveScreenState extends State<PujaLiveScreen> {
  // Same App ID the existing GoLiveScreen uses; the server also returns one,
  // and the server's value wins so the two can never drift apart.
  static const _fallbackAppId = "8782e154141a4c0bbc8acaa3004d21f2";

  RtcEngine? _engine;

  bool   _engineReady = false;
  bool   _joined      = false;
  bool   _ending      = false;
  String _error       = '';

  bool _micOn  = true;
  bool _camOn  = true;
  bool _frontCam = true;

  Timer?   _timer;
  Duration _elapsed = Duration.zero;

  String get _channelId => widget.session.channelId;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Fire-and-forget teardown — dispose can't await.
    _engine?.stopPreview();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  // ── Bring-up ──────────────────────────────────────────────────────────────
  Future<void> _start() async {
    try {
      // Camera/mic are requested app-wide at launch, but a user can revoke
      // them — asking again here means "Start Live" never silently fails.
      final perms = await [Permission.camera, Permission.microphone].request();
      final denied = perms.values.any((s) => !s.isGranted);
      if (denied) {
        setState(() => _error =
            'Camera and microphone permission are required to go live.');
        return;
      }

      await _initAgora();
      await _joinChannel();
    } catch (e) {
      debugPrint('❌ puja live start error: $e');
      if (mounted) setState(() => _error = 'Could not start the live: $e');
    }
  }

  Future<void> _initAgora() async {
    final appId = widget.session.appId.isNotEmpty
        ? widget.session.appId
        : _fallbackAppId;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId         : appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, elapsed) {
        debugPrint('✅ puja live joined: ${conn.channelId} uid=${conn.localUid}');
        if (!mounted) return;
        setState(() => _joined = true);
        _startTimer();
      },

      onUserJoined: (conn, uid, __) => debugPrint('👤 viewer joined: $uid'),
      onUserOffline: (conn, uid, __) => debugPrint('👤 viewer left: $uid'),

      // A puja can easily run longer than the 1 hour token lifetime. Without
      // this the stream silently drops when the token expires.
      onTokenPrivilegeWillExpire: (conn, token) async {
        debugPrint('🔑 puja live token expiring — refreshing');
        try {
          final res = await ApiService().PoojaLiveToken(widget.pujaId);
          if (res.status && res.token.isNotEmpty) {
            await _engine?.renewToken(res.token);
            debugPrint('🔑 token renewed');
          }
        } catch (e) {
          debugPrint('❌ token refresh failed: $e');
        }
      },

      onError: (code, msg) => debugPrint('❌ Agora $code: $msg'),
    ));

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview();

    if (mounted) setState(() => _engineReady = true);
  }

  Future<void> _joinChannel() async {
    await _engine?.joinChannel(
      token    : widget.session.token,
      channelId: _channelId,
      uid      : widget.session.uid,
      options  : const ChannelMediaOptions(
        clientRoleType        : ClientRoleType.clientRoleBroadcaster,
        channelProfile        : ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack    : true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  String get _elapsedLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  Future<void> _toggleMic() async {
    final next = !_micOn;
    await _engine?.muteLocalAudioStream(!next);
    if (mounted) setState(() => _micOn = next);
  }

  Future<void> _toggleCam() async {
    final next = !_camOn;
    await _engine?.muteLocalVideoStream(!next);
    if (next) {
      await _engine?.startPreview();
    } else {
      await _engine?.stopPreview();
    }
    if (mounted) setState(() => _camOn = next);
  }

  Future<void> _switchCam() async {
    await _engine?.switchCamera();
    if (mounted) setState(() => _frontCam = !_frontCam);
  }

  Future<void> _confirmEnd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title  : const Text('End puja live?'),
        content: const Text(
            'Viewers will be disconnected and the puja will be marked as no '
            'longer live.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child    : const Text('Keep streaming'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child    : const Text('End live'),
          ),
        ],
      ),
    );
    if (ok == true) await _endLive();
  }

  Future<void> _endLive() async {
    if (_ending) return;
    setState(() => _ending = true);

    _timer?.cancel();

    // Tell the server first so is_live flips even if teardown throws.
    try {
      await ApiService().PoojaEndLive(widget.pujaId);
    } catch (e) {
      debugPrint('❌ puja_live_end failed: $e');
    }

    try { await _engine?.stopPreview(); }  catch (_) {}
    try { await _engine?.leaveChannel(); } catch (_) {}
    try { await _engine?.release(); }      catch (_) {}
    _engine = null;

    if (mounted) Navigator.of(context).pop(true); // true → refresh the list
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back must not silently abandon a running stream.
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && !_ending) _confirmEnd();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _videoLayer(),

            // Soft scrim so the top bar text stays legible over any footage.
            Positioned(
              top: 0, left: 0, right: 0, height: 130,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin : Alignment.topCenter,
                      end   : Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Matching scrim behind the bottom control bar.
            Positioned(
              bottom: 0, left: 0, right: 0, height: 170,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin : Alignment.bottomCenter,
                      end   : Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // Pinned to the top edge — without Positioned/Align here the
            // Stack's StackFit.expand stretches _topBar()'s Row to the full
            // screen height and Row centers its children vertically inside
            // it, dropping the LIVE badge/timer/title to mid-screen.
            Positioned(
              top: 0, left: 0, right: 0,
              child: _topBar(),
            ),
            _bottomControls(),

            if (_ending)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                    decoration: BoxDecoration(
                      color       : const Color(0xFF1B1B2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 14),
                        Text('Ending live…',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _videoLayer() {
    if (_error.isNotEmpty) {
      return Container(
        color: const Color(0xFF0E0E1C),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_off_rounded,
                      color: Colors.white70, size: 42),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Unable to start puja live',
                  style: TextStyle(
                    color     : Colors.white,
                    fontSize  : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Go back',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_engineReady) {
      return Container(
        color: const Color(0xFF0E0E1C),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width : 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor : AlwaysStoppedAnimation(AppTheme.primaryYellow),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Preparing camera…',
                  style: TextStyle(
                    color     : Colors.white70,
                    fontSize  : 13,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 4),
              Text('Getting your puja live ready',
                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
            ],
          ),
        ),
      );
    }

    if (!_camOn) {
      return Container(
        color: const Color(0xFF14142B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam_off_rounded,
                    color: Colors.white38, size: 46),
              ),
              const SizedBox(height: 14),
              const Text('Camera is off',
                  style: TextStyle(
                    color     : Colors.white54,
                    fontSize  : 14,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 4),
              Text('Your audience only hears you now',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ],
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas   : const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _topBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LIVE / CONNECTING badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color       : _joined ? const Color(0xFFE0203A) : Colors.orange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_joined ? const Color(0xFFE0203A) : Colors.orange)
                        .withOpacity(0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_joined)
                    Container(
                      width : 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(
                      width : 9,
                      height: 9,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        valueColor : AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _joined ? 'LIVE' : 'CONNECTING',
                    style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),

            if (_joined) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color       : Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _elapsedLabel,
                      style: const TextStyle(
                        color     : Colors.white,
                        fontSize  : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Puja title
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.pujaTitle,
                    textAlign: TextAlign.right,
                    maxLines : 1,
                    overflow : TextOverflow.ellipsis,
                    style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Puja Live',
                    style: TextStyle(
                      color     : Colors.white.withOpacity(0.55),
                      fontSize  : 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin : const EdgeInsets.only(bottom: 20, left: 18, right: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(44),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color       : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circleBtn(
                      icon   : _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      active : _micOn,
                      label  : 'Mic',
                      onTap  : _engineReady ? _toggleMic : null,
                    ),
                    _circleBtn(
                      icon   : _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      active : _camOn,
                      label  : 'Camera',
                      onTap  : _engineReady ? _toggleCam : null,
                    ),
                    _circleBtn(
                      icon   : Icons.cameraswitch_rounded,
                      active : true,
                      label  : _frontCam ? 'Front' : 'Back',
                      onTap  : _engineReady && _camOn ? _switchCam : null,
                    ),
                    _circleBtn(
                      icon    : Icons.call_end_rounded,
                      active  : true,
                      label   : 'End',
                      bgColor : const Color(0xFFE0203A),
                      onTap   : _ending ? null : _confirmEnd,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required bool     active,
    required String   label,
    VoidCallback?     onTap,
    Color?            bgColor,
  }) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width : bgColor != null ? 54 : 50,
              height: bgColor != null ? 54 : 50,
              decoration: BoxDecoration(
                color: bgColor ??
                    (active ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.08)),
                shape: BoxShape.circle,
                boxShadow: bgColor != null
                    ? [
                        BoxShadow(
                          color: bgColor.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: bgColor != null ? 24 : 21),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                color     : Colors.white70,
                fontSize  : 10,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}