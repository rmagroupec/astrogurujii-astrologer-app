// lib/app.dart
// PRODUCTION-GRADE _AppRoot — handles foreground FCM + overlay permission
// + resume routing

import 'dart:io';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/providers/locale_provider.dart';
import 'package:astrologer_app/core/providers/theme_provider.dart';
import 'package:astrologer_app/core/utils/responsive.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/account/SplashScreen.dart';
import 'package:astrologer_app/features/service/ChatMiniOverlay.dart';
import 'package:astrologer_app/features/service/VideoCallOverlay.dart';
import 'package:astrologer_app/features/service/minimized_call_overlay.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/incoming_call_router.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          navigatorKey              : NavigationManager().navigatorKey,
          debugShowCheckedModeBanner: false,
          title                     : 'Vaidikguru Astrologer',
          theme                     : AppTheme.lightTheme,
          darkTheme                 : AppTheme.darkTheme,
          themeMode                 : themeProvider.themeMode,
          locale                    : localeProvider.locale,
          supportedLocales          : AppLocalizations.supportedLocales,
          localizationsDelegates    : const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            Responsive.init(context);
            FigmaSize.init(context);
            return child!;
          },
          home: const _AppRoot(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppRoot
// Responsibilities:
//   1. Install floating call/chat overlays
//   2. Request overlay (draw-over-apps) permission
//   3. Route any pending call on first frame (cold start / background resume)
//   4. Route pending call on app resume (lifecycle)
//   5. Handle foreground FCM — show notification + route
// ─────────────────────────────────────────────────────────────────────────────
class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Install floating overlays (audio, video, chat bubbles)
      if (mounted) {
        AudioCallOverlayManager.install(context);
        ChatOverlayManager.install(context);
        VideoCallOverlayManager.install(context);
      }

      // Overlay permission (Android only)
      if (Platform.isAndroid && mounted) {
        await _requestOverlayPermission(context);
      }

      // Route any call that arrived while app was killed / backgrounded
      await IncomingCallRouter.handlePending();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when app comes back to foreground from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Small delay to let Navigator settle after app wakes
      Future.delayed(const Duration(milliseconds: 300), () {
        IncomingCallRouter.handlePending();
      });
    }
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY PERMISSION REQUEST
// ─────────────────────────────────────────────────────────────────────────────
const _overlayChannel = MethodChannel('com.astrologer.astro/overlay');

Future<bool> _canDrawOverlays() async {
  try {
    return await _overlayChannel.invokeMethod<bool>('canDrawOverlays') ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> _requestOverlayPermission(BuildContext context) async {
  if (await _canDrawOverlays()) return; // already granted
  if (!context.mounted) return;

  final shouldOpen = await showDialog<bool>(
    context           : context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title  : const Text('Allow Display Over Other Apps'),
      content: const Text(
        'To show incoming calls when another app is open or the screen is locked, '
        'please enable "Display over other apps" for this app.\n\n'
        'Tap "Open Settings", toggle it ON, then press Back.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child    : const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child    : const Text('Open Settings'),
        ),
      ],
    ),
  );

  if (shouldOpen != true) return;

  try {
    await _overlayChannel.invokeMethod('openOverlaySettings');
  } catch (_) {}

  // Poll until the user grants it or gives up (60 s)
  for (int i = 0; i < 120; i++) {
    await Future.delayed(const Duration(milliseconds: 500));
    if (await _canDrawOverlays()) {
      debugPrint('✅ Overlay permission granted');
      return;
    }
  }
  debugPrint('⚠️ Overlay permission not granted within 60 s');
}