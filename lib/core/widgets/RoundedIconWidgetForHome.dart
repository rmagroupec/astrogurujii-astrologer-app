import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RoundedIconForHome extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const RoundedIconForHome({
    super.key,
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width : FigmaSize.w(52),
            height: FigmaSize.h(52),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x33FCD417),
                  Color(0x33FED402),
                ],
                begin: Alignment.topLeft,
                end  : Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                height: FigmaSize.h(30),
                width : FigmaSize.w(30),
              ),
            ),
          ),
          SizedBox(height: FigmaSize.h(6)),
          Text(
            label,
            style: TextStyle(
              fontSize  : FigmaSize.w(13),
              fontWeight: FontWeight.w600,
              color     : context.colors.text,  // ✅ dark/light aware
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}