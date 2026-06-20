// lib/features/service/VideoCallScreen.dart
// ── UI: Images 2 & 3 — top bar matching AudioCallScreen, info toggle, PiP ────
// ── Theme-aware: rating sheet uses AppColors ──────────────────────────────────
// ── Zero functional changes ───────────────────────────────────────────────────

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String token;
  final String channelId;
  final String userName;
  final String userAvatar;
  final bool   resumed;

  // Optional user info for info panel
  final String userId;
  final String gender;
  final String dob;
  final String pob;
  final String remainingTime;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    this.userName      = 'User',
    this.userAvatar    = '',
    this.resumed       = false,
    this.userId        = '',
    this.gender        = '',
    this.dob           = '',
    this.pob           = '',
    this.remainingTime = '',
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with WidgetsBindingObserver {

  bool _showInfo = false;
  bool _endShown = false;

  static const _gold     = Color(0xFFE6A817);
  static const _darkText = Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      if (!mounted) return;
      final provider = context.read<VideoCallProvider>();

      if (!widget.resumed) {
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
        provider.expand();
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
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onEndButtonPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape  : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title  : const Text('End Call',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end this video call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
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
    final provider    = context.watch<VideoCallProvider>();
    final isConnected = provider.remoteUid != null;

    return WillPopScope(
      onWillPop: () async { _minimize(); return false; },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [

            // ── Remote video full-screen ────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _showInfo = false),
              child: SizedBox.expand(child: _remoteVideoWidget(provider)),
            ),

            // ── Local PiP — bottom-right, above controls ────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 104,
              right : 12,
              width : 100,
              height: 140,
              child : _localPipWidget(provider),
            ),

            // ── Top gradient ────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: MediaQuery.of(context).padding.top + 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin  : Alignment.topCenter,
                    end    : Alignment.bottomCenter,
                    colors : [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Top bar — matches AudioCallScreen exactly ───────────────
            Positioned(
              top : MediaQuery.of(context).padding.top + 8,
              left: 12, right: 12,
              child: Row(
                children: [
                  // Back / minimize
                  GestureDetector(
                    onTap: _minimize,
                    child: Container(
                      width : 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name + timer (centered)
                  Expanded(
                    child: Column(
                      children: [
                        Text(widget.userName,
                            style: const TextStyle(
                                color     : Colors.white,
                                fontSize  : 16,
                                fontWeight: FontWeight.w700)),
                        Consumer<VideoCallProvider>(
                          builder: (_, p, __) => Text(
                            p.remoteUid != null ? p.duration : 'Connecting…',
                            style: TextStyle(
                                color  : isConnected
                                    ? Colors.greenAccent.shade200
                                    : Colors.white54,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Info toggle — gold circle matching audio screen
                  GestureDetector(
                    onTap: () => setState(() => _showInfo = !_showInfo),
                    child: Container(
                      width : 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _showInfo
                            ? _gold
                            : _gold.withOpacity(0.25),
                      ),
                      child: Icon(Icons.info_outline,
                          color: _showInfo ? Colors.white : _gold,
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info overlay panel (Image 2) ────────────────────────────
            if (_showInfo)
              Positioned(
                top  : MediaQuery.of(context).padding.top + 66,
                left : 12, right: 12,
                child: _InfoOverlay(
                  displayName: widget.userName,
                  userId     : widget.userId,
                  gender     : widget.gender,
                  dob        : widget.dob,
                  pob        : widget.pob,
                ),
              ),

            // ── Bottom controls (frosted pill, matches images) ───────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child : _BottomControls(
                provider: provider,
                onEnd   : _onEndButtonPressed,
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
          children: [
            CircleAvatar(
              radius         : 52,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: widget.userAvatar.isNotEmpty
                  ? NetworkImage(widget.userAvatar) : null,
              child: widget.userAvatar.isEmpty
                  ? const Icon(Icons.person, size: 52, color: Colors.white54)
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
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }
    return provider.remoteVideoOn
        ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine        : provider.engine!,
              canvas           : VideoCanvas(uid: provider.remoteUid!),
              connection       : RtcConnection(channelId: widget.channelId),
              useFlutterTexture: true,
            ),
          )
        : Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off,
                      color: Colors.white54, size: 40),
                  const SizedBox(height: 8),
                  Text(widget.userName,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
  }

  Widget _localPipWidget(VideoCallProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color       : Colors.black,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: Colors.white38, width: 1.5),
        ),
        child: provider.engine == null
            ? const Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white54)))
            : provider.isVideoOn
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine        : provider.engine!,
                      canvas           : const VideoCanvas(uid: 0),
                      useFlutterTexture: true,
                    ),
                  )
                : Container(
                    color: Colors.grey.shade900,
                    child: const Center(child: Icon(Icons.videocam_off,
                        color: Colors.white54, size: 28)),
                  ),
      ),
    );
  }
}

// ── Info overlay panel ────────────────────────────────────────────────────────
class _InfoOverlay extends StatelessWidget {
  final String displayName;
  final String userId;
  final String gender;
  final String dob;
  final String pob;

  static const _red = Color(0xFFD41000);

  const _InfoOverlay({
    required this.displayName,
    required this.userId,
    required this.gender,
    required this.dob,
    required this.pob,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color       : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow   : [
          BoxShadow(
            color     : Colors.black.withOpacity(0.20),
            blurRadius: 12,
            offset    : const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Name',
              value: '$displayName${userId.isNotEmpty ? " ($userId)" : ""}'),
          _InfoRow(label: 'Gender',
              value: gender.isNotEmpty ? gender : '—'),
          _InfoRow(label: 'DOB',
              value: dob.isNotEmpty ? dob : '—'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _InfoRow(
                  label: 'POB',
                  value: pob.isNotEmpty ? pob : '—')),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: pob));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content : Text('Copied'),
                        duration: Duration(seconds: 1)));
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Icon(Icons.copy_rounded,
                      size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Suggest -Remedy',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Open Kundli',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.note_alt_outlined, size: 14, color: _red),
              SizedBox(width: 5),
              Text('Add / View Notes',
                  style: TextStyle(
                      color     : _red,
                      fontSize  : 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  static const _red = Color(0xFFD41000);
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2C)),
        children: [
          TextSpan(text: '$label : ',
              style: const TextStyle(
                  color: _red, fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

// ── Bottom controls (frosted pill — matches image) ────────────────────────────
class _BottomControls extends StatelessWidget {
  final VideoCallProvider provider;
  final VoidCallback      onEnd;

  const _BottomControls({required this.provider, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top   : 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left  : 12, right: 12,
      ),
      decoration: BoxDecoration(
        color       : Colors.black.withOpacity(0.72),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CtrlBtn(
            icon  : provider.speakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label : 'Speaker',
            active: provider.speakerOn,
            onTap : provider.toggleSpeaker,
          ),
          _CtrlBtn(
            icon  : provider.muted
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            label : 'Mute',
            active: !provider.muted,
            onTap : provider.toggleMute,
          ),
          _CtrlBtn(
            icon  : provider.isVideoOn
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label : 'Video',
            active: provider.isVideoOn,
            onTap : provider.toggleVideo,
          ),
          // Red end call — center, slightly larger
          GestureDetector(
            onTap: onEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width     : 58, height: 58,
                  decoration: BoxDecoration(
                    shape    : BoxShape.circle,
                    color    : Colors.red.shade600,
                    boxShadow: [
                      BoxShadow(
                        color     : Colors.red.withOpacity(0.40),
                        blurRadius: 12,
                        offset    : const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 5),
                const Text('End',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         active;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width : 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(active ? 0.18 : 0.08),
            border: Border.all(
                color: active ? Colors.white38 : Colors.transparent),
          ),
          child: Icon(icon,
              color: active ? Colors.white : Colors.white38,
              size: 22),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                color   : active ? Colors.white70 : Colors.white30,
                fontSize: 11)),
      ],
    ),
  );
}

// ── Rating sheet — theme-aware ─────────────────────────────────────────────────
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
  int  _stars      = 0;
  bool _submitting = false;
  final _reviewCtrl = TextEditingController();
  static const _labels = [
    '', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'
  ];

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
    final c  = context.colors;
    final bi = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 24, bottom: 24 + bi),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color      : c.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Call ended badge
        Container(
          padding   : const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color       : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border      : Border.all(color: Colors.red.shade200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.videocam_off, size: 14, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text('Video Call Ended',
                style: TextStyle(
                    color     : Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize  : 12)),
          ]),
        ),
        const SizedBox(height: 20),

        CircleAvatar(
          radius         : 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: widget.userAvatar.isNotEmpty
              ? NetworkImage(widget.userAvatar) : null,
          child: widget.userAvatar.isEmpty
              ? const Icon(Icons.person, size: 40, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 10),
        Text(widget.userName,
            style: TextStyle(
                fontSize  : 18,
                fontWeight: FontWeight.bold,
                color     : c.text)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text('Video · ${widget.duration}',
              style: TextStyle(color: c.subText, fontSize: 13)),
        ]),

        const SizedBox(height: 20),
        Text('Rate Your Experience',
            style: TextStyle(
                fontSize  : 17,
                fontWeight: FontWeight.bold,
                color     : c.text)),
        const SizedBox(height: 4),
        Text('How was your video call with ${widget.userName}?',
            style: TextStyle(fontSize: 13, color: c.subText)),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final s = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _stars = s),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
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
            child: Text(_labels[_stars],
                style: const TextStyle(
                    color     : Color(0xFFEBC351),
                    fontWeight: FontWeight.w600,
                    fontSize  : 14)),
          ),

        const SizedBox(height: 16),

        TextField(
          controller: _reviewCtrl,
          maxLines  : 3,
          maxLength : 300,
          style     : TextStyle(color: c.text),
          decoration: InputDecoration(
            hintText     : 'Write your review (optional)…',
            hintStyle    : TextStyle(color: c.subText, fontSize: 13),
            filled       : true,
            fillColor    : c.toggleBg,
            border       : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide  : BorderSide(color: c.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide  : BorderSide(color: c.border)),
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
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side   : BorderSide(color: c.border),
                shape  : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting ? null : widget.onDone,
              child: Text('Skip',
                  style: TextStyle(color: c.subText)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding        : const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFFEBC351),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20,
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
      ]),
    );
  }
}