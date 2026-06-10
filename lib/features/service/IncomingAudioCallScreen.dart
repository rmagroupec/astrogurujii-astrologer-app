// lib/features/service/IncomingAudioCallScreen.dart
//
// Changes:
// 1. ✅ Ringtone plays via FlutterRingtonePlayer on initState (already was present — kept)
// 2. ✅ Fixed typo "Incomming" → "Incoming"
// 3. ✅ Ringtone guaranteed to stop in _stopAndPop for both accept and decline

import 'package:astrologer_app/core/widgets/RingingWave.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

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
  bool _ringStopped = false;


  @override
  void initState() {
    super.initState();

    // 🔔 Ring animation
    _ringController = AnimationController(
      vsync   : this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 🔊 ✅ Play ringtone when incoming call arrives
  LocalNotificationService.playRingtone();
  }

 @override
void dispose() {
  _ringController.dispose();
  _stopRingOnce();
  super.dispose();
}

// bool _ringStopped = false;
void _stopRingOnce() {
  if (_ringStopped) return;
  _ringStopped = true;
  FlutterRingtonePlayer().stop();          // ✅ immediate sync stop
  LocalNotificationService.stopRingtone(); // updates flag
}

void _stopAndPop(String result) {
  _stopRingOnce();
  Navigator.pop(context, result);
}
  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _ringController,
      curve : Curves.easeOut,
    );

    return Scaffold(
      body: Container(
        width     : double.infinity,
        height    : double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin  : Alignment.topCenter,
            end    : Alignment.bottomCenter,
            colors : [
              Color(0xFF0D2B6B),
              Color(0xFF0A2356),
              Color(0xFF071A42),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _circleIconBtn(
                      icon : Icons.chevron_left,
                      onTap: () => _stopAndPop('audio_reject'),
                    ),
                    const Spacer(),
                    _circleIconBtn(
                      icon : Icons.more_horiz,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Avatar with ringing waves ─────────────────────────
              SizedBox(
                width : 220,
                height: 220,
                child : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated ripple rings
                    AnimatedBuilder(
                      animation: _ringController,
                      builder  : (_, __) => Stack(
                        alignment: Alignment.center,
                        children : List.generate(3, (i) {
                          final progress =
                              ((_ringController.value + i * 0.3) % 1.0);
                          return Container(
                            width : 140 + (progress * 80),
                            height: 140 + (progress * 80),
                            decoration: BoxDecoration(
                              shape : BoxShape.circle,
                              border: Border.all(
                                color: Colors.white
                                    .withOpacity((1 - progress) * 0.5),
                                width: 1.5,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Gold-bordered avatar
                    Container(
                      width     : 110,
                      height    : 110,
                      decoration: BoxDecoration(
                        shape : BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFE6A817), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color     : const Color(0xFFE6A817)
                                .withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.profile.isNotEmpty
                            ? Image.network(
                                widget.profile,
                                fit         : BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(),
                              )
                            : _avatarFallback(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Caller name ────────────────────────────────────────
              Text(
                widget.userName,
                style: const TextStyle(
                  color      : Colors.white,
                  fontSize   : 26,
                  fontWeight : FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              // ── Status ─────────────────────────────────────────────
              Text(
                'Incoming Audio Call',   // ✅ Fixed typo
                style: TextStyle(
                  color   : Colors.white.withOpacity(0.6),
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              // ── Accept / Decline ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 60, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ Accept
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _stopAndPop('audio_accept'),
                          child: Container(
                            width : 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape    : BoxShape.circle,
                              color    : const Color(0xFF43A047),
                              boxShadow: [
                                BoxShadow(
                                  color     : const Color(0xFF43A047)
                                      .withOpacity(0.35),
                                  blurRadius: 18,
                                  offset    : const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size : 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Accept',
                          style: TextStyle(
                            color     : Colors.white,
                            fontSize  : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // ✅ Decline
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _stopAndPop('audio_reject'),
                          child: Container(
                            width : 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape    : BoxShape.circle,
                              color    : const Color(0xFFE53935),
                              boxShadow: [
                                BoxShadow(
                                  color     : const Color(0xFFE53935)
                                      .withOpacity(0.35),
                                  blurRadius: 18,
                                  offset    : const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size : 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Decline',
                          style: TextStyle(
                            color     : Colors.white,
                            fontSize  : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: const Color(0xFF1A3C7A),
        child: const Icon(Icons.person, size: 70, color: Colors.white54),
      );

  Widget _circleIconBtn({
    required IconData  icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width : 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}