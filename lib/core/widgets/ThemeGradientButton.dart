import 'package:flutter/material.dart';
import 'package:astrologer_app/core/utils/size_config.dart';

class GradientButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? width;

  const GradientButton({
    super.key,
    required this.title,
    required this.onTap,
    this.height,
    this.margin,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ??
            EdgeInsets.symmetric(
              horizontal: FigmaSize.w(20),
              vertical: FigmaSize.h(20),
            ),
        height: height ?? FigmaSize.h(48),
        width: width,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFCD417),
              Color(0xFFFFE569),
            ],
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: FigmaSize.w(16),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
