// lib/widgets/active_call_floating_card.dart
//
// A draggable floating card that shows an active call/chat session.
// Supports chat, audio, and video call types with distinct icons/colors.
// Dark background with white text — matches the astrologer app's dark+red theme.
//
// Usage in MainNavScreen:
//
//   floatingActionButton: ActiveCallFloatingCard(
//     data2     : _activeCall,
//     onTap     : () { /* navigate back to active screen */ },
//     onDismiss : () { /* end call */ },
//   ),

import 'package:flutter/material.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Minimal Data2 contract — replace with your real model import
// ─────────────────────────────────────────────────────────────────────────────

abstract class ActiveCallData {
  String? get callType;      // "chat" | "audio" | "video"
  String? get status;        // "accept_astro" etc.
  String? get userName;
  String? get userImage;
  String? get callRate;
  String? get channelId;
  String? get fbChannelId;
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme constants
// ─────────────────────────────────────────────────────────────────────────────

class _C {
  static const bg        = Color(0xFF1A1A1A);   // near-black card
  static const surface   = Color(0xFF2A2A2A);   // slightly lighter surface
  static const red       = Color(0xFFD41000);   // brand red
  static const white     = Colors.white;
  static const grey      = Color(0xFF9E9E9E);
  static const chatGreen = Color(0xFF00C97B);
  static const audioBlue = Color(0xFF2979FF);
  static const videoAmber= Color(0xFFFFAB00);
}

// ─────────────────────────────────────────────────────────────────────────────
// Call-type config
// ─────────────────────────────────────────────────────────────────────────────

class _TypeConfig {
  final Color        color;
  final IconData     icon;
  final String       label;

  const _TypeConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

_TypeConfig _typeConfig(String? type) {
  switch (type?.toLowerCase()) {
    case 'audio':
      return const _TypeConfig(
        color: _C.audioBlue, icon: Icons.phone_in_talk_rounded, label: 'Audio Call');
    case 'video':
      return const _TypeConfig(
        color: _C.videoAmber, icon: Icons.videocam_rounded, label: 'Video Call');
    default:
      return const _TypeConfig(
        color: _C.chatGreen, icon: Icons.chat_bubble_rounded, label: 'Chat');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class ActiveCallFloatingCard extends StatefulWidget {
  /// Pass your Data2 model here. Card hides itself when null.
  final dynamic data2;           // Data2? from your model

  /// Called when user taps "Resume" — navigate back to active screen.
  final VoidCallback onTap;

  /// Called when user taps the ✕ end button.
  final VoidCallback? onDismiss;

  /// Optional live seconds-remaining from CountdownManager or similar.
  /// If null, no timer is shown.
  final int? timeLeftSeconds;

  const ActiveCallFloatingCard({
    super.key,
    required this.data2,
    required this.onTap,
    this.onDismiss,
    this.timeLeftSeconds,
  });

  @override
  State<ActiveCallFloatingCard> createState() => _ActiveCallFloatingCardState();
}

class _ActiveCallFloatingCardState extends State<ActiveCallFloatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double>   _pulseAnim;

  void _resumeActiveCall() {
  final d = widget.data2;
  if (d == null) return;

  switch (d?.callType?.toString().toLowerCase()) {
    case 'audio':
      NavigationManager().openAudioCallScreen(
        channelId : d?.channelId?.toString()  ?? '',
        token     : '',
        userName  : d?.userName?.toString()   ?? '',
        userAvatar: d?.userImage?.toString()  ?? '',
      );
      break;

    case 'video':
      NavigationManager().openVideoCallScreen(
        channelId : d?.channelId?.toString()  ?? '',
        token     : '',
        userName  : d?.userName?.toString()   ?? '',
        userAvatar: d?.userImage?.toString()  ?? '',
      );
      break;

    default: // chat
      NavigationManager().openChatScreen(
        channelId : d?.channelId?.toString()  ?? '',
        astroId   : d?.astroId?.toString()    ?? '',
        userId    : d?.userId?.toString()     ?? '',
        userName  : d?.userName?.toString()   ?? '',
        userAvatar: d?.userImage?.toString()  ?? '',
      );
      break;
  }
}

  // Draggable position — start bottom-right
  Offset _position = const Offset(-12, -100);
  bool   _positionSet = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_positionSet) {
      final size = MediaQuery.of(context).size;
      _position   = Offset(size.width - 300, size.height - 160);
      _positionSet = true;
    }
  }

  String _fmtTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data2 == null) return const SizedBox.shrink();

    final d      = widget.data2;
   // ✅ FIXED — safe null-aware toString()
final cfg   = _typeConfig(d?.callType?.toString());
final name  = d?.userName?.toString()  ?? 'User';
final image = d?.userImage?.toString() ?? '';
final rate  = d?.callRate?.toString()  ?? '0';
    final tLeft  = widget.timeLeftSeconds;
    final lowBal = tLeft != null && tLeft <= 120;  // ≤ 2 min

    return Positioned(
      left: _position.dx,
      top : _position.dy,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          final size = MediaQuery.of(context).size;
          _position = Offset(
            (_position.dx + d.delta.dx).clamp(0, size.width  - 272),
            (_position.dy + d.delta.dy).clamp(0, size.height - 100),
          );
        }),
        child: ScaleTransition(
          scale: _pulseAnim,
          child: _Card(
            cfg      : cfg,
            name     : name,
            image    : image,
            rate     : rate,
            tLeft    : tLeft,
            lowBal   : lowBal,
            fmtTime  : _fmtTime,
            onTap    :_resumeActiveCall,
            onDismiss: widget.onDismiss,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card body (extracted for clarity)
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final _TypeConfig           cfg;
  final String                name;
  final String                image;
  final String                rate;
  final int?                  tLeft;
  final bool                  lowBal;
  final String Function(int)  fmtTime;
  final VoidCallback          onTap;
  final VoidCallback?         onDismiss;

  const _Card({
    required this.cfg,
    required this.name,
    required this.image,
    required this.rate,
    required this.tLeft,
    required this.lowBal,
    required this.fmtTime,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color       : Colors.transparent,
      elevation   : 0,
      child: Container(
        width: 272,
        decoration: BoxDecoration(
          color       : _C.bg,
          borderRadius: BorderRadius.circular(16),
          border      : Border.all(color: cfg.color.withOpacity(0.35), width: 1.2),
          boxShadow   : [
            BoxShadow(
              color      : Colors.black.withOpacity(0.55),
              blurRadius : 20,
              offset     : const Offset(0, 6),
            ),
            BoxShadow(
              color      : cfg.color.withOpacity(0.18),
              blurRadius : 28,
              offset     : const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Type banner ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(0.15),
                  border: Border(
                    bottom: BorderSide(color: cfg.color.withOpacity(0.25), width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    // Live pulse dot
                    _PulseDot(color: cfg.color),
                    const SizedBox(width: 6),
                    Icon(cfg.icon, color: cfg.color, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      cfg.label,
                      style: TextStyle(
                        color      : cfg.color,
                        fontSize   : 11,
                        fontWeight : FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    // Timer badge
                    if (tLeft != null)
                      _TimerBadge(tLeft: tLeft!, fmtTime: fmtTime, lowBal: lowBal),
                    // Dismiss button
                    if (onDismiss != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          width : 22, height: 22,
                          decoration: BoxDecoration(
                            color : _C.red.withOpacity(0.15),
                            shape : BoxShape.circle,
                            border: Border.all(color: _C.red.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.call_end_rounded,
                              color: _C.red, size: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Main content ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Avatar
                    _Avatar(image: image, name: name, color: cfg.color),
                    const SizedBox(width: 10),
                    // Name + rate
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color      : _C.white,
                              fontSize   : 14,
                              fontWeight : FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$rate / min',
                            style: const TextStyle(
                              color    : _C.grey,
                              fontSize : 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (lowBal && tLeft != null) ...[
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: _C.red, size: 11),
                              const SizedBox(width: 3),
                              Text(
                                'Low balance',
                                style: TextStyle(
                                  color    : _C.red.withOpacity(0.9),
                                  fontSize : 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    // Resume button
                    _ResumeButton(color: cfg.color, onTap: onTap),
                  ],
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(
      width : 7, height: 7,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

class _TimerBadge extends StatelessWidget {
  final int                 tLeft;
  final String Function(int) fmtTime;
  final bool                lowBal;

  const _TimerBadge({
    required this.tLeft,
    required this.fmtTime,
    required this.lowBal,
  });

  @override
  Widget build(BuildContext context) {
    final color = lowBal ? _C.red : _C.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color       : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border      : Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_outlined, color: color, size: 10),
        const SizedBox(width: 3),
        Text(
          fmtTime(tLeft),
          style: TextStyle(
            color     : color,
            fontSize  : 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String image;
  final String name;
  final Color  color;

  const _Avatar({required this.image, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width : 42, height: 42,
      decoration: BoxDecoration(
        shape : BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: ClipOval(
        child: image.isNotEmpty
            ? Image.network(
                image,
                fit         : BoxFit.cover,
                errorBuilder: (_, __, ___) => _Placeholder(name: name),
              )
            : _Placeholder(name: name),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String name;
  const _Placeholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color : _C.surface,
      child : Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color     : _C.white,
            fontSize  : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ResumeButton extends StatelessWidget {
  final Color         color;
  final VoidCallback  onTap;

  const _ResumeButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color       : color,
          borderRadius: BorderRadius.circular(20),
          boxShadow   : [
            BoxShadow(
              color     : color.withOpacity(0.4),
              blurRadius: 8,
              offset    : const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          'Resume',
          style: TextStyle(
            color     : Colors.white,
            fontSize  : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}