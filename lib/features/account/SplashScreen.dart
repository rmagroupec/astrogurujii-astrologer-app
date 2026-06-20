// lib/features/account/SplashScreen.dart
//
// FIX: After checking login status, also check ActiveCallStore for a call
// that was in progress when the OS killed the app. If found, re-open the
// call screen directly (bypassing the Incoming screen — the call is already
// accepted/active). This is the correct fix for:
//   "app goes to background → process killed → user returns → no call showing"
//
// Priority order on startup:
//   1. If NOT logged in → LoginScreen (don't restore call)
//   2. If logged in + active call record → re-open call screen
//   3. If logged in + no active call → MainNavScreen (normal)

import 'package:astrologer_app/MainNavScreen.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/account/LoginScreen.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/features/service/active_call_store.dart';
import 'package:astrologer_app/service/localStorageService.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Show logo for at least 1.5 s (reduced from 2 s so restore feels snappy)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final loggedIn = await LocalStorageService().isLoggedIn();

    if (!loggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    // ── Logged in — check for an active call that needs restoring ──────────
    final call = await ActiveCallStore.restore();

    if (call != null) {
      // Navigate to home first (so back-stack is clean), then push call screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );

      // Small delay so MainNavScreen (+ overlays) finishes mounting
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // Re-open the correct call screen
      switch (call.type) {
        case ActiveCallType.audio:
          await NavigationManager().openAudioCallScreen(
            channelId : call.channelId,
            token     : call.token,
            userName  : call.userName,
            userAvatar: call.userAvatar,
          );
        case ActiveCallType.video:
          await NavigationManager().openVideoCallScreen(
            channelId : call.channelId,
            token     : call.token,
            userName  : call.userName,
            userAvatar: call.userAvatar,
          );
        case ActiveCallType.chat:
          await NavigationManager().openChatScreen(
            channelId : call.channelId,
            astroId   : call.astroId,
            userId    : call.userId,
            userName  : call.userName,
            userAvatar: call.userAvatar,
          );
      }
      return;
    }

    // Normal startup — no active call
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: FigmaSize.w(160),
          fit  : BoxFit.contain,
        ),
      ),
    );
  }
}