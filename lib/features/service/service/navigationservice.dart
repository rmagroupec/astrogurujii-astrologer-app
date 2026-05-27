import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _locked = false;
  static DateTime? _lastNavigation;

  // Prevent duplicate pushes within 500ms
  static bool _shouldAllowNavigation() {
    if (_locked) return false;
    
    final now = DateTime.now();
    if (_lastNavigation != null) {
      final difference = now.difference(_lastNavigation!);
      if (difference.inMilliseconds < 500) {
        return false; // Too soon, ignore
      }
    }
    return true;
  }

  static Future<T?> pushOnce<T>(Route<T> route) async {
    if (!_shouldAllowNavigation()) {
      print('Navigation blocked - too soon or locked');
      return null;
    }

    _locked = true;
    _lastNavigation = DateTime.now();

    try {
      final result = await navigatorKey.currentState?.push(route);
      return result;
    } finally {
      // Unlock after a delay to prevent rapid-fire navigations
      await Future.delayed(const Duration(milliseconds: 300));
      _locked = false;
    }
  }

  static Future<T?> replaceOnce<T, TO>(Route<T> route) async {
    if (!_shouldAllowNavigation()) {
      print('Navigation blocked - too soon or locked');
      return null;
    }

    _locked = true;
    _lastNavigation = DateTime.now();

    try {
      final result = await navigatorKey.currentState?.pushReplacement(route);
      return result;
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      _locked = false;
    }
  }

  static bool canNavigate() => !_locked;
  
  static void reset() {
    _locked = false;
    _lastNavigation = null;
  }
}