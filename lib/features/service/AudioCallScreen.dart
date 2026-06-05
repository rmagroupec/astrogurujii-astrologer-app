// lib/features/service/AudioCallScreen.dart
//
// Fixes from doc 6 (current code):
// 1. init() now passes onRemoteDisconnected: _showRatingDialog callback
// 2. Removed _wasConnected + addPostFrameCallback from build() — that race
//    condition caused double-dialog. Callback from provider is the clean path.
// 3. _endCall() guard prevents double-show if user taps end while callback fires
// UI is 100% identical to doc 6.

import 'package:astrologer_app/core/widgets/RingingWave.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:flutter/material.dart';
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
  bool _ratingShown = false;   // ✅ single guard — no _wasConnected needed

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

    // ✅ FIX 1: wire callback — provider calls this when remote disconnects
    context.read<AudioCallProvider>().init(
      channelId           : widget.channelId,
      token               : widget.token,
      onRemoteDisconnected: _showRatingDialog,
    );
  }

  Future<void> _endCall() async {
    if (_ratingShown) return;                  // ✅ FIX 3: prevent double dialog
    final provider = context.read<AudioCallProvider>();
    await provider.end();
    if (mounted) _showRatingDialog();
  }

  void _showRatingDialog() {
    if (!mounted || _ratingShown) return;
    _ratingShown = true;
    _waveController.stop();

    showDialog(
      context           : context,
      barrierDismissible: false,
      builder           : (_) => _RatingDialog(
        callerName : widget.callerName,
        callerImage: widget.callerImage,
        onSubmit   : (rating) {
          Navigator.of(context).pop(); // close dialog
          if (mounted) Navigator.of(context).pop(); // close call screen
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

    // ✅ FIX 2: removed _wasConnected + addPostFrameCallback — no more race condition
    // Wave animation control only
    if (isConnected && _waveController.isAnimating) {
      _waveController.stop();
    } else if (!isConnected && !_ratingShown && !_waveController.isAnimating) {
      _waveController.repeat();
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  callerName: widget.callerName,
                  duration  : isConnected ? provider.duration : '00:00',
                  onBack    : () => Navigator.pop(context),
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

                if (_showInfo) ...[
                  const SizedBox(height: 16),
                  _InfoPanel(
                    remainingTime: widget.remainingTime  ?? '00:00',
                    patientName  : widget.patientName    ?? '',
                    patientId    : widget.patientId      ?? '',
                    patientGender: widget.patientGender  ?? '',
                    patientDOB   : widget.patientDOB     ?? '',
                    patientPOB   : widget.patientPOB     ?? '',
                    cardBg       : _cardBg,
                    onSuggestRemedy: widget.onSuggestRemedy,
                    onOpenKundli   : widget.onOpenKundli,
                    onAddViewNotes : widget.onAddViewNotes,
                  ),
                ],

                const Spacer(),
              ],
            ),

            Positioned(
              left  : 0,
              right : 0,
              bottom: 0,
              child : _BottomBar(
                provider: provider,
                onEnd   : _endCall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets — identical to doc 6 ─────────────────────────────────────────

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
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
              ),
              child: const Icon(Icons.chevron_left,
                  color: Color(0xFF1A1A1A), size: 22),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(callerName,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(duration,
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onInfo,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: goldColor),
              child: const Icon(Icons.info_outline,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final String imageUrl;
  final Color  goldColor;
  const _AvatarRing({required this.imageUrl, required this.goldColor});

  @override
  Widget build(BuildContext context) {
    final size =
        (MediaQuery.of(context).size.width * 0.42).clamp(120.0, 180.0);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape    : BoxShape.circle,
        border   : Border.all(color: goldColor, width: 3.5),
        boxShadow: [
          BoxShadow(
              color      : goldColor.withOpacity(0.25),
              blurRadius : 20,
              spreadRadius: 4),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFFE8D5B5),
        child: const Icon(Icons.person, size: 70, color: Colors.white),
      );
}

class _InfoPanel extends StatelessWidget {
  final String remainingTime, patientName, patientId,
      patientGender, patientDOB, patientPOB;
  final Color           cardBg;
  final VoidCallback?   onSuggestRemedy, onOpenKundli, onAddViewNotes;

  const _InfoPanel({
    required this.remainingTime, required this.patientName,
    required this.patientId, required this.patientGender,
    required this.patientDOB, required this.patientPOB,
    required this.cardBg,
    this.onSuggestRemedy, this.onOpenKundli, this.onAddViewNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color     : Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset    : const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Name', '$patientName ($patientId)'),
                  const SizedBox(height: 8),
                  _detailRow('Gender', patientGender),
                  const SizedBox(height: 8),
                  _detailRow('DOB', patientDOB),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('POB', patientPOB),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(Icons.copy,
                            size: 20, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                        label: 'Suggest -Remedy',
                        color: const Color(0xFFE53935),
                        onTap: onSuggestRemedy)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionBtn(
                        label: 'Open Kundli',
                        color: const Color(0xFF4CAF50),
                        onTap: onOpenKundli)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAddViewNotes,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: const [
                    Text('Add / View Notes',
                        style: TextStyle(
                            color     : Color(0xFF1A1A1A),
                            fontSize  : 14,
                            fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.edit_note,
                        size: 22, color: Color(0xFF6B6B6B)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => RichText(
        text: TextSpan(children: [
          TextSpan(
              text : '$label : ',
              style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          TextSpan(
              text : value,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
        ]),
      );

  Widget _actionBtn({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) =>
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
      padding: const EdgeInsets.only(
          top: 20, bottom: 28, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _barBtn(
            icon  : provider.speakerOn
                ? Icons.volume_up
                : Icons.volume_off,
            active: provider.speakerOn,
            onTap : provider.toggleSpeaker,
          ),
          GestureDetector(
            onTap: onEnd,
            child: Container(
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
          ),
          _barBtn(
            icon  : provider.muted ? Icons.mic_off : Icons.mic,
            active: provider.muted,
            onTap : provider.toggleMute,
          ),
        ],
      ),
    );
  }

  Widget _barBtn({
    required IconData     icon,
    required bool         active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                : const Color(0xFF5A5A5A),
            size: 22),
      ),
    );
  }
}

// ── Rating Dialog — identical to doc 6 ───────────────────────────────────────
class _RatingDialog extends StatefulWidget {
  final String callerName;
  final String callerImage;
  final void Function(int rating) onSubmit;

  const _RatingDialog({
    required this.callerName,
    required this.callerImage,
    required this.onSubmit,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape          : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child  : Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape : BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFE6A817), width: 2.5),
              ),
              child: ClipOval(
                child: widget.callerImage.isNotEmpty
                    ? Image.network(widget.callerImage,
                        fit         : BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback())
                    : _fallback(),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Rate your experience',
                style: TextStyle(
                    fontSize  : 17,
                    fontWeight: FontWeight.bold,
                    color     : Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text('How was your call with ${widget.callerName}?',
                textAlign: TextAlign.center,
                style    : const TextStyle(
                    fontSize: 13, color: Color(0xFF6B6B6B))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children         : List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selected = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child  : Icon(
                      _selected >= star
                          ? Icons.star
                          : Icons.star_border,
                      size : 36,
                      color: _selected >= star
                          ? const Color(0xFFE6A817)
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => widget.onSubmit(_selected),
                child: Container(
                  padding   : const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient    : const LinearGradient(colors: [
                      Color(0xFFE6A817),
                      Color(0xFFFF9800),
                    ]),
                  ),
                  alignment: Alignment.center,
                  child    : const Text('Submit',
                      style: TextStyle(
                          color     : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize  : 15)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => widget.onSubmit(0),
              child: const Text('Skip',
                  style: TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFFE8D5B5),
        child: const Icon(Icons.person, size: 40, color: Colors.white),
      );
}