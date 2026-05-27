import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class AppGradientButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double? height;

  const AppGradientButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height ?? FigmaSize.h(56),
        child: InkWell(
          borderRadius: BorderRadius.circular(FigmaSize.w(14)),
          onTap: isLoading ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF28272F),
                  Color(0xFF4B4039),
                ],
              ),
              borderRadius: BorderRadius.circular(FigmaSize.w(14)),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: FigmaSize.w(22),
                      height: FigmaSize.w(22),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
