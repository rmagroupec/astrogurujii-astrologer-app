import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

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
  bool _ringStopped = false;

  @override
  void initState() {
    super.initState();

    /// 🔔 Ringing wave animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    /// 🔊 Play ringtone (FIXED)
   LocalNotificationService.playRingtone();
  }

  void _stopRingOnce() {
    if (_ringStopped) return;
    _ringStopped = true;
    LocalNotificationService.stopRingtone();
  }

  @override
  void dispose() {
    _stopRingOnce();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              /// 🔮 Avatar + Ringing Waves
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (_, __) {
                        return _RingingWave(animation: _ringController);
                      },
                    ),
                    CircleAvatar(
                      radius: 65,
                      backgroundImage: NetworkImage(widget.profile),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// 👤 Name
              Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              /// 🎥 Subtitle
              Text(
                "Incoming Video Call",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),

              const Spacer(),

              /// ☎️ Actions
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      color: Colors.redAccent,
                      icon: Icons.call_end,
                      onTap: () {
                        _stopRingOnce();
                        Navigator.pop(context, 'reject');
                      },
                    ),
                    _actionButton(
                      color: Colors.greenAccent,
                      icon: Icons.videocam,
                      onTap: () {
                        _stopRingOnce();
                        Navigator.pop(context, 'accept');
                      },
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

  Widget _actionButton({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }
}

/// 🔔 Ringing wave animation widget
class _RingingWave extends StatelessWidget {
  final Animation<double> animation;

  const _RingingWave({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (i) {
        final progress = ((animation.value + (i * 0.3)) % 1.0);
        return Container(
          width: 140 + (progress * 90),
          height: 140 + (progress * 90),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.purpleAccent.withOpacity(1 - progress),
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
