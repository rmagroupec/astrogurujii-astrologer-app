// lib/features/service/IncomingAudioCallScreen.dart
// PRODUCTION-GRADE ringtone + animation + accept/decline

import 'package:astrologer_app/core/widgets/RingingWave.dart';
import 'package:astrologer_app/service/incoming_call_router.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:flutter/material.dart';

class IncomingAudioCallScreen extends StatefulWidget {
  final String channelId;
  final String userName;
  final String profile;
  final String token;

  const IncomingAudioCallScreen({
    super.key,
    required this.channelId,
    required this.userName,
    required this.profile,
    required this.token,
  });

  @override
  State<IncomingAudioCallScreen> createState() =>
      _IncomingAudioCallScreenState();
}

class _IncomingAudioCallScreenState extends State<IncomingAudioCallScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ringController;
  bool _handled = false; // prevents double accept/decline

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync   : this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start ringtone — this is the ONLY place it should be started
    LocalNotificationService.playRingtone();
  }

  @override
  void dispose() {
    _ringController.dispose();
    // Always stop on dispose — covers back-button, timeout, etc.
    LocalNotificationService.stopRingtone();
    super.dispose();
  }

  void _accept() {
    if (_handled) return;
    _handled = true;
    LocalNotificationService.stopRingtone();
    // Clear persisted call data immediately so a restart won't re-ring
    IncomingCallRouter.clear();
    Navigator.of(context).pop('audio_accept');
  }

  void _decline() {
    if (_handled) return;
    _handled = true;
    LocalNotificationService.stopRingtone();
    IncomingCallRouter.clear();
    Navigator.of(context).pop('audio_decline');
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _ringController,
      curve : Curves.easeOut,
    );

    return PopScope(
      canPop: false, // prevent back button — must use decline
      child : Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ── Caller info ──────────────────────────────────────────────
              Text(
                'Incoming Audio Call',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 16),

              // Ripple + avatar
              SizedBox(
                width : 200,
                height: 200,
                child : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple rings
                    AnimatedBuilder(
                      animation: animation,
                      builder : (_, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          _ring(animation.value,        110),
                          _ring((animation.value + 0.3) % 1.0, 95),
                          _ring((animation.value + 0.6) % 1.0, 80),
                        ],
                      ),
                    ),
                    // Avatar
                    CircleAvatar(
                      radius     : 52,
                      backgroundColor: const Color(0xFFFCD417),
                      backgroundImage: widget.profile.isNotEmpty
                          ? NetworkImage(widget.profile) : null,
                      child: widget.profile.isEmpty
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 48)
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(widget.userName,
                  style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 26,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Calling you…',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),

              const Spacer(),

              // ── Action buttons ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decline
                    _CallButton(
                      color  : Colors.red,
                      icon   : Icons.call_end,
                      label  : 'Decline',
                      onTap  : _decline,
                    ),
                    // Accept
                    _CallButton(
                      color  : Colors.green,
                      icon   : Icons.call,
                      label  : 'Accept',
                      onTap  : _accept,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ring(double progress, double maxR) {
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 1.0),
      child  : Container(
        width     : maxR * 2 * progress + 104,
        height    : maxR * 2 * progress + 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final Color    color;
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _CallButton({
    required this.color, required this.icon,
    required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width : 68, height: 68,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ],
  );
}