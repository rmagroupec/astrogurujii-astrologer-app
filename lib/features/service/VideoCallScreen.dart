// lib/features/service/VideoCallScreen.dart  (ASTROLOGER APP)
//
// Fixes from doc 1 (current code):
// 1. Added userName + userAvatar fields (NavigationManager must pass them)
// 2. initAgora() wires onEnded: _showEndFlow callback
// 3. _showEndFlow() shows rating bottom sheet after call ends
// 4. All existing UI (remote video, local PiP, top info, bottom controls) identical

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String token;
  final String channelId;
  final String userName;     // ✅ added
  final String userAvatar;   // ✅ added

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    this.userName   = 'User',
    this.userAvatar = '',
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with WidgetsBindingObserver {
  bool _showUI   = true;
  bool _endShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      if (!mounted) return;
      final provider = Provider.of<VideoCallProvider>(context, listen: false);

      await provider.initAgora(
        channelId: widget.channelId,
        token    : widget.token,
        // ✅ FIX: wire end callback so rating sheet shows
        onEnded  : (reason) => _showEndFlow(reason: reason),
      );

      provider.startDeduction(
        channelId: widget.channelId,
        deductApi: (id) async => ApiService().deductAmount(id),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = Provider.of<VideoCallProvider>(context, listen: false);
    if (state == AppLifecycleState.paused) {
      provider.muteLocalVideoForBackground(true);
    } else if (state == AppLifecycleState.resumed) {
      provider.muteLocalVideoForBackground(false);
    }
  }

  Future<void> _showEndFlow({required String reason}) async {
    if (_endShown || !mounted) return;
    _endShown = true;

    final provider = Provider.of<VideoCallProvider>(context, listen: false);
    await provider.endLocalCall();

    if (!mounted) return;
    await showModalBottomSheet(
      context         : context,
      isDismissible   : false,
      enableDrag      : false,
      isScrollControlled: true,
      backgroundColor : Colors.transparent,
      builder: (_) => _VideoRatingSheet(
        userName  : widget.userName,
        userAvatar: widget.userAvatar,
        duration  : provider.duration,
        onDone    : () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // close call screen
        },
      ),
    );
  }

  void _onEndButtonPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title  : const Text('End Call',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end this video call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child    : const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showEndFlow(reason: 'You ended the call.');
            },
            child: const Text('End Call',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoCallProvider>();

    return WillPopScope(
      onWillPop: () async {
        _showEndFlow(reason: 'You ended the call.');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Remote video full-screen
            GestureDetector(
              onTap: () => setState(() => _showUI = !_showUI),
              child: SizedBox.expand(
                  child: _remoteVideoWidget(provider)),
            ),

            // Local PiP top-right
            Positioned(
              top   : MediaQuery.of(context).padding.top + 8,
              right : 12,
              width : 110,
              height: 150,
              child : _localPipWidget(provider),
            ),

            // Top info
            AnimatedOpacity(
              opacity : _showUI ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child   : Positioned(
                top : MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: _topInfo(provider),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0, left: 0, right: 0,
              child : AnimatedSlide(
                offset  : _showUI ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 250),
                child   : AnimatedOpacity(
                  opacity : _showUI ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child   : _bottomControls(provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remoteVideoWidget(VideoCallProvider provider) {
    if (provider.engine == null || provider.remoteUid == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            CircleAvatar(
              radius         : 48,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: widget.userAvatar.isNotEmpty
                  ? NetworkImage(widget.userAvatar)
                  : null,
              child: widget.userAvatar.isEmpty
                  ? const Icon(Icons.person,
                      size: 48, color: Colors.white54)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(widget.userName,
                style: const TextStyle(
                    color     : Colors.white,
                    fontSize  : 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Waiting for user to join…',
                style: TextStyle(
                    color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine : provider.engine!,
        canvas    : VideoCanvas(uid: provider.remoteUid!),
        connection: RtcConnection(channelId: widget.channelId),
      ),
    );
  }

  Widget _localPipWidget(VideoCallProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child       : Container(
        color: Colors.black,
        child: provider.engine == null
            ? const Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white54),
                ),
              )
            : provider.isVideoOn
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine       : provider.engine!,
                      canvas          : const VideoCanvas(uid: 0),
                      useFlutterTexture: true,
                    ),
                  )
                : Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(Icons.videocam_off,
                          color: Colors.white54, size: 32),
                    ),
                  ),
      ),
    );
  }

  Widget _topInfo(VideoCallProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children          : [
        Text(widget.userName,
            style: const TextStyle(
                color     : Colors.white,
                fontSize  : 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Consumer<VideoCallProvider>(
          builder: (_, p, __) => Row(
            children: [
              Container(
                width : 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.remoteUid != null
                      ? Colors.greenAccent
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                p.remoteUid != null ? p.duration : 'Connecting…',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomControls(VideoCallProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        top   : 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left  : 16, right: 16,
      ),
      decoration: const BoxDecoration(
        color       : Color(0xBB000000),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children         : [
          _ctrlBtn(
            icon  : provider.speakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label : 'Speaker',
            active: provider.speakerOn,
            onTap : provider.toggleSpeaker,
          ),
          _ctrlBtn(
            icon  : provider.muted ? Icons.mic_off : Icons.mic,
            label : 'Mute',
            active: !provider.muted,
            onTap : provider.toggleMute,
          ),
          _ctrlBtn(
            icon  : Icons.cameraswitch_rounded,
            label : 'Flip',
            active: true,
            onTap : provider.switchCamera,
          ),
          _ctrlBtn(
            icon  : provider.isVideoOn
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label : 'Video',
            active: provider.isVideoOn,
            onTap : provider.toggleVideo,
          ),
          GestureDetector(
            onTap: _onEndButtonPressed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children    : [
                Container(
                  width     : 60, height: 60,
                  decoration: BoxDecoration(
                    shape    : BoxShape.circle,
                    color    : Colors.red,
                    boxShadow: [
                      BoxShadow(
                          color    : Colors.red.withOpacity(0.5),
                          blurRadius: 12)
                    ],
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 6),
                const Text('End',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData     icon,
    required String       label,
    required bool         active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children    : [
          Container(
            width     : 50, height: 50,
            decoration: BoxDecoration(
              shape : BoxShape.circle,
              color : active
                  ? Colors.white24
                  : Colors.white.withOpacity(0.08),
              border: Border.all(
                  color: active
                      ? Colors.white38
                      : Colors.transparent),
            ),
            child: Icon(icon,
                color: active ? Colors.white : Colors.white38,
                size : 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color   : active ? Colors.white70 : Colors.white30,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Rating sheet (same as doc 1) ──────────────────────────────────────────────
class _VideoRatingSheet extends StatefulWidget {
  final String     userName;
  final String     userAvatar;
  final String     duration;
  final VoidCallback onDone;

  const _VideoRatingSheet({
    required this.userName,
    required this.userAvatar,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_VideoRatingSheet> createState() => _VideoRatingSheetState();
}

class _VideoRatingSheetState extends State<_VideoRatingSheet> {
  int    _stars      = 0;
  bool   _submitting = false;
  final  _reviewCtrl = TextEditingController();

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];

  @override
  void dispose() { _reviewCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rating')));
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _submitting = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final bi = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding   : EdgeInsets.only(
          left: 20, right: 20, top: 24, bottom: 24 + bi),
      decoration: const BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children    : [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color       : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Session card
          Container(
            padding   : const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color       : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              CircleAvatar(
                radius         : 26,
                backgroundColor: Colors.grey.shade700,
                backgroundImage: widget.userAvatar.isNotEmpty
                    ? NetworkImage(widget.userAvatar)
                    : null,
                child: widget.userAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children          : [
                    Text(widget.userName,
                        style: const TextStyle(
                            color     : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize  : 15)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.videocam_rounded,
                          size: 13, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text('Video Call · ${widget.duration}',
                          style: const TextStyle(
                              color  : Colors.white54,
                              fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              Container(
                padding   : const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color       : Colors.red.shade900,
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('Ended',
                    style: TextStyle(
                        color     : Colors.white,
                        fontSize  : 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          const Text('Rate Your Experience',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('How was your video call with ${widget.userName}?',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children         : List.generate(5, (i) {
              final s = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _stars = s),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child  : Icon(
                    _stars >= s
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size : 44,
                    color: _stars >= s
                        ? const Color(0xFFEBC351)
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),

          if (_stars > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child  : Text(_labels[_stars],
                  style: const TextStyle(
                      color     : Color(0xFFEBC351),
                      fontWeight: FontWeight.w600,
                      fontSize  : 14)),
            ),

          const SizedBox(height: 20),

          TextField(
            controller: _reviewCtrl,
            maxLines  : 3,
            maxLength : 300,
            decoration: InputDecoration(
              hintText   : 'Write your review (optional)…',
              hintStyle  : TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              filled     : true,
              fillColor  : Colors.grey.shade50,
              border     : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide  :
                      BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide  :
                      BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide  : const BorderSide(
                      color: Color(0xFFEBC351))),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                style    : OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side   : BorderSide(color: Colors.grey.shade300),
                  shape  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitting ? null : widget.onDone,
                child    : const Text('Skip',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex : 2,
              child: ElevatedButton(
                style    : ElevatedButton.styleFrom(
                  padding        : const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFEBC351),
                  shape          : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _submitting ? null : _submit,
                child    : _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('Submit Rating',
                        style: TextStyle(
                            color     : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize  : 15)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}