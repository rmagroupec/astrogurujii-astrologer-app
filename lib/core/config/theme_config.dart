// lib/core/config/theme_config.dart
// COMPLETE dark + light theme system
// All screens use Theme.of(context) colors — no more hardcoded Colors.white/black

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Brand colors (same in both modes) ──────────────────────────────────────
  static const Color primaryYellow  = Color(0xFFFCD417);  // your yellow
  static const Color accentRed      = Color(0xFFD41000);  // your red
  static const Color primaryColor   = primaryYellow;      // alias for existing code

  // ── Semantic tokens — light ────────────────────────────────────────────────
  static const Color _lightBg           = Color(0xFFF6F6F6);
  static const Color _lightSurface      = Colors.white;
  static const Color _lightCardBorder   = Color(0xFFE0E0E0);
  static const Color _lightText         = Color(0xFF1A1A1A);
  static const Color _lightSubText      = Color(0xFF6C7278);
  static const Color _lightDivider      = Color(0xFFEEEEEE);
  static const Color _lightToggleBg     = Color(0xFFF3F3F3);

  // ── Semantic tokens — dark ─────────────────────────────────────────────────
  static const Color _darkBg            = Color(0xFF0F0F0F);
  static const Color _darkSurface       = Color(0xFF1E1E1E);
  static const Color _darkCardBorder    = Color(0xFF2C2C2C);
  static const Color _darkText          = Color(0xFFF0F0F0);
  static const Color _darkSubText       = Color(0xFF9E9E9E);
  static const Color _darkDivider       = Color(0xFF2C2C2C);
  static const Color _darkToggleBg      = Color(0xFF2A2A2A);

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness  : Brightness.light,

    colorScheme: ColorScheme(
      brightness       : Brightness.light,
      primary          : primaryYellow,
      onPrimary        : Colors.black,
      secondary        : accentRed,
      onSecondary      : Colors.white,
      error            : accentRed,
      onError          : Colors.white,
      surface          : _lightSurface,
      onSurface        : _lightText,
      // custom extensions via extensions map below
    ),

    scaffoldBackgroundColor: _lightBg,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor    : primaryYellow,
      foregroundColor    : Colors.black,
      elevation          : 0,
      systemOverlayStyle : SystemUiOverlayStyle(
        statusBarColor           : Colors.transparent,
        statusBarIconBrightness  : Brightness.dark,
      ),
      titleTextStyle: TextStyle(
          color     : Colors.black,
          fontSize  : 16,
          fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: Colors.black),
    ),

    // Cards
    cardTheme: CardThemeData(
      color        : _lightSurface,
      elevation    : 0,
      shape        : RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side        : const BorderSide(color: _lightCardBorder),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(color: _lightDivider, thickness: 1),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled         : true,
      fillColor      : _lightSurface,
      hintStyle      : const TextStyle(color: _lightSubText, fontSize: 13),
      contentPadding : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: _lightCardBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: _lightCardBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: primaryYellow, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: accentRed)),
    ),

    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryYellow,
        foregroundColor: Colors.black,
        elevation      : 0,
        shape          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Outlined button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentRed,
        side           : const BorderSide(color: accentRed),
        shape          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      iconColor      : Color(0xFF444444),
      textColor      : _lightText,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primaryYellow : Colors.grey.shade300),
    ),

    // Text
    textTheme: const TextTheme(
      displayLarge : TextStyle(color: _lightText),
      displayMedium: TextStyle(color: _lightText),
      displaySmall : TextStyle(color: _lightText),
      headlineLarge: TextStyle(color: _lightText),
      headlineMedium:TextStyle(color: _lightText),
      headlineSmall: TextStyle(color: _lightText),
      titleLarge   : TextStyle(color: _lightText),
      titleMedium  : TextStyle(color: _lightText),
      titleSmall   : TextStyle(color: _lightText),
      bodyLarge    : TextStyle(color: _lightText),
      bodyMedium   : TextStyle(color: _lightSubText),
      bodySmall    : TextStyle(color: _lightSubText),
      labelLarge   : TextStyle(color: _lightSubText),
      labelMedium  : TextStyle(color: _lightSubText),
      labelSmall   : TextStyle(color: _lightSubText),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? accentRed : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side       : const BorderSide(color: _lightCardBorder),
    ),

    // Bottom sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _lightSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: _lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior        : SnackBarBehavior.floating,
      backgroundColor : const Color(0xFF323232),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    extensions: [
      AppColors.light,
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness  : Brightness.dark,

    colorScheme: ColorScheme(
      brightness  : Brightness.dark,
      primary     : primaryYellow,
      onPrimary   : Colors.black,
      secondary   : accentRed,
      onSecondary : Colors.white,
      error       : accentRed,
      onError     : Colors.white,
      surface     : _darkSurface,
      onSurface   : _darkText,
    ),

    scaffoldBackgroundColor: _darkBg,

    appBarTheme: const AppBarTheme(
      backgroundColor    : Color(0xFF1A1A1A),
      foregroundColor    : Colors.white,
      elevation          : 0,
      systemOverlayStyle : SystemUiOverlayStyle(
        statusBarColor          : Colors.transparent,
        statusBarIconBrightness : Brightness.light,
      ),
      titleTextStyle: TextStyle(
          color     : Colors.white,
          fontSize  : 16,
          fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      color    : _darkSurface,
      elevation: 0,
      shape    : RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side        : const BorderSide(color: _darkCardBorder),
      ),
    ),

    dividerTheme: const DividerThemeData(color: _darkDivider, thickness: 1),

    inputDecorationTheme: InputDecorationTheme(
      filled        : true,
      fillColor     : _darkSurface,
      hintStyle     : const TextStyle(color: _darkSubText, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: _darkCardBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: _darkCardBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: primaryYellow, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide  : const BorderSide(color: accentRed)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryYellow,
        foregroundColor: Colors.black,
        elevation      : 0,
        shape          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentRed,
        side           : const BorderSide(color: accentRed),
        shape          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFFBBBBBB),
      textColor: _darkText,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.black : Colors.grey.shade600),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primaryYellow : Colors.grey.shade700),
    ),

    textTheme: const TextTheme(
      displayLarge : TextStyle(color: _darkText),
      displayMedium: TextStyle(color: _darkText),
      displaySmall : TextStyle(color: _darkText),
      headlineLarge: TextStyle(color: _darkText),
      headlineMedium:TextStyle(color: _darkText),
      headlineSmall: TextStyle(color: _darkText),
      titleLarge   : TextStyle(color: _darkText),
      titleMedium  : TextStyle(color: _darkText),
      titleSmall   : TextStyle(color: _darkText),
      bodyLarge    : TextStyle(color: _darkText),
      bodyMedium   : TextStyle(color: _darkSubText),
      bodySmall    : TextStyle(color: _darkSubText),
      labelLarge   : TextStyle(color: _darkSubText),
      labelMedium  : TextStyle(color: _darkSubText),
      labelSmall   : TextStyle(color: _darkSubText),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? accentRed : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side       : const BorderSide(color: _darkCardBorder),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior        : SnackBarBehavior.floating,
      backgroundColor : const Color(0xFF2C2C2C),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    extensions: [
      AppColors.dark,
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppColors ThemeExtension — access custom semantic colors anywhere via:
//   final c = Theme.of(context).ext<AppColors>()!;
//   c.cardBg, c.toggleBg, c.subText, c.border, etc.
// ─────────────────────────────────────────────────────────────────────────────
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color border;
  final Color text;
  final Color subText;
  final Color divider;
  final Color toggleBg;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.border,
    required this.text,
    required this.subText,
    required this.divider,
    required this.toggleBg,
  });

  static const light = AppColors(
    bg      : Color(0xFFF6F6F6),
    surface : Colors.white,
    border  : Color(0xFFE0E0E0),
    text    : Color(0xFF1A1A1A),
    subText : Color(0xFF6C7278),
    divider : Color(0xFFEEEEEE),
    toggleBg: Color(0xFFF3F3F3),
  );

  static const dark = AppColors(
    bg      : Color(0xFF0F0F0F),
    surface : Color(0xFF1E1E1E),
    border  : Color(0xFF2C2C2C),
    text    : Color(0xFFF0F0F0),
    subText : Color(0xFF9E9E9E),
    divider : Color(0xFF2C2C2C),
    toggleBg: Color(0xFF2A2A2A),
  );

  @override
  AppColors copyWith({
    Color? bg, Color? surface, Color? border,
    Color? text, Color? subText, Color? divider, Color? toggleBg,
  }) => AppColors(
    bg      : bg       ?? this.bg,
    surface : surface  ?? this.surface,
    border  : border   ?? this.border,
    text    : text     ?? this.text,
    subText : subText  ?? this.subText,
    divider : divider  ?? this.divider,
    toggleBg: toggleBg ?? this.toggleBg,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg      : Color.lerp(bg,       other.bg,       t)!,
      surface : Color.lerp(surface,  other.surface,  t)!,
      border  : Color.lerp(border,   other.border,   t)!,
      text    : Color.lerp(text,     other.text,     t)!,
      subText : Color.lerp(subText,  other.subText,  t)!,
      divider : Color.lerp(divider,  other.divider,  t)!,
      toggleBg: Color.lerp(toggleBg, other.toggleBg, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience extension — use c.bg instead of Theme.of(context).ext<AppColors>()!.bg
// ─────────────────────────────────────────────────────────────────────────────
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  bool      get isDark  => Theme.of(this).brightness == Brightness.dark;
}