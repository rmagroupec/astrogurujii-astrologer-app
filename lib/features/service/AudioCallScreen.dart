// lib/features/service/AudioCallScreen.dart
// Mirrors VideoCallScreen pattern exactly for remote disconnect handling

import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final String callerName;
  final String callerImage;

  const AudioCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    this.callerName  = 'User',
    this.callerImage = '',
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with SingleTickerProviderStateMixin {

  bool _initDone = false;
  bool _endShown = false;

  late AnimationController _waveCtrl;

  static const _bgColor = Color(0xFFF5EBD8);
  static const _cardBg  = Color(0xFFEDE3D5);
  static const _gold    = Color(0xFFE6A817);

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initDone) return;
    _initDone = true;

    // Mirror VideoCallScreen — pass onEnded callback
    context.read<AudioCallProvider>().init(
      channelId : widget.channelId,
      token     : widget.token,
      name      : widget.callerName,
      image     : widget.callerImage,
      onEnded   : (reason) {
        debugPrint('📞 onEnded fired: $reason');
        _doEnd();
      },
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  // ── End button ────────────────────────────────────────────────────────────
  void _onEndPressed() {
    if (_endShown) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape  : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title  : const Text('End Call',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end this call?'),
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
              _doEnd();
            },
            child: const Text('End',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Core end — mirrors VideoCallScreen._showEndFlow ───────────────────────
  Future<void> _doEnd() async {
    if (_endShown) return;
    _endShown = true;

    if (_waveCtrl.isAnimating) _waveCtrl.stop();

    final provider = context.read<AudioCallProvider>();
    await provider.end();

    if (!mounted) return;

    // Small delay so engine teardown settles — same as VideoCallScreen
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _showRatingSheet();
  }

  // ── Rating sheet ─────────────────────────────────────────────────────────
  void _showRatingSheet() {
    showModalBottomSheet(
      context           : context,
      isDismissible     : false,
      enableDrag        : false,
      isScrollControlled: true,
      useRootNavigator  : false,   // keep on same navigator as call screen
      backgroundColor   : Colors.transparent,
      builder           : (_) => _RatingSheet(
        callerName : widget.callerName,
        callerImage: widget.callerImage,
        onDone: (_) {
          // Defer navigation to AFTER the current gesture/frame completes.
          // popUntil inside an onTap causes _debugLocked because the navigator
          // is locked during gesture dispatch. addPostFrameCallback guarantees
          // we're outside the gesture recognizer before touching the navigator.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationManager().navigatorKey.currentState?.popUntil(
              (route) => route.isFirst,
            );
          });
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AudioCallProvider>();
    final isConnected = provider.remoteJoined;

    // Mirror VideoCallScreen — watch isEnded in build() as a safety net
    // In case onEnded callback fires while widget is between frames
    if (provider.isEnded && !_endShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _doEnd());
    }

    if (isConnected && _waveCtrl.isAnimating) {
      _waveCtrl.stop();
    } else if (!isConnected && !_endShown && !_waveCtrl.isAnimating) {
      _waveCtrl.repeat();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (_) {
        provider.minimize();
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(children: [

            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(children: [
                CircleAvatar(
                  radius         : 24,
                  backgroundColor: _gold.withOpacity(0.2),
                  backgroundImage: widget.callerImage.isNotEmpty
                      ? NetworkImage(widget.callerImage) : null,
                  child: widget.callerImage.isEmpty
                      ? const Icon(Icons.person, color: _gold, size: 26)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.callerName,
                        style: const TextStyle(
                            fontSize  : 18,
                            fontWeight: FontWeight.w700,
                            color     : Color(0xFF2C2C2C))),
                    Text(
                      isConnected ? provider.duration : 'Connecting…',
                      style: TextStyle(
                          fontSize: 13,
                          color   : isConnected
                              ? Colors.green.shade700
                              : Colors.grey),
                    ),
                  ],
                )),
                IconButton(
                  onPressed: () {
                    provider.minimize();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF555555), size: 28),
                ),
              ]),
            ),

            // ── Wave / connected ─────────────────────────────────────────
            Expanded(
              child: Center(
                child: isConnected
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius         : 64,
                            backgroundColor: _gold.withOpacity(0.15),
                            backgroundImage: widget.callerImage.isNotEmpty
                                ? NetworkImage(widget.callerImage) : null,
                            child: widget.callerImage.isEmpty
                                ? const Icon(Icons.person,
                                    color: _gold, size: 56)
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(widget.callerName,
                              style: const TextStyle(
                                  fontSize  : 22,
                                  fontWeight: FontWeight.w700,
                                  color     : Color(0xFF2C2C2C))),
                          const SizedBox(height: 6),
                          Text(provider.duration,
                              style: TextStyle(
                                  fontSize  : 16,
                                  color     : Colors.green.shade700,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    : AnimatedBuilder(
                        animation: _waveCtrl,
                        builder : (_, __) => _WaveRipple(
                          progress: _waveCtrl.value,
                          name    : widget.callerName,
                          imageUrl: widget.callerImage,
                        ),
                      ),
              ),
            ),

            // ── Controls ─────────────────────────────────────────────────
            Container(
              margin    : const EdgeInsets.all(20),
              padding   : const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color       : _cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CtrlBtn(
                      icon  : provider.speakerOn
                          ? Icons.volume_up : Icons.volume_off,
                      label : 'Speaker',
                      active: provider.speakerOn,
                      onTap : provider.toggleSpeaker,
                    ),
                    _EndBtn(onTap: _onEndPressed),
                    _CtrlBtn(
                      icon  : provider.muted
                          ? Icons.mic_off : Icons.mic,
                      label : 'Mute',
                      active: provider.muted,
                      onTap : provider.toggleMute,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CtrlBtn(
                  icon  : provider.onHold
                      ? Icons.play_arrow : Icons.pause,
                  label : provider.onHold ? 'Resume' : 'Hold',
                  active: provider.onHold,
                  color : provider.onHold ? Colors.orange : null,
                  onTap : provider.toggleHold,
                ),
              ]),
            ),

          ]),
        ),
      ),
    );
  }
}

// =============================================================================
class _WaveRipple extends StatelessWidget {
  final double progress;
  final String name;
  final String imageUrl;
  const _WaveRipple({
      required this.progress,
      required this.name,
      required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260, height: 260,
      child: Stack(alignment: Alignment.center, children: [
        _ring(progress,               130),
        _ring((progress + 0.33) % 1,  115),
        _ring((progress + 0.66) % 1,  100),
        CircleAvatar(
          radius         : 56,
          backgroundColor: const Color(0xFFE6A817).withOpacity(0.15),
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person,
                  color: Color(0xFFE6A817), size: 52)
              : null,
        ),
      ]),
    );
  }

  Widget _ring(double p, double maxR) => Opacity(
    opacity: (1 - p).clamp(0.0, 1.0),
    child  : Container(
      width : maxR * 2 * p + 112,
      height: maxR * 2 * p + 112,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE6A817).withOpacity(0.08)),
    ),
  );
}

// =============================================================================
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final Color?   color;
  final VoidCallback onTap;
  const _CtrlBtn({
      required this.icon, required this.label,
      required this.onTap, this.active = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active
        ? const Color(0xFFE6A817)
        : const Color(0xFF888888));
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width : 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? c.withOpacity(0.15)
                : Colors.white.withOpacity(0.5),
          ),
          child: Icon(icon, color: c, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF555555))),
      ]),
    );
  }
}

// =============================================================================
class _EndBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _EndBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(
        width : 64, height: 64,
        decoration: BoxDecoration(
          shape    : BoxShape.circle,
          color    : const Color(0xFFE53935),
          boxShadow: [BoxShadow(
            color     : const Color(0xFFE53935).withOpacity(0.4),
            blurRadius: 16,
            offset    : const Offset(0, 4))],
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 30),
      ),
      const SizedBox(height: 4),
      const Text('End',
          style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
    ]),
  );
}

// =============================================================================
class _RatingSheet extends StatefulWidget {
  final String callerName;
  final String callerImage;
  final void Function(int rating) onDone;
  const _RatingSheet({
      required this.callerName,
      required this.callerImage,
      required this.onDone});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top   : 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color       : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.call_end, size: 14, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text('Call Ended',
                style: TextStyle(
                    color     : Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize  : 12)),
          ]),
        ),
        const SizedBox(height: 20),

        CircleAvatar(
          radius         : 40,
          backgroundColor: const Color(0xFFE6A817).withOpacity(0.15),
          backgroundImage: widget.callerImage.isNotEmpty
              ? NetworkImage(widget.callerImage) : null,
          child: widget.callerImage.isEmpty
              ? const Icon(Icons.person,
                  color: Color(0xFFE6A817), size: 36)
              : null,
        ),
        const SizedBox(height: 12),
        Text(widget.callerName,
            style: const TextStyle(
                fontSize  : 18,
                fontWeight: FontWeight.w700,
                color     : Color(0xFF2C2C2C))),
        const SizedBox(height: 4),
        const Text('How was your call?',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFE6A817),
                  size : 38,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _ctrl,
          maxLines  : 3,
          decoration: InputDecoration(
            hintText : 'Leave a comment (optional)',
            hintStyle: const TextStyle(color: Colors.grey),
            filled   : true,
            fillColor: const Color(0xFFF5F5F5),
            border   : OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide  : BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onDone(_rating),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE6A817),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape  : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Submit Review',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 10),

        TextButton(
          onPressed: () => widget.onDone(0),
          child: const Text('Skip',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      ]),
    );
  }
}