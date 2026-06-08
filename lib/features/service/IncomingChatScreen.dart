import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:flutter/material.dart';

class IncomingChatRequestScreen extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final String messagePreview;

  const IncomingChatRequestScreen({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.messagePreview,
  });

  @override
  State<IncomingChatRequestScreen> createState() =>
      _IncomingChatRequestScreenState();
}

class _IncomingChatRequestScreenState
    extends State<IncomingChatRequestScreen> with TickerProviderStateMixin {
  bool _isHandled = false;

  late AnimationController _rippleController;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _ring1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _ring2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    LocalNotificationService.playRingtone();
  }

bool _ringStopped = false;

void _stopRingOnce() {
  if (_ringStopped) return;
  _ringStopped = true;
  LocalNotificationService.stopRingtone();
}
  @override
  void dispose() {
     _stopRingOnce();
    _rippleController.dispose();
    super.dispose();
  }


  void _handleAccept() {
    if (_isHandled) return;
    setState(() => _isHandled = true);
    Navigator.of(context).pop('accept');
  }

  void _handleDecline() {
    if (_isHandled) return;
    setState(() => _isHandled = true);
    Navigator.of(context).pop('decline');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Full-screen blurred background photo ──────────────────
            Image.network(
              widget.userAvatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800),
            ),

            // ── 2. Dark overlay ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000), // light at top
                    Color(0x55000000),
                    Color(0xAA000000),
                    Color(0xDD000000), // heavy at bottom
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),

            // ── 3. Top bar (back + more) ─────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopBarButton(
                      icon: Icons.chevron_left,
                      onTap: () => Navigator.of(context).pop('decline'),
                    ),
                    _TopBarButton(
                      icon: Icons.more_horiz,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── 4. Centre: ripple + avatar + name + subtitle ─────────────
            Positioned(
              top: 0,
              bottom: 200, // push centre content upward so buttons sit low
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ripple rings + gold-bordered avatar
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (_, __) => Stack(
                              alignment: Alignment.center,
                              children: [
                                _RippleRing(
                                    progress: _ring1.value, maxRadius: 112),
                                _RippleRing(
                                    progress: _ring2.value, maxRadius: 103),
                                _RippleRing(
                                    progress: _ring3.value, maxRadius: 94),
                              ],
                            ),
                          ),
                          // Gold ring
                          Container(
                            width: 138,
                            height: 138,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFCC00),
                                width: 3.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                widget.userAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade700,
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 60),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Incoming Chat Request',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 5. Bottom: Accept / Decline ──────────────────────────────
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Accept
                    _CallButton(
                      color: const Color(0xFF4CAF50),
                      icon: Icons.call,
                      label: 'Accept',
                      onTap: _isHandled ? null : _handleAccept,
                    ),
                    // Decline
                    _CallButton(
                      color: const Color(0xFFE53935),
                      icon: Icons.call_end,
                      label: 'Decline',
                      onTap: _isHandled ? null : _handleDecline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ripple ring ───────────────────────────────────────────────────────────────

class _RippleRing extends StatelessWidget {
  final double progress;
  final double maxRadius;

  const _RippleRing({required this.progress, required this.maxRadius});

  @override
  Widget build(BuildContext context) {
    final double size = maxRadius * 2 * progress;
    final double opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.35;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

// ── Top bar circular button ───────────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.22),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

// ── Accept / Decline button ───────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _CallButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color : color.withOpacity(0.4),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.55),
                        blurRadius: 24,
                        spreadRadius: 3,
                      ),
                    ]
                  : [],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}