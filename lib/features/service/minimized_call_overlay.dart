// lib/features/service/widgets/minimized_call_overlay.dart
//
// Uses Flutter's Overlay system so it appears on top of ALL pages,
// including screens pushed by the Navigator.
//
// HOW TO USE:
//   In app.dart, replace SplashScreen() with:
//     home: const _AppRoot(),
//
//   And add _AppRoot at the bottom of app.dart:
//     class _AppRoot extends StatefulWidget { ... }   ← defined at end of this file
//
// OR simply call AudioCallOverlayManager.show(context) once from SplashScreen.initState()

import 'package:astrologer_app/features/service/AudioCallScreen.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Call this ONCE after the app starts — e.g. in SplashScreen.initState()
// or in your root widget's initState().
//
//   AudioCallOverlayManager.install(context);
// ─────────────────────────────────────────────────────────────────────────────
class AudioCallOverlayManager {
  static OverlayEntry? _entry;

  /// Call once from a widget that has access to the root Overlay.
  /// Best place: SplashScreen or MainNavScreen initState (after super.initState).
  static void install(BuildContext context) {
    if (_entry != null) return; // already installed

    _entry = OverlayEntry(
      builder: (_) => const _FloatingCallBubble(),
    );

    // Insert after the current frame so Overlay is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = Overlay.of(context, rootOverlay: true);
      overlay.insert(_entry!);
    });
  }

  static void remove() {
    _entry?.remove();
    _entry = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The actual floating bubble — listens to NavigationManager.activeAudioProvider
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingCallBubble extends StatefulWidget {
  const _FloatingCallBubble();

  @override
  State<_FloatingCallBubble> createState() => _FloatingCallBubbleState();
}

class _FloatingCallBubbleState extends State<_FloatingCallBubble>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(16, 120);

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  // We poll/listen by rebuilding when the provider notifies
  AudioCallProvider? _lastProvider;

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

    // Poll NavigationManager every second for a new provider
    _startPolling();
  }

  void _startPolling() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;

      final provider = NavigationManager().activeAudioProvider;
      if (provider != _lastProvider) {
        _lastProvider?.removeListener(_onProviderChanged);
        _lastProvider = provider;
        provider?.addListener(_onProviderChanged);
        if (mounted) setState(() {});
      }
      return true; // keep polling
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

  void _expandCall(AudioCallProvider provider) {
    provider.expand();
    NavigationManager().navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AudioCallProvider>.value(
          value: provider,
          child: AudioCallScreen(
            channelId  : provider.channelId,
            token      : '',          // engine already running
            callerName : provider.callerName,
            callerImage: provider.callerImage,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _lastProvider;

    // Hide when no active call, not minimized, or call ended
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
        onTap: () => _expandCall(provider),
        child: ScaleTransition(
          scale: _pulseAnim,
          child: _OverlayPill(
            provider: provider,
            onEnd   : () async {
              await provider.end();
              if (mounted) setState(() {});
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The pill UI
// ─────────────────────────────────────────────────────────────────────────────
class _OverlayPill extends StatelessWidget {
  final AudioCallProvider provider;
  final VoidCallback      onEnd;
  const _OverlayPill({required this.provider, required this.onEnd});

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
            colors: [Color(0xFF0D2B6B), Color(0xFF1565C0)],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children    : [
            const SizedBox(width: 6),

            // Avatar + status dot
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
                      color : provider.remoteJoined
                          ? const Color(0xFF43A047)
                          : Colors.orange,
                      shape : BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0D2B6B), width: 2),
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
                      const Icon(Icons.call, color: Color(0xFF90CAF9), size: 11),
                      const SizedBox(width: 4),
                      Text(
                        provider.remoteJoined ? provider.duration : 'Connecting...',
                        style: const TextStyle(
                            color: Color(0xFF90CAF9), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick end button
            GestureDetector(
              onTap: onEnd,
              child: Container(
                width     : 40,
                height    : 40,
                margin    : const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}