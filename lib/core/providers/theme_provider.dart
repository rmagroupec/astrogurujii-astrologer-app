// lib/core/providers/theme_provider.dart
// Persists theme choice across app restarts using SharedPreferences

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs  = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key) ?? 'system';
    _themeMode = _fromString(stored);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _toString(mode));
  }

  String _toString(ThemeMode m) => switch (m) {
    ThemeMode.light  => 'light',
    ThemeMode.dark   => 'dark',
    ThemeMode.system => 'system',
  };

  ThemeMode _fromString(String s) => switch (s) {
    'light'  => ThemeMode.light,
    'dark'   => ThemeMode.dark,
    _        => ThemeMode.system,
  };
}