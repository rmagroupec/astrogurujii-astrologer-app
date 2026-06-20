// lib/features/Settings/MainSettingScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/Settings/components/SettingsGridComponent.dart';
import 'package:flutter/material.dart';

class Mainsettingscreen extends StatelessWidget {
  const Mainsettingscreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical  : FigmaSize.h(18),
          horizontal: FigmaSize.w(20),
        ),
        child: const SettingsIconGrid(),
      ),
    );
  }
}