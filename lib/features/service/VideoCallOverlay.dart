// lib/features/service/widgets/video_mini_overlay.dart
//
// Mirrors minimized_call_overlay.dart exactly, but for VideoCallProvider.
// Shows a green video-camera pill.
// Install once in _AppRoot alongside audio and chat overlays.

import 'package:astrologer_app/features/service/VideoCallScreen.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manager — call install(context) once from _AppRoot
// ─────────────────────────────────────────────────────────────────────────────
class VideoCallOverlayManager {
  static OverlayEntry? _entry;

  static void install(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: (_) => const _FloatingVideoBubble());
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
class _FloatingVideoBubble extends StatefulWidget {
  const _FloatingVideoBubble();
  @override
  State<_FloatingVideoBubble> createState() => _FloatingVideoBubbleState();
}

class _FloatingVideoBubbleState extends State<_FloatingVideoBubble>
    with SingleTickerProviderStateMixin {
  // Position below audio (120) and chat (220) bubbles
  Offset _position = const Offset(16, 320);

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  VideoCallProvider? _lastProvider;

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
      final provider = NavigationManager().activeVideoProvider;
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

  void _expandVideo(VideoCallProvider provider) {
    provider.expand();
    NavigationManager().navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<VideoCallProvider>.value(
          value  : provider,    // same instance — engine still running
          child  : VideoCallScreen(
            channelId : provider.channelId,
            token     : '',             // engine already joined — token not needed
            userName  : provider.callerName,
            userAvatar: provider.callerImage,
            resumed   : true,           // skips re-initAgora()
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
        onTap: () => _expandVideo(provider),
        child: ScaleTransition(
          scale: _pulseAnim,
          child: _VideoPill(
            provider: provider,
            onEnd   : () async {
              await provider.endLocalCall();
              if (mounted) setState(() {});
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill UI — green/teal accent to distinguish from blue (audio) and gold (chat)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoPill extends StatelessWidget {
  final VideoCallProvider provider;
  final VoidCallback      onEnd;
  const _VideoPill({required this.provider, required this.onEnd});

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
            colors: [Color(0xFF004D40), Color(0xFF00897B)],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children    : [
            const SizedBox(width: 6),

            // Avatar + live dot
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
                      color : provider.remoteUid != null
                          ? const Color(0xFF43A047)
                          : Colors.orange,
                      shape : BoxShape.circle,
                      border: Border.all(color: const Color(0xFF004D40), width: 2),
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
                      const Icon(Icons.videocam,
                          color: Colors.white70, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        provider.remoteUid != null
                            ? provider.duration
                            : 'Connecting…',
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
                child: const Icon(Icons.call_end,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}