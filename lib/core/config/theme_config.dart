import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFCD726);
  static const Color headingTextColor = Colors.black;
  static const Color bodyTextColor = Color(0xFF6C7278);

  /// LIGHT THEME
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: headingTextColor),
      displayMedium: TextStyle(color: headingTextColor),
      displaySmall: TextStyle(color: headingTextColor),

      headlineLarge: TextStyle(color: headingTextColor),
      headlineMedium: TextStyle(color: headingTextColor),
      headlineSmall: TextStyle(color: headingTextColor),

      titleLarge: TextStyle(color: headingTextColor),
      titleMedium: TextStyle(color: headingTextColor),
      titleSmall: TextStyle(color: headingTextColor),

      bodyLarge: TextStyle(color: bodyTextColor),
      bodyMedium: TextStyle(color: bodyTextColor),
      bodySmall: TextStyle(color: bodyTextColor),

      labelLarge: TextStyle(color: bodyTextColor),
      labelMedium: TextStyle(color: bodyTextColor),
      labelSmall: TextStyle(color: bodyTextColor),
    ),
  );

  /// DARK THEME
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60),
      bodySmall: TextStyle(color: Colors.white54),
    ),
  );
}
