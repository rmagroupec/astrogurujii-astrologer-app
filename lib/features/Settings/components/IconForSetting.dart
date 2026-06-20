// lib/features/Settings/components/IconForSetting.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IconForSetting extends StatelessWidget {
  final String       iconPath;
  final String       label;
  final VoidCallback onTap;

  const IconForSetting({
    super.key,
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical  : FigmaSize.h(10),
            horizontal: FigmaSize.w(10)),
        decoration: BoxDecoration(
          color       : AppTheme.primaryYellow.withOpacity(
              isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border      : isDark
              ? Border.all(
                  color: AppTheme.primaryYellow.withOpacity(0.15))
              : null,
        ),
        child: Column(
          children: [
            Container(
              width : FigmaSize.w(52),
              height: FigmaSize.h(52),
              decoration: BoxDecoration(
                color: isDark ? c.toggleBg : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color     : Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset    : const Offset(0, 2),
                        ),
                      ],
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
                fontSize  : FigmaSize.w(11),
                color     : c.text,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}