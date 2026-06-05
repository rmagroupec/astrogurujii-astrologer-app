// lib/features/live/GoLiveScreen.dart
//
// Zero UI changes from the original.
// Fixes applied (logic only):
// 1. StatelessWidget → StatefulWidget
// 2. channelProfileLiveBroadcasting (was missing entirely)
// 3. setClientRole(Broadcaster) before joinChannel
// 4. Camera preview shown before going live
// 5. "Click to Go Live" calls Liveservice().LiveStart then joinChannel
// 6. "End Live" calls Liveservice().LiveEnd then leaveChannel
// 7. Mic / camera toggle actually mute the engine
// 8. Firebase chat listener wired up (same as the existing GoLiveScreen doc)
// 9. Viewer count from Firebase LiveViewers node

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/model/AstrologerLiveEventsListModel.dart';
import 'package:astrologer_app/service/liveService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoLiveScreen extends StatefulWidget {
  final LiveEventData? event;
  const GoLiveScreen({super.key, this.event});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen>
    with WidgetsBindingObserver {
  // ── Constants ──────────────────────────────────────────────────────────────
  static const _appId  = "8782e154141a4c0bbc8acaa3004d21f2";
  static const _dbUrl  =
      "https://astrogurujii-production-default-rtdb.firebaseio.com/";

  // ── Agora ──────────────────────────────────────────────────────────────────
  RtcEngine? _engine;
  bool _engineReady = false;
  bool _isLive      = false;
  bool _isLoading   = false;
  bool _micOn       = true;
  bool _camOn       = true;

  // ── Viewer count ───────────────────────────────────────────────────────────
  int  _viewerCount = 0;
  StreamSubscription<DatabaseEvent>? _viewerSub;
  DatabaseReference? _viewerRef;

  // ── Chat ───────────────────────────────────────────────────────────────────
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus            = FocusNode();
  DatabaseReference? _chatRef;
  String _astroId   = '';
  String _astroName = '';
  bool   _chatReady = false;
  bool   _showChat  = true;

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _channelId {
    final ch = widget.event?.channelId ?? '';
    return ch.isNotEmpty ? ch : (widget.event?.id ?? 'live_default');
  }

  DatabaseReference get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _dbUrl,
      ).ref();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _boot();
  }

  Future<void> _boot() async {
    await _loadUser();
    await _initAgora();
    _initFirebase();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine?.muteLocalVideoStream(true);
    } else if (state == AppLifecycleState.resumed) {
      if (_camOn) _engine?.muteLocalVideoStream(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewerSub?.cancel();
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _engine?.stopPreview();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  // ── Load user info ─────────────────────────────────────────────────────────
  Future<void> _loadUser() async {
    final p  = await SharedPreferences.getInstance();
    _astroId   = p.getString('astro_id')   ?? '';
    _astroName = p.getString('astro_name') ?? 'Astrologer';
  }

  // ── Init Agora — preview only, no joinChannel yet ──────────────────────────
  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();

    await _engine!.initialize(
      const RtcEngineContext(
        appId: _appId,
        // ✅ FIX 1: LiveBroadcasting — required for one-to-many streaming
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (_, uid, __) {
          _viewerRef?.child(uid.toString()).set(true);
        },
        onUserOffline: (_, uid, __) {
          _viewerRef?.child(uid.toString()).remove();
        },
        onError: (code, msg) => debugPrint('❌ Agora $code: $msg'),
      ),
    );

    // ✅ FIX 2: broadcaster role before anything else
    await _engine!.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview(); // camera on before going live

    if (mounted) setState(() => _engineReady = true);
  }

  // ── Init Firebase ──────────────────────────────────────────────────────────
  void _initFirebase() {
    _chatRef  = _db.child('GroupLive').child(_channelId);
    _viewerRef = _db.child('LiveViewers').child(_channelId);

    _viewerSub = _viewerRef!.onValue.listen((event) {
      final val   = event.snapshot.value;
      final count = (val is Map) ? val.length : 0;
      if (mounted) setState(() => _viewerCount = count);
    });

    if (mounted) setState(() => _chatReady = true);
  }

  // ── Go Live ────────────────────────────────────────────────────────────────
  Future<void> _startLive() async {
    if (widget.event?.id == null) {
      _toast('No event ID found', error: true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final body = await Liveservice().LiveStart(widget.event!.id!);
      if (!mounted) return;

      if (body['status'] == true) {
        // ✅ FIX 3: joinChannel with token returned from live_start
        final agoraToken = body['token'] as String? ?? '';
        await _engine!.joinChannel(
          token    : agoraToken,
          channelId: _channelId,
          uid      : 0,
          options  : const ChannelMediaOptions(
            clientRoleType        : ClientRoleType.clientRoleBroadcaster,
            channelProfile        : ChannelProfileType.channelProfileLiveBroadcasting,
            publishCameraTrack    : true,
            publishMicrophoneTrack: true,
            autoSubscribeVideo    : false,
            autoSubscribeAudio    : false,
          ),
        );

        await _postSystemMsg('🔴 Live session started!');
        if (mounted) setState(() => _isLive = true);
      } else {
        _toast(body['message'] ?? 'Cannot go live right now', error: true);
      }
    } catch (e) {
      debugPrint('❌ startLive: $e');
      if (mounted) _toast('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── End Live ───────────────────────────────────────────────────────────────
  Future<void> _endLive() async {
    setState(() => _isLoading = true);
    try {
      await _engine?.leaveChannel();
      await _viewerRef?.remove();
      await _postSystemMsg('⏹ Live session ended.');

      final body = await Liveservice().LiveEnd(widget.event!.id!);
      if (!mounted) return;

      if (body['status'] == true) {
        Navigator.pop(context);
      } else {
        setState(() { _isLive = false; _isLoading = false; });
        _toast(body['message'] ?? 'Failed to end live', error: true);
      }
    } catch (e) {
      debugPrint('❌ endLive: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmEnd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title  : const Text('End Live Session?'),
        content: const Text(
            'Viewers will be disconnected. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child    : const Text('End Live',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes == true) _endLive();
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Future<void> _toggleMic() async {
    _micOn = !_micOn;
    await _engine?.muteLocalAudioStream(!_micOn);
    setState(() {});
  }

  Future<void> _toggleCam() async {
    _camOn = !_camOn;
    await _engine?.muteLocalVideoStream(!_camOn);
    setState(() {});
  }

  // ── Chat helpers ───────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    _msgFocus.unfocus();
    await _writeChat(name: _astroName, message: text, isSystem: false);
  }

  Future<void> _postSystemMsg(String msg) async {
    await _writeChat(name: 'System', message: msg, isSystem: true);
  }

  Future<void> _writeChat({
    required String name,
    required String message,
    required bool isSystem,
  }) async {
    if (_chatRef == null) return;
    final ref = _chatRef!.push();
    await ref.set({
      'from'      : isSystem ? 'system' : _astroId,
      'name'      : name,
      'message'   : message,
      'message_id': ref.key,
      'date_time' : DateTime.now().millisecondsSinceEpoch,
      'is_system' : isSystem,
    });
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: error
          ? Colors.red.shade700
          : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape   : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq  = MediaQuery.of(context);
    final sw  = mq.size.width;
    final sh  = mq.size.height;
    final top = mq.padding.top;
    final bot = mq.padding.bottom;

    return WillPopScope(
      onWillPop: () async {
        if (_isLive) { _confirmEnd(); return false; }
        return true;
      },
      child: Scaffold(
        backgroundColor            : Colors.black,
        resizeToAvoidBottomInset   : true,
        body: Stack(
          children: [

            // ── LAYER 1: full-screen camera feed ────────────────────────────
            Positioned.fill(
              child: _engineReady && _engine != null
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine       : _engine!,
                        canvas          : const VideoCanvas(uid: 0),
                        useFlutterTexture: true,
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0D0D1A),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFCD417)),
                      ),
                    ),
            ),

            // ── LAYER 2: top gradient ────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              height: sh * 0.25,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin  : Alignment.topCenter,
                    end    : Alignment.bottomCenter,
                    colors : [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── LAYER 3: bottom gradient ─────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: sh * 0.42,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin  : Alignment.bottomCenter,
                    end    : Alignment.topCenter,
                    colors : [Colors.black, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── LAYER 4: top bar ─────────────────────────────────────────────
            Positioned(
              top  : top + 12,
              left : sw * 0.04,
              right: sw * 0.04,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  GestureDetector(
                    onTap: () => _isLive
                        ? _confirmEnd()
                        : Navigator.pop(context),
                    child: Container(
                      padding   : const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color        : Colors.black45,
                        borderRadius : BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event?.title ?? 'Live Session',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color     : Colors.white,
                            fontSize  : sw * 0.042,
                            fontWeight: FontWeight.bold,
                            shadows   : const [Shadow(
                                color    : Colors.black54,
                                blurRadius: 8)],
                          ),
                        ),
                        if ((widget.event?.liveDate ?? '').isNotEmpty)
                          Text(
                            '${widget.event!.liveDate}  '
                            '${widget.event!.startTime ?? ''}',
                            style: TextStyle(
                              color   : Colors.white60,
                              fontSize: sw * 0.030,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_isLive) ...[
                    _LiveBadge(sw: sw),
                    const SizedBox(width: 8),
                  ],

                  if (_isLive) ...[
                    _ViewerBadge(count: _viewerCount, sw: sw),
                    const SizedBox(width: 8),
                  ],

                  GestureDetector(
                    onTap: () =>
                        setState(() => _showChat = !_showChat),
                    child: Container(
                      padding   : const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color       : Colors.black45,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _showChat
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size : sw * 0.052,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── LAYER 5: SVG face frame (before going live) ─────────────────
            if (!_isLive)
              Positioned(
                top : sh * 0.16,
                left: 0, right: 0,
                child: Center(
                  child: SizedBox(
                    height: sh * 0.36,
                    width : sw * 0.70,
                    child : Stack(children: [
                      Positioned.fill(
                        child: SvgPicture.asset(
                          'assets/images/go_live.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        bottom: sh * 0.04,
                        left  : 0, right: 0,
                        child : const Center(
                          child: Text(
                            'Face Here',
                            style: TextStyle(
                              color     : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize  : 15,
                              shadows   : [Shadow(
                                  color    : Colors.black,
                                  blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

            // ── LAYER 6: chat messages ───────────────────────────────────────
            if (_isLive && _showChat && _chatReady && _chatRef != null)
              Positioned(
                bottom: bot + sh * 0.155,
                left  : sw * 0.03,
                width : sw * 0.64,
                height: sh * 0.28,
                child : ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
                        begin  : Alignment.topCenter,
                        end    : Alignment.bottomCenter,
                        colors : [Colors.transparent, Colors.white],
                        stops  : [0.0, 0.25],
                      ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child    : FirebaseAnimatedList(
                    query  : _chatRef!
                        .orderByChild('date_time')
                        .limitToLast(50),
                    reverse: true,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (_, snap, __, ___) {
                      final raw = snap.value;
                      if (raw == null) return const SizedBox.shrink();
                      final data = Map<String, dynamic>.from(
                          raw as Map<dynamic, dynamic>);
                      final isMe =
                          data['from'] == _astroId;
                      final isSystem =
                          data['is_system'] == true;

                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: sh * 0.007),
                        child: _ChatBubble(
                          name    : data['name']    ?? '',
                          message : data['message'] ?? '',
                          isMe    : isMe,
                          isSystem: isSystem,
                          sw      : sw,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── LAYER 7: chat input ──────────────────────────────────────────
            if (_isLive)
              Positioned(
                bottom: bot + sh * 0.12,
                left  : sw * 0.03,
                right : sw * 0.03,
                child : _ChatInput(
                  controller: _msgCtrl,
                  focusNode : _msgFocus,
                  onSend    : _sendMessage,
                  sw: sw, sh: sh,
                ),
              ),

            // ── LAYER 8: bottom controls ─────────────────────────────────────
            Positioned(
              bottom: bot + sh * 0.015,
              left  : sw * 0.03,
              right : sw * 0.03,
              child : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Mic toggle
                  _ControlButton(
                    svgPath: 'assets/images/mic.svg',
                    active : _micOn,
                    onTap  : _isLoading ? null : _toggleMic,
                    size   : sw * 0.14,
                  ),

                  SizedBox(width: sw * 0.03),

                  // Camera toggle
                  _ControlButton(
                    svgPath: 'assets/images/video-camera.svg',
                    active : _camOn,
                    onTap  : _isLoading ? null : _toggleCam,
                    size   : sw * 0.14,
                  ),

                  SizedBox(width: sw * 0.03),

                  // ✅ FIX 4: button actually calls _startLive / _confirmEnd
                  Expanded(
                    child: GradientButton(
                      height: sw * 0.14,
                      title : _isLoading
                          ? 'Please wait...'
                          : _isLive
                              ? 'End Live'
                              : 'Click to Go Live',
                      onTap : _isLoading
                          ? () {}
                          : _isLive
                              ? _confirmEnd
                              : _startLive,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            // ── LAYER 9: loading overlay ─────────────────────────────────────
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: Color(0xFFFCD417)),
                        SizedBox(height: 12),
                        Text('Please wait...',
                            style: TextStyle(
                                color   : Colors.white70,
                                fontSize: 14)),
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
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  final double sw;
  const _LiveBadge({required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.025, vertical: 4),
      decoration: BoxDecoration(
        color       : Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow   : [
          BoxShadow(
              color      : Colors.red.withOpacity(0.5),
              blurRadius : 8,
              spreadRadius: 1)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: Colors.white, size: 7),
          SizedBox(width: sw * 0.01),
          Text('LIVE',
              style: TextStyle(
                  color      : Colors.white,
                  fontSize   : sw * 0.028,
                  fontWeight : FontWeight.bold,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _ViewerBadge extends StatelessWidget {
  final int count;
  final double sw;
  const _ViewerBadge({required this.count, required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.025, vertical: 4),
      decoration: BoxDecoration(
        color       : Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border      : Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_red_eye_outlined,
              color: Colors.white70, size: sw * 0.038),
          SizedBox(width: sw * 0.012),
          Text('$count',
              style: TextStyle(
                  color     : Colors.white,
                  fontSize  : sw * 0.032,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String name;
  final String message;
  final bool   isMe;
  final bool   isSystem;
  final double sw;

  const _ChatBubble({
    required this.name,
    required this.message,
    required this.isMe,
    required this.isSystem,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    if (isSystem) {
      return Center(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.03, vertical: 3),
          decoration: BoxDecoration(
            color       : Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(message,
              style: TextStyle(
                  color   : Colors.white54,
                  fontSize: sw * 0.028)),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.03, vertical: sw * 0.012),
      decoration: BoxDecoration(
        color       : Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text : '$name  ',
            style: TextStyle(
              color     : isMe
                  ? const Color(0xFFFCD417)
                  : Colors.lightBlueAccent,
              fontSize  : sw * 0.031,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text : message,
            style: TextStyle(
                color   : Colors.white,
                fontSize: sw * 0.031),
          ),
        ]),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final VoidCallback          onSend;
  final double                sw, sh;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          height : sh * 0.052,
          padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
          decoration: BoxDecoration(
            color       : Colors.black.withOpacity(0.60),
            borderRadius: BorderRadius.circular(30),
            border      : Border.all(color: Colors.white24),
          ),
          child: TextField(
            controller: controller,
            focusNode : focusNode,
            style     : TextStyle(
                color: Colors.white, fontSize: sw * 0.034),
            decoration: InputDecoration(
              hintText      : 'Say something...',
              hintStyle     : TextStyle(
                  color: Colors.white38, fontSize: sw * 0.032),
              border        : InputBorder.none,
              isDense       : true,
              contentPadding: EdgeInsets.symmetric(
                  vertical: sh * 0.014),
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
      ),
      SizedBox(width: sw * 0.025),
      GestureDetector(
        onTap: onSend,
        child: Container(
          width : sh * 0.052,
          height: sh * 0.052,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFCD417),
          ),
          child: Icon(Icons.send_rounded,
              color: Colors.black, size: sw * 0.045),
        ),
      ),
    ]);
  }
}

class _ControlButton extends StatelessWidget {
  final String    svgPath;
  final bool      active;
  final VoidCallback? onTap;
  final double    size;

  const _ControlButton({
    required this.svgPath,
    required this.active,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration : const Duration(milliseconds: 200),
        width    : size,
        height   : size,
        padding  : EdgeInsets.all(size * 0.22),
        decoration: BoxDecoration(
          shape    : BoxShape.circle,
          color    : active ? Colors.white : Colors.red.shade600,
          boxShadow: [
            BoxShadow(
              color : (active ? Colors.white : Colors.red)
                  .withOpacity(0.25),
              blurRadius: 8,
              offset    : const Offset(0, 3),
            )
          ],
        ),
        child: SvgPicture.asset(
          svgPath,
          colorFilter: ColorFilter.mode(
            active ? Colors.black : Colors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}