// lib/features/service/IncomingChatScreen.dart
// PRODUCTION-GRADE — chat request with ringtone

import 'package:astrologer_app/service/incoming_call_router.dart';
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
    extends State<IncomingChatRequestScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late Animation<double>   _pulse;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    LocalNotificationService.playRingtone();
    LocalNotificationService.startVibration();   // ✅ continuous vibration

  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    return PopScope(
      canPop: false,
      child : Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background avatar
            widget.userAvatar.isNotEmpty
                ? Image.network(widget.userAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade900))
                : Container(color: Colors.grey.shade900),

            // Dark overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin  : Alignment.topCenter,
                  end    : Alignment.bottomCenter,
                  colors : [
                    Color(0x22000000),
                    Color(0x66000000),
                    Color(0xCC000000),
                    Color(0xEE000000),
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // Pulsing avatar
                  ScaleTransition(
                    scale: _pulse,
                    child: CircleAvatar(
                      radius         : 56,
                      backgroundColor: const Color(0xFFFCD417),
                      backgroundImage: widget.userAvatar.isNotEmpty
                          ? NetworkImage(widget.userAvatar) : null,
                      child: widget.userAvatar.isEmpty
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 52)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(widget.userName,
                      style: const TextStyle(
                          color     : Colors.white,
                          fontSize  : 28,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.messagePreview,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Incoming Chat Request',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),

                  const Spacer(),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ChatButton(
                          color  : Colors.red,
                          icon   : Icons.close,
                          label  : 'Decline',
                          onTap  : _decline,
                        ),
                        _ChatButton(
                          color  : const Color(0xFFFCD417),
                          icon   : Icons.chat_bubble,
                          label  : 'Accept',
                          onTap  : _accept,
                          iconColor: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final Color      color;
  final IconData   icon;
  final String     label;
  final VoidCallback onTap;
  final Color      iconColor;

  const _ChatButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    GestureDetector(
      onTap: onTap,
      child: Container(
        width : 68, height: 68,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 30),
      ),
    ),
    const SizedBox(height: 8),
    Text(label,
        style: const TextStyle(color: Colors.white70, fontSize: 13)),
  ]);
}