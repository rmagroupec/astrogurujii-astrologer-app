import 'package:flutter/material.dart';

/// Animated ripple rings shown around the avatar while waiting for connection.
/// Mirrors the web SpinAvatar ping rings.
class RingingWave extends StatelessWidget {
  final Animation<double> animation;

  const RingingWave({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            // Each ring is offset by 1/3 of the animation cycle
            final offset = index / 3.0;
            final value  = ((animation.value + offset) % 1.0);

            // Starts at avatar size (120), expands to 220
            final size   = 120.0 + (value * 100.0);
            final opacity = (1.0 - value).clamp(0.0, 1.0) * 0.6;

            return Container(
              width:  size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(opacity),
                  width: 2,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}