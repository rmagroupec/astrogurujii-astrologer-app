// lib/app.dart
//
// FIX: _onForegroundMessage — the old guard `if (type != 'initiate') return`
//      was blocking all messages where type='audio'/'video'/'chat' (no notification_type).
//      Now accepts EITHER notification_type=='initiate' OR a known call type directly.

import 'dart:async';
import 'dart:io';

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/account/SplashScreen.dart';
import 'package:astrologer_app/features/service/ChatMiniOverlay.dart';
import 'package:astrologer_app/features/service/VideoCallOverlay.dart';
import 'package:astrologer_app/features/service/minimized_call_overlay.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'core/config/theme_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/utils/responsive.dart';
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
          title                     : 'Professional App',
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
// _AppRoot — installs overlays and listens for foreground FCM messages
// ─────────────────────────────────────────────────────────────────────────────
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  StreamSubscription? _fcmSub;

  @override
  void initState() {
    super.initState();
    // _fcmSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Install floating overlays after first frame (Overlay is ready then)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AudioCallOverlayManager.install(context);
      ChatOverlayManager.install(context);
      VideoCallOverlayManager.install(context);
      await _requestAllPermissions(context);
    });
  }

  Future<void> _requestAllPermissions(BuildContext context) async {
  // Step 1: normal runtime permissions
  await [
    Permission.camera,
    Permission.microphone,
    Permission.notification,
    Permission.phone,
    Permission.bluetooth,
    Permission.bluetoothConnect,
  ].request();

  if (!context.mounted) return;

  // Step 2: overlay permission
  if (Platform.isAndroid) {
    await _requestOverlayPermission(context);
  }
}

Future<void> _requestOverlayPermission(BuildContext context) async {
  const channel = MethodChannel('com.astrologer.astro/overlay');

  Future<bool> canDraw() async {
    try {
      return await channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) { return false; }
  }

  if (await canDraw()) return; // already granted

  if (!context.mounted) return;

  // ✅ This dialog will actually show because we're inside MaterialApp now
  final shouldOpen = await showDialog<bool>(
    context            : context,
    barrierDismissible : false,
    builder: (ctx) => AlertDialog(
      title  : const Text('Allow Display Over Other Apps'),
      content: const Text(
        'To show incoming calls when another app is open, '
        'please enable "Display over other apps" for this app.\n\n'
        'Tap "Open Settings", toggle it ON, then press back.',
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

  await channel.invokeMethod('openOverlaySettings'); // opens exact settings page

  // Poll until user comes back
  for (int i = 0; i < 120; i++) {
    await Future.delayed(const Duration(milliseconds: 500));
    if (await canDraw()) {
      debugPrint('✅ Overlay permission granted');
      return;
    }
  }
}

 Future<void> _onForegroundMessage(RemoteMessage message) async {
  final data      = message.data;
  final callType  = data['type'] ?? '';
  final notifType = data['notification_type'] ?? '';

  debugPrint('📨 Foreground FCM: type=$callType notif=$notifType data=$data');

  final isIncomingCall = notifType == 'initiate' ||
      callType == 'audio' ||
      callType == 'video' ||
      callType == 'chat';

  if (!isIncomingCall) return;
  if ((data['channel_id'] ?? '').isEmpty) return;

  // ✅ Same as background — show full screen intent which opens incoming page
  await LocalNotificationService.showIncomingCall(
    title  : data['title'] ?? 'Incoming Call',
    body   : '${data['user_name'] ?? 'Someone'} is calling you',
    payload: data.map((k, v) => MapEntry(k, v.toString())),
  );
}
  
  @override
  void dispose() {
    _fcmSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}