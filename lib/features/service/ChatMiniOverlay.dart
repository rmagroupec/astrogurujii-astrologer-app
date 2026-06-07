// lib/features/service/widgets/chat_mini_overlay.dart
//
// Mirrors minimized_call_overlay.dart exactly, but for ChatProvider.
// Install once in app.dart via AudioCallOverlayManager pattern.
// Tap → expands back to ChatScreen using .value provider (same instance).

import 'package:astrologer_app/features/service/ChatScreen.dart';
import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manager — call install(context) once from _AppRoot (same as audio overlay)
// ─────────────────────────────────────────────────────────────────────────────
class ChatOverlayManager {
  static OverlayEntry? _entry;

  static void install(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: (_) => const _FloatingChatBubble());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context, rootOverlay: true).insert(_entry!);
    });
  }

  static void remove() {
    _entry?.remove();
    _entry = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating bubble
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingChatBubble extends StatefulWidget {
  const _FloatingChatBubble();
  @override
  State<_FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<_FloatingChatBubble>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(16, 220); // offset from audio bubble

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  ChatProvider? _lastProvider;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync   : this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startPolling();
  }

  void _startPolling() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      final provider = NavigationManager().activeChatProvider;
      if (provider != _lastProvider) {
        _lastProvider?.removeListener(_onProviderChanged);
        _lastProvider = provider;
        provider?.addListener(_onProviderChanged);
        if (mounted) setState(() {});
      }
      return true;
    });
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _lastProvider?.removeListener(_onProviderChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _expandChat(ChatProvider provider) {
    provider.expand();
    NavigationManager().navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ChatProvider>.value(
          value: provider,        // same instance — Firebase listener alive
          child: ChatScreen(
            channelId : provider.channelId,
            astroId   : provider.senderId,
            userId    : provider.receiverId,
            userName  : provider.callerName,
            userAvatar: provider.callerImage,
            resumed   : true,     // skips re-initializeChat()
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _lastProvider;
    if (provider == null || !provider.isMinimized || provider.isEnded) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx.clamp(0.0, size.width  - 210),
      top : _position.dy.clamp(0.0, size.height - 80),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0.0, size.width  - 210),
              (_position.dy + details.delta.dy).clamp(0.0, size.height - 80),
            );
          });
        },
        onTap: () => _expandChat(provider),
        child: ScaleTransition(
          scale: _pulseAnim,
          child: _ChatPill(
            provider: provider,
            onEnd   : () async {
              await provider.endChatApi(provider.channelId);
              if (mounted) setState(() {});
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill UI  — yellow/gold accent to distinguish from the blue audio pill
// ─────────────────────────────────────────────────────────────────────────────
class _ChatPill extends StatelessWidget {
  final ChatProvider provider;
  final VoidCallback onEnd;
  const _ChatPill({required this.provider, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation    : 12,
      borderRadius : BorderRadius.circular(50),
      shadowColor  : Colors.black45,
      child        : Container(
        height     : 64,
        constraints: const BoxConstraints(minWidth: 195, maxWidth: 230),
        decoration : BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient    : const LinearGradient(
            colors: [Color(0xFF7B5800), Color(0xFFEBC351)],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children    : [
            const SizedBox(width: 6),

            // Avatar + green dot
            Stack(
              children: [
                CircleAvatar(
                  radius         : 24,
                  backgroundColor: Colors.white24,
                  backgroundImage: provider.callerImage.isNotEmpty
                      ? NetworkImage(provider.callerImage)
                      : null,
                  child: provider.callerImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 26)
                      : null,
                ),
                Positioned(
                  bottom: 1,
                  right : 1,
                  child : Container(
                    width : 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color : const Color(0xFF43A047),
                      shape : BoxShape.circle,
                      border: Border.all(color: const Color(0xFF7B5800), width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 10),

            // Name + timer
            Expanded(
              child: Column(
                mainAxisAlignment : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.callerName,
                    style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble,
                          color: Colors.white70, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        provider.sessionDuration,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick end button
            GestureDetector(
              onTap: (){},
              child: Container(
                width     : 40,
                height    : 40,
                margin    : const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}