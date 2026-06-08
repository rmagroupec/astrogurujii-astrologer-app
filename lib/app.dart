// lib/app.dart
//
// FIX: _onForegroundMessage — the old guard `if (type != 'initiate') return`
//      was blocking all messages where type='audio'/'video'/'chat' (no notification_type).
//      Now accepts EITHER notification_type=='initiate' OR a known call type directly.

import 'dart:async';

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/account/SplashScreen.dart';
import 'package:astrologer_app/features/service/ChatMiniOverlay.dart';
import 'package:astrologer_app/features/service/VideoCallOverlay.dart';
import 'package:astrologer_app/features/service/minimized_call_overlay.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    _fcmSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Install floating overlays after first frame (Overlay is ready then)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioCallOverlayManager.install(context);
      ChatOverlayManager.install(context);
      VideoCallOverlayManager.install(context);
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data             = message.data;
    final notificationType = data['notification_type'] ?? '';
    final callType         = data['type'] ?? '';

    // ✅ FIX: old guard was `if (type != 'initiate') return` — this blocked
    //         all messages where server sends type='audio' without notification_type.
    //         Now we accept EITHER notification_type=='initiate' OR a known call type.
    final isIncomingCall = notificationType == 'initiate' ||
        callType == 'audio' ||
        callType == 'video' ||
        callType == 'chat';

    if (!isIncomingCall) return;

    final channelId  = data['channel_id'] ?? '';
    final agoraToken = data['agora_token'] ?? '';
    final userName   = data['user_name']   ?? '';
    final userImage  = data['user_image']  ?? '';
    final userId     = data['user_id']     ?? '';

    if (channelId.isEmpty) return;

    if (callType == 'video') {
      NavigationManager().showIncomingVideoCall(
        token     : agoraToken,
        channelId : channelId,
        userName  : userName,
        userAvatar: userImage,
      );
    } else if (callType == 'audio') {
      NavigationManager().showIncomingAudioCall(
        token     : agoraToken,
        channelId : channelId,
        userName  : userName,
        userAvatar: userImage,
      );
    } else if (callType == 'chat') {
      final prefs   = await SharedPreferences.getInstance();
      final astroId = prefs.getString('astro_id') ?? '';
      NavigationManager().showIncomingChatRequest(
        requestId     : channelId,
        userName      : userName,
        userAvatar    : userImage,
        messagePreview: 'Incoming chat request',
        channelId     : channelId,
        userId        : userId,
        astroId       : astroId,
      );
    }
  }

  @override
  void dispose() {
    _fcmSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}