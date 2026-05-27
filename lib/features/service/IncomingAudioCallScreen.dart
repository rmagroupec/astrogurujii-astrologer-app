import 'package:astrologer_app/core/widgets/RingingWave.dart';
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

  @override
  void initState() {
    super.initState();

    /// 🔔 Ring animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    /// 🔊 Play ringtone
    FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume: 0.8,
      asAlarm: false,
    );
  }

  @override
  void dispose() {
    _ringController.dispose();

    /// 🔇 Stop ringtone safely
    FlutterRingtonePlayer().stop();

    super.dispose();
  }

  void _stopAndPop(String result) {
    FlutterRingtonePlayer().stop();
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2B6B),
              Color(0xFF0A2356),
              Color(0xFF071A42),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _circleIconBtn(
                      icon: Icons.chevron_left,
                      onTap: () => _stopAndPop('audio_reject'),
                    ),
                    const Spacer(),
                    _circleIconBtn(
                      icon: Icons.more_horiz,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.06),

              // ── Avatar + ringing waves ────────────────────────────────
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (_, __) => RingingWave(
                        animation: _ringController,
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE6A817),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.profile.isNotEmpty
                            ? Image.network(
                                widget.profile,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarFallback(),
                              )
                            : _avatarFallback(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Caller name ───────────────────────────────────────────
              Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              // ── Status label ──────────────────────────────────────────
              Text(
                'Incomming Audio  Call',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              // ── Accept / Decline buttons ──────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Accept
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _stopAndPop('audio_accept'),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4CAF50),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50)
                                      .withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Decline
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _stopAndPop('audio_reject'),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE53935),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935)
                                      .withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Decline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
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