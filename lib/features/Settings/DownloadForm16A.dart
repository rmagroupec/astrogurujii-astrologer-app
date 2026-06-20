// lib/features/Settings/DownloadForm16A.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Downloadform16a extends StatefulWidget {
  const Downloadform16a({super.key});

  @override
  State<Downloadform16a> createState() => _Downloadform16aState();
}

class _Downloadform16aState extends State<Downloadform16a> {
  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Download Form 16A'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical  : FigmaSize.h(18),
          horizontal: FigmaSize.w(20),
        ),
        child: ListView.builder(
          itemCount : 6,
          shrinkWrap: true,
          physics   : const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical  : FigmaSize.h(2),
                horizontal: FigmaSize.w(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GSFPP1020J_2025-26',
                        style: TextStyle(
                          fontSize  : FigmaSize.w(14),
                          fontWeight: FontWeight.w600,
                          color     : c.subText,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/images/download.svg',
                        colorFilter: isDark
                            ? ColorFilter.mode(
                                AppTheme.primaryYellow, BlendMode.srcIn)
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: FigmaSize.h(14)),
                  Divider(color: c.divider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}