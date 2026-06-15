// lib/features/service/IncomingVideoCallScreen.dart
// PRODUCTION-GRADE — mirrors audio call screen exactly

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
    // Clear persisted call data immediately so a restart won't re-ring
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
    final anim = CurvedAnimation(
        parent: _ringController, curve: Curves.easeOut);

    return PopScope(
      canPop: false,
      child : Scaffold(
        body: Container(
          width : double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              begin : Alignment.topLeft,
              end   : Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                const Text('Incoming Video Call',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 16),

                SizedBox(
                  width : 200, height: 200,
                  child : Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: anim,
                        builder : (_, __) => Stack(
                          alignment: Alignment.center,
                          children: [
                            _ring(anim.value,         110),
                            _ring((anim.value + 0.33) % 1.0, 95),
                            _ring((anim.value + 0.66) % 1.0, 80),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius          : 52,
                        backgroundColor : const Color(0xFFFCD417),
                        backgroundImage : widget.profile.isNotEmpty
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
                        color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Video calling you…',
                    style: TextStyle(color: Colors.white54, fontSize: 16)),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CallButton(
                        color: Colors.red, icon: Icons.call_end,
                        label: 'Decline',   onTap: _decline),
                      _CallButton(
                        color: Colors.green, icon: Icons.videocam,
                        label: 'Accept',    onTap: _accept),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double progress, double maxR) => Opacity(
    opacity: (1 - progress).clamp(0.0, 1.0),
    child  : Container(
      width : maxR * 2 * progress + 104,
      height: maxR * 2 * progress + 104,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08)),
    ),
  );
}

class _CallButton extends StatelessWidget {
  final Color color; final IconData icon;
  final String label; final VoidCallback onTap;
  const _CallButton({required this.color, required this.icon,
      required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(children: [
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68, height: 68,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    ),
    const SizedBox(height: 8),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
  ]);
}