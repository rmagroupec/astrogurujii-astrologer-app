// lib/features/service/IncomingVideoCallScreen.dart
// ── UI: Image 1 — full-screen blurred user photo, name at bottom, Accept/Decline
// ── Zero functional changes ───────────────────────────────────────────────────

import 'package:astrologer_app/service/incoming_call_router.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:flutter/material.dart';

class IncomingVideoCallScreen extends StatefulWidget {
  final String channelId;
  final String userName;
  final String profile;
  final String token;

  const IncomingVideoCallScreen({
    super.key,
    required this.channelId,
    required this.userName,
    required this.profile,
    required this.token,
  });

  @override
  State<IncomingVideoCallScreen> createState() =>
      _IncomingVideoCallScreenState();
}

class _IncomingVideoCallScreenState extends State<IncomingVideoCallScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ringController;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync   : this,
      duration: const Duration(seconds: 2),
    )..repeat();
    LocalNotificationService.playRingtone();
  }

  @override
  void dispose() {
    _ringController.dispose();
    LocalNotificationService.stopRingtone();
    super.dispose();
  }

  void _accept() {
    if (_handled) return;
    _handled = true;
    LocalNotificationService.stopRingtone();
    IncomingCallRouter.clear();
    Navigator.of(context).pop('accept');
  }

  void _decline() {
    if (_handled) return;
    _handled = true;
    LocalNotificationService.stopRingtone();
    IncomingCallRouter.clear();
    Navigator.of(context).pop('decline');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child : Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [

            // ── Full-screen blurred profile photo ────────────────────────
            if (widget.profile.isNotEmpty)
              Image.network(
                widget.profile,
                fit           : BoxFit.cover,
                width         : double.infinity,
                height        : double.infinity,
                errorBuilder  : (_, __, ___) => _fallbackBg(),
              )
            else
              _fallbackBg(),

            // ── Gradient overlay (light → dark toward bottom) ─────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin : Alignment.topCenter,
                  end   : Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0.0, 0.30, 0.60, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [

                  // ── Top action row ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TopBtn(icon: Icons.arrow_back_ios_new, onTap: () {}),
                        _TopBtn(icon: Icons.more_horiz,         onTap: () {}),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Caller name + subtitle ──────────────────────────────
                  Text(
                    widget.userName,
                    style: const TextStyle(
                        color     : Colors.white,
                        fontSize  : 28,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Incomming Video Call',
                    style: TextStyle(
                        color  : Colors.white70, fontSize: 15),
                  ),

                  const SizedBox(height: 40),

                  // ── Accept / Decline ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CallButton(
                          color: Colors.green.shade500,
                          icon : Icons.call,
                          label: 'Accept',
                          onTap: _accept,
                        ),
                        _CallButton(
                          color: Colors.red.shade500,
                          icon : Icons.call_end,
                          label: 'Decline',
                          onTap: _decline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A2D6D), Color(0xFF0D1B4B)],
        begin : Alignment.topCenter,
        end   : Alignment.bottomCenter,
      ),
    ),
  );
}

// ── Top icon button ───────────────────────────────────────────────────────────
class _TopBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _TopBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width : 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.18),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// ── Call button ───────────────────────────────────────────────────────────────
class _CallButton extends StatelessWidget {
  final Color        color;
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _CallButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width : 68, height: 68,
          decoration: BoxDecoration(
            color    : color,
            shape    : BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color     : color.withOpacity(0.45),
                blurRadius: 16,
                offset    : const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
      const SizedBox(height: 10),
      Text(label,
          style: const TextStyle(
              color     : Colors.white,
              fontSize  : 14,
              fontWeight: FontWeight.w500)),
    ],
  );
}