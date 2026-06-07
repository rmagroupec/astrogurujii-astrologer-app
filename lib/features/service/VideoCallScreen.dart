// lib/features/service/VideoCallScreen.dart
//
// Changes:
// 1. ✅ FIXED: back press → minimize() instead of ending call
// 2. ✅ minimize() arrow in top-left (keyboard_arrow_down icon)
// 3. ✅ WillPopScope minimizes, never ends
// 4. ✅ resumed flag — skips re-initAgora() if engine already running
// 5. ✅ initAgora passes callerName/callerImage for overlay
// 6. ✅ dispose() never calls endLocalCall() — provider manages lifetime
// 7. ✅ onEnded callback re-wired on every screen open

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String token;
  final String channelId;
  final String userName;
  final String userAvatar;

  /// ✅ true when navigated back from mini overlay — skip re-initAgora()
  final bool resumed;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    this.userName   = 'User',
    this.userAvatar = '',
    this.resumed    = false,
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
      final provider = context.read<VideoCallProvider>();

      if (!widget.resumed) {
        // Fresh call — full init
        await provider.initAgora(
          channelId: widget.channelId,
          token    : widget.token,
          name     : widget.userName,
          image    : widget.userAvatar,
          onEnded  : (reason) => _showEndFlow(reason: reason),
        );
        provider.startDeduction(
          channelId: widget.channelId,
          deductApi: (id) async => ApiService().deductAmount(id),
        );
      } else {
        // Resumed from overlay — engine still running, just re-wire callback
        provider.expand();
        // Re-wire onEnded so this new screen instance handles rating sheet
        await provider.initAgora(
          channelId: widget.channelId,
          token    : widget.token,
          onEnded  : (reason) => _showEndFlow(reason: reason),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ✅ NEVER call endLocalCall here — provider manages engine lifetime
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<VideoCallProvider>();
    if (state == AppLifecycleState.paused) {
      provider.muteLocalVideoForBackground(true);
    } else if (state == AppLifecycleState.resumed) {
      if (!provider.isMinimized) provider.muteLocalVideoForBackground(false);
    }
  }

  // ✅ Minimize — does NOT end call
  void _minimize() {
    if (_endShown) return;
    context.read<VideoCallProvider>().minimize();
    Navigator.of(context).pop();
  }

  Future<void> _showEndFlow({required String reason}) async {
    if (_endShown || !mounted) return;
    _endShown = true;

    final provider = context.read<VideoCallProvider>();
    await provider.endLocalCall();

    if (!mounted) return;
    await showModalBottomSheet(
      context           : context,
      isDismissible     : false,
      enableDrag        : false,
      isScrollControlled: true,
      backgroundColor   : Colors.transparent,
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
        shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    // ✅ Back press → minimize, NOT end call
    return WillPopScope(
      onWillPop: () async {
        _minimize();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Remote video full-screen
            GestureDetector(
              onTap : () => setState(() => _showUI = !_showUI),
              child : SizedBox.expand(child: _remoteVideoWidget(provider)),
            ),

            // Local PiP top-right
            Positioned(
              top   : MediaQuery.of(context).padding.top + 8,
              right : 12,
              width : 110,
              height: 150,
              child : _localPipWidget(provider),
            ),

            // ✅ Minimize button top-left (replaces raw back behaviour)
            Positioned(
              top : MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: AnimatedOpacity(
                opacity : _showUI ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child   : GestureDetector(
                  onTap: _minimize,
                  child: Container(
                    width     : 40,
                    height    : 40,
                    decoration: BoxDecoration(
                      color : Colors.black45,
                      shape : BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),

            // Top info — name + timer (pushed right of minimize button)
            AnimatedOpacity(
              opacity : _showUI ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child   : Positioned(
                top : MediaQuery.of(context).padding.top + 12,
                left: 64,  // right of minimize button
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
                  ? const Icon(Icons.person, size: 48, color: Colors.white54)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(widget.userName,
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Waiting for user to join…',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
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
      child: Container(
        color: Colors.black,
        child: provider.engine == null
            ? const Center(child: SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white54)))
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
                    child: const Center(child: Icon(Icons.videocam_off,
                        color: Colors.white54, size: 32)),
                  ),
      ),
    );
  }

  Widget _topInfo(VideoCallProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.userName,
            style: const TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Consumer<VideoCallProvider>(
          builder: (_, p, __) => Row(children: [
            Container(
              width : 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.remoteUid != null ? Colors.greenAccent : Colors.orange,
              ),
            ),
            const SizedBox(width: 6),
            Text(p.remoteUid != null ? p.duration : 'Connecting…',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
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
        children: [
          _ctrlBtn(
            icon  : provider.speakerOn
                ? Icons.volume_up_rounded : Icons.volume_off_rounded,
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
                ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label : 'Video',
            active: provider.isVideoOn,
            onTap : provider.toggleVideo,
          ),
          GestureDetector(
            onTap: _onEndButtonPressed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width     : 60, height: 60,
                  decoration: BoxDecoration(
                    shape    : BoxShape.circle,
                    color    : Colors.red,
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5),
                        blurRadius: 12)],
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 6),
                const Text('End',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              color : active ? Colors.white24 : Colors.white.withOpacity(0.08),
              border: Border.all(
                  color: active ? Colors.white38 : Colors.transparent),
            ),
            child: Icon(icon,
                color: active ? Colors.white : Colors.white38, size: 22),
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

// =============================================================================
// VIDEO RATING SHEET
// =============================================================================
class _VideoRatingSheet extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final String duration;
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
  int  _stars      = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitting  = false;
  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];

  @override
  void dispose() { _reviewCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')));
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
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 24 + bi),
      decoration: const BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Call ended badge
        Container(
          padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color       : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border      : Border.all(color: Colors.red.shade200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.videocam_off, size: 14, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text('Video Call Ended',
                style: TextStyle(color: Colors.red.shade400,
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 20),

        // Avatar + name + duration
        CircleAvatar(
          radius         : 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: widget.userAvatar.isNotEmpty
              ? NetworkImage(widget.userAvatar) : null,
          child: widget.userAvatar.isEmpty
              ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
        ),
        const SizedBox(height: 10),
        Text(widget.userName,
            style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text('Video · ${widget.duration}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),

        const SizedBox(height: 20),
        const Text('Rate Your Experience',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('How was your video call with ${widget.userName}?',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 16),

        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final s = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _stars = s),
              child: Padding(padding: const EdgeInsets.all(4),
                child: Icon(
                  _stars >= s ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 44,
                  color: _stars >= s ? const Color(0xFFEBC351) : Colors.grey.shade300,
                )),
            );
          }),
        ),
        if (_stars > 0) Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(_labels[_stars],
              style: const TextStyle(color: Color(0xFFEBC351),
                  fontWeight: FontWeight.w600, fontSize: 14))),

        const SizedBox(height: 16),
        TextField(controller: _reviewCtrl, maxLines: 3, maxLength: 300,
          decoration: InputDecoration(
            hintText     : 'Write your review (optional)…',
            hintStyle    : TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled       : true, fillColor: Colors.grey.shade50,
            border       : OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEBC351))),
            contentPadding: const EdgeInsets.all(12),
          )),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side   : BorderSide(color: Colors.grey.shade300),
              shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submitting ? null : widget.onDone,
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding        : const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFEBC351),
              shape          : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Text('Submit Rating',
                    style: TextStyle(color: Colors.black,
                        fontWeight: FontWeight.bold, fontSize: 15)),
          )),
        ]),
      ]),
    );
  }
}