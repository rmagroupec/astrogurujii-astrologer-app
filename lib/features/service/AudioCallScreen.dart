// lib/features/service/AudioCallScreen.dart
//
// Changes:
// 1. ✅ FIXED end call — removed double-guard, properly calls provider.end()
// 2. ✅ Added Hold button in bottom bar
// 3. ✅ Back press → minimizes call instead of popping
// 4. ✅ Call end shows a bottom sheet with "Write a Review" button (not auto-dialog)
// 5. ✅ init() passes callerName/callerImage to provider for overlay

import 'package:astrologer_app/core/widgets/RingingWave.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final String callerName;
  final String callerImage;

  final String? patientName;
  final String? patientId;
  final String? patientGender;
  final String? patientDOB;
  final String? patientPOB;
  final String? remainingTime;
  final VoidCallback? onSuggestRemedy;
  final VoidCallback? onOpenKundli;
  final VoidCallback? onAddViewNotes;

  const AudioCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    this.callerName  = 'User',
    this.callerImage = '',
    this.patientName,
    this.patientId,
    this.patientGender,
    this.patientDOB,
    this.patientPOB,
    this.remainingTime,
    this.onSuggestRemedy,
    this.onOpenKundli,
    this.onAddViewNotes,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with SingleTickerProviderStateMixin {
  bool _started     = false;
  bool _showInfo    = false;
  bool _reviewShown = false;   // ✅ guard for review sheet

  late AnimationController _waveController;
  late Animation<double>   _waveAnimation;

  static const _bgColor = Color(0xFFF5EBD8);
  static const _cardBg  = Color(0xFFEDE3D5);
  static const _gold    = Color(0xFFE6A817);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve : Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    context.read<AudioCallProvider>().init(
      channelId           : widget.channelId,
      token               : widget.token,
      name                : widget.callerName,
      image               : widget.callerImage,
      onRemoteDisconnected: _handleRemoteDisconnected,
    );
  }

  // ✅ Called when remote user disconnects — show review sheet
  void _handleRemoteDisconnected() {
    if (!mounted || _reviewShown) return;
    _endCallAndShowReview();
  }

  // ✅ FIXED: end call → stop engine → show review bottom sheet
  Future<void> _endCallAndShowReview() async {
    if (_reviewShown) return;
    _reviewShown = true;
    _waveController.stop();

    final provider = context.read<AudioCallProvider>();
    await provider.end();           // ✅ Always call end() — provider guards double-end internally

    if (!mounted) return;
    _showReviewSheet();
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context            : context,
      isDismissible      : false,
      enableDrag         : false,
      isScrollControlled : true,
      backgroundColor    : Colors.transparent,
      builder            : (_) => _ReviewSheet(
        callerName : widget.callerName,
        callerImage: widget.callerImage,
        onDone     : (rating) {
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).pop(); // close call screen
        },
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AudioCallProvider>();
    final isConnected = provider.remoteJoined;

    if (isConnected && _waveController.isAnimating) {
      _waveController.stop();
    } else if (!isConnected && !_reviewShown && !_waveController.isAnimating) {
      _waveController.repeat();
    }

    // ✅ Back press → minimize (not pop)
    return WillPopScope(
      onWillPop: () async {
        provider.minimize();
        Navigator.of(context).pop(); // pop the screen but call continues
        return false;
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _TopBar(
                    callerName: widget.callerName,
                    duration  : isConnected ? provider.duration : '00:00',
                    onBack    : () {
                      provider.minimize();
                      Navigator.of(context).pop();
                    },
                    onInfo    : () => setState(() => _showInfo = !_showInfo),
                    goldColor : _gold,
                  ),

                  const SizedBox(height: 32),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isConnected)
                        RingingWave(animation: _waveAnimation),
                      _AvatarRing(
                        imageUrl : widget.callerImage,
                        goldColor: _gold,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (!_showInfo && widget.remainingTime != null)
                    Text(
                      'Remaining time : ${widget.remainingTime}',
                      style: const TextStyle(
                        color     : Color(0xFF1A1A1A),
                        fontSize  : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  // ✅ Hold indicator banner
                  if (provider.onHold)
                    Container(
                      margin : const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color       : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border      : Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pause_circle, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text('Call on Hold',
                              style: TextStyle(
                                  color     : Colors.orange,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                  if (_showInfo) ...[
                    const SizedBox(height: 16),
                    _InfoPanel(
                      remainingTime  : widget.remainingTime  ?? '00:00',
                      patientName    : widget.patientName    ?? '',
                      patientId      : widget.patientId      ?? '',
                      patientGender  : widget.patientGender  ?? '',
                      patientDOB     : widget.patientDOB     ?? '',
                      patientPOB     : widget.patientPOB     ?? '',
                      cardBg         : _cardBg,
                      onSuggestRemedy: widget.onSuggestRemedy,
                      onOpenKundli   : widget.onOpenKundli,
                      onAddViewNotes : widget.onAddViewNotes,
                    ),
                  ],

                  const Spacer(),
                ],
              ),

              // ✅ Bottom bar with Speaker | End | Mute | Hold
              Positioned(
                left  : 0,
                right : 0,
                bottom: 0,
                child : _BottomBar(
                  provider: provider,
                  onEnd   : _endCallAndShowReview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String callerName;
  final String duration;
  final VoidCallback onBack;
  final VoidCallback onInfo;
  final Color goldColor;

  const _TopBar({
    required this.callerName,
    required this.duration,
    required this.onBack,
    required this.onInfo,
    required this.goldColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.keyboard_arrow_down,
                size: 28, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(callerName,
                    style: const TextStyle(
                        color     : Color(0xFF1A1A1A),
                        fontSize  : 16,
                        fontWeight: FontWeight.w700)),
                Text(duration,
                    style: TextStyle(
                        color   : goldColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onInfo,
            child: Container(
              padding   : const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color       : const Color(0xFFEDE3D5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline,
                  size: 20, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR RING
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarRing extends StatelessWidget {
  final String imageUrl;
  final Color  goldColor;
  const _AvatarRing({required this.imageUrl, required this.goldColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width : 130,
      height: 130,
      decoration: BoxDecoration(
        shape : BoxShape.circle,
        border: Border.all(color: goldColor, width: 3),
        boxShadow: [
          BoxShadow(
            color     : goldColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(imageUrl,
                fit         : BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFFE6A817).withOpacity(0.2),
    child: const Icon(Icons.person, size: 60, color: Color(0xFFE6A817)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR  (Speaker | End | Mute | Hold)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final AudioCallProvider provider;
  final VoidCallback      onEnd;
  const _BottomBar({required this.provider, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color      : Color(0xFFE8DDD0),
        borderRadius: BorderRadius.only(
          topLeft : Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 28, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Speaker | End | Mute
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _barBtn(
                icon  : provider.speakerOn ? Icons.volume_up : Icons.volume_off,
                label : 'Speaker',
                active: provider.speakerOn,
                onTap : provider.toggleSpeaker,
              ),

              // ✅ End call button — prominent red circle
              GestureDetector(
                onTap: onEnd,
                child: Column(
                  children: [
                    Container(
                      width: 62, height: 62,
                      decoration: BoxDecoration(
                        shape    : BoxShape.circle,
                        color    : const Color(0xFFE53935),
                        boxShadow: [
                          BoxShadow(
                              color    : const Color(0xFFE53935).withOpacity(0.35),
                              blurRadius: 16,
                              offset   : const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.call_end,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 4),
                    const Text('End',
                        style: TextStyle(
                            fontSize: 11,
                            color   : Color(0xFF555555))),
                  ],
                ),
              ),

              _barBtn(
                icon  : provider.muted ? Icons.mic_off : Icons.mic,
                label : 'Mute',
                active: provider.muted,
                onTap : provider.toggleMute,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Hold button (centered)
          // ✅ NEW: Hold button
          GestureDetector(
            onTap: provider.toggleHold,
            child: Container(
              width  : 56,
              height : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: provider.onHold
                    ? Colors.orange.withOpacity(0.25)
                    : const Color(0xFFCFC4B4),
                border: provider.onHold
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    provider.onHold ? Icons.play_arrow : Icons.pause,
                    color: provider.onHold ? Colors.orange : const Color(0xFF555555),
                    size : 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.onHold ? 'Resume' : 'Hold',
            style: TextStyle(
                fontSize: 11,
                color   : provider.onHold ? Colors.orange : const Color(0xFF555555)),
          ),
        ],
      ),
    );
  }

  Widget _barBtn({
    required IconData     icon,
    required String       label,
    required bool         active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? const Color(0xFF1A1A1A).withOpacity(0.15)
                  : const Color(0xFFCFC4B4),
            ),
            child: Icon(icon,
                color: active
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF777777),
                size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF555555))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _InfoPanel extends StatelessWidget {
  final String remainingTime;
  final String patientName;
  final String patientId;
  final String patientGender;
  final String patientDOB;
  final String patientPOB;
  final Color  cardBg;
  final VoidCallback? onSuggestRemedy;
  final VoidCallback? onOpenKundli;
  final VoidCallback? onAddViewNotes;

  const _InfoPanel({
    required this.remainingTime,
    required this.patientName,
    required this.patientId,
    required this.patientGender,
    required this.patientDOB,
    required this.patientPOB,
    required this.cardBg,
    this.onSuggestRemedy,
    this.onOpenKundli,
    this.onAddViewNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color       : cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Name',   patientName),
            _row('ID',     patientId),
            _row('Gender', patientGender),
            _row('DOB',    patientDOB),
            _row('POB',    patientPOB),
            _row('Time Left', remainingTime),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onSuggestRemedy != null)
                  Expanded(child: _actionBtn('Remedy',  Colors.teal,   onSuggestRemedy!)),
                if (onOpenKundli != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _actionBtn('Kundli',  Colors.indigo, onOpenKundli!)),
                ],
                if (onAddViewNotes != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _actionBtn('Notes',   Colors.brown,  onAddViewNotes!)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize  : 13,
                color     : Color(0xFF555555))),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
        ),
      ],
    ),
  );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding   : const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child    : Text(label,
              style: const TextStyle(
                  color     : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize  : 13)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ NEW: REVIEW BOTTOM SHEET  (replaces old _RatingDialog)
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewSheet extends StatefulWidget {
  final String callerName;
  final String callerImage;
  final void Function(int rating) onDone;

  const _ReviewSheet({
    required this.callerName,
    required this.callerImage,
    required this.onDone,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top   : 24,
        left  : 24,
        right : 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width : 40,
            height: 4,
            decoration: BoxDecoration(
              color       : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Call ended badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color       : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border      : Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_end, size: 14, color: Colors.red.shade400),
                const SizedBox(width: 6),
                Text('Call Ended',
                    style: TextStyle(
                        color     : Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                        fontSize  : 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Avatar + name
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE6A817).withOpacity(0.15),
            backgroundImage: widget.callerImage.isNotEmpty
                ? NetworkImage(widget.callerImage)
                : null,
            child: widget.callerImage.isEmpty
                ? const Icon(Icons.person, size: 40, color: Color(0xFFE6A817))
                : null,
          ),
          const SizedBox(height: 12),
          Text(widget.callerName,
              style: const TextStyle(
                  fontSize  : 18,
                  fontWeight: FontWeight.bold,
                  color     : Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          const Text('How was your experience?',
              style: TextStyle(color: Colors.grey, fontSize: 14)),

          const SizedBox(height: 20),

          // ✅ Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFE6A817),
                    size : 36,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Comment field
          TextField(
            controller : _commentCtrl,
            maxLines   : 3,
            decoration : InputDecoration(
              hintText    : 'Leave a comment (optional)',
              hintStyle   : const TextStyle(color: Colors.grey),
              filled      : true,
              fillColor   : const Color(0xFFF5F5F5),
              border      : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide  : BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Write a Review / Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onDone(_rating),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE6A817),
                foregroundColor: Colors.white,
                padding        : const EdgeInsets.symmetric(vertical: 16),
                shape          : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Submit Review',
                  style: TextStyle(
                      fontSize  : 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 10),

          // Skip option
          TextButton(
            onPressed: () => widget.onDone(0),
            child: const Text('Skip',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}