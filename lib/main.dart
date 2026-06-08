// lib/main.dart
//
// FIXES:
// 1. ✅ onNotificationAction — Accept button now goes DIRECTLY to call screen
//       (was wrongly calling showIncomingAudioCall which re-shows the IncomingScreen)
// 2. ✅ _parsePayload — URI-decodes values (LocalNotificationService encodes them)
// 3. ✅ firebaseMessagingBackgroundHandler — also accepts type-based trigger
//       in case server sends type='audio'/'video'/'chat' without notification_type='initiate'

import 'dart:io';

import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:astrologer_app/service/notificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Background handler (runs in separate isolate when app is killed/background) ──
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data      = message.data;
  final callType  = data['type'] ?? '';
  final notifType = data['notification_type'] ?? '';

  final isIncomingCall = notifType == 'initiate' ||
      callType == 'audio' ||
      callType == 'video' ||
      callType == 'chat';

  if (!isIncomingCall) return;

  // ✅ Must re-initialize in background isolate before calling show
  await LocalNotificationService.initialize(onNotificationAction);

  await LocalNotificationService.showIncomingCall(
    title  : data['title'] ?? 'Incoming Call',
    body   : '${data['user_name'] ?? 'Someone'} is calling you',
    payload: data.map((k, v) => MapEntry(k, v.toString())),
  );
}

final callStatusService = CallStatusService();

// ── Notification action handler (Accept / Reject button taps) ────────────────
void onNotificationAction(NotificationResponse response) async {
  // ✅ Stop ringtone FIRST — before any async work
  // Works for all cases: accept, reject, body tap
  FlutterRingtonePlayer().stop();
  await LocalNotificationService.stopRingtone();

  final payload   = _parsePayload(response.payload);
  final channelId = payload['channel_id'];
  final type      = payload['type'];

  if (channelId == null || channelId.isEmpty) return;

  final prefs   = await SharedPreferences.getInstance();
  final astroId = prefs.getString('astro_id') ?? '';

  switch (response.actionId) {
    case LocalNotificationService.acceptAction:
      await LocalNotificationService.cancelCall(channelId);
      await callStatusService.updateCallStatus(
        channelId: channelId,
        status   : 'accept_astro',
      );
      if (type == 'audio') {
        NavigationManager().openAudioCallScreen(
          channelId : channelId,
          token     : payload['agora_token'] ?? '',
          userName  : payload['user_name']   ?? '',
          userAvatar: payload['user_image']  ?? '',
        );
      } else if (type == 'video') {
        NavigationManager().openVideoCallScreen(
          channelId : channelId,
          token     : payload['agora_token'] ?? '',
          userName  : payload['user_name']   ?? '',
          userAvatar: payload['user_image']  ?? '',
        );
      } else if (type == 'chat') {
        NavigationManager().openChatScreen(
          channelId : channelId,
          astroId   : astroId,
          userId    : payload['user_id']    ?? '',
          userName  : payload['user_name']  ?? '',
          userAvatar: payload['user_image'] ?? '',
        );
      }
      break;

    case LocalNotificationService.rejectAction:
      await LocalNotificationService.cancelCall(channelId);
      await callStatusService.updateCallStatus(
        channelId: channelId,
        status   : 'reject_astro',
      );
      break;

    default:
      await LocalNotificationService.cancelCall(channelId);
      int retries = 0;
      while (NavigationManager().navigatorKey.currentState == null && retries < 25) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }
      NavigationManager().reset();
      if (type == 'audio') {
        NavigationManager().showIncomingAudioCall(
          token     : payload['agora_token'] ?? '',
          channelId : channelId,
          userName  : payload['user_name']   ?? '',
          userAvatar: payload['user_image']  ?? '',
        );
      } else if (type == 'video') {
        NavigationManager().showIncomingVideoCall(
          token     : payload['agora_token'] ?? '',
          channelId : channelId,
          userName  : payload['user_name']   ?? '',
          userAvatar: payload['user_image']  ?? '',
        );
      } else if (type == 'chat') {
        NavigationManager().showIncomingChatRequest(
          requestId     : channelId,
          userName      : payload['user_name']   ?? '',
          userAvatar    : payload['user_image']  ?? '',
          messagePreview: 'Incoming chat request',
          channelId     : channelId,
          userId        : payload['user_id']     ?? '',
          astroId       : astroId,
        );
      }
      break;
  }
}
// ✅ FIX: URI-decode values — LocalNotificationService encodes them with
//         Uri.encodeComponent so spaces/special chars survive the payload string.
Map<String, String> _parsePayload(String? payload) {
  if (payload == null || payload.isEmpty) return {};
  return Map.fromEntries(
    payload.split('&').where((e) => e.contains('=')).map((e) {
      final idx   = e.indexOf('=');
      final key   = e.substring(0, idx);
      final value = Uri.decodeComponent(e.substring(idx + 1));
      return MapEntry(key, value);
    }),
  );
}

// ── Permission helper ─────────────────────────────────────────────────────────
// ── Overlay permission via native MethodChannel ───────────────────────────────
const _overlayChannel = MethodChannel('com.astrologer.astro/overlay');

Future<bool> _canDrawOverlays() async {
  try {
    return await _overlayChannel.invokeMethod<bool>('canDrawOverlays') ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> _openOverlaySettings() async {
  try {
    await _overlayChannel.invokeMethod('openOverlaySettings');
  } catch (e) {
    debugPrint('openOverlaySettings failed: $e');
  }
}

Future<void> _requestOverlayPermission(BuildContext context) async {
  final granted = await _canDrawOverlays();
  if (granted) return;

  if (!context.mounted) return;

  final shouldOpen = await showDialog<bool>(
    context            : context,
    barrierDismissible : false,
    builder: (ctx) => AlertDialog(
      title  : const Text('Allow Display Over Other Apps'),
      content: const Text(
        'To show incoming calls when another app is open, '
        'please enable "Display over other apps" for this app.\n\n'
        'Tap "Open Settings", find this app in the list, and toggle it ON, '
        'then press the back button to return.',
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

  await _openOverlaySettings(); // opens Settings.ACTION_MANAGE_OVERLAY_PERMISSION natively

  // Poll until user comes back and grants it
  await _waitForOverlayPermission();
}

Future<void> _waitForOverlayPermission() async {
  for (int i = 0; i < 120; i++) {
    await Future.delayed(const Duration(milliseconds: 500));
    if (await _canDrawOverlays()) {
      debugPrint('✅ Overlay permission granted');
      return;
    }
  }
  debugPrint('⚠️ Overlay permission not granted');
}


// ── Main ──────────────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey           : "AIzaSyDMOLSzOQbwUsaSg2576yb92UmNMxuf3Xc",
      appId            : "1:307653017355:android:bc17f957ae29d29bc8ec0e",
      messagingSenderId: "307653017355",
      projectId        : "astrogurujii-production",
      storageBucket    : "astrogurujii-production.firebasestorage.app",
      databaseURL      : "https://astrogurujii-production-default-rtdb.firebaseio.com",
    ),
  );
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  await LocalNotificationService.initialize(onNotificationAction);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  debugPrint('🔥 FOREGROUND HIT: ${message.data}');

  final data      = message.data;
  final callType  = data['type'] ?? '';
  final notifType = data['notification_type'] ?? '';

  final isIncomingCall = notifType == 'initiate' ||
      callType == 'audio' ||
      callType == 'video' ||
      callType == 'chat';

  if (!isIncomingCall) return;
  if ((data['channel_id'] ?? '').isEmpty) return;

  final channelId  = data['channel_id'] ?? '';
  final agoraToken = data['agora_token'] ?? '';
  final userName   = data['user_name']   ?? '';
  final userImage  = data['user_image']  ?? '';
  final userId     = data['user_id']     ?? '';

  // ✅ Reset stale locks
  NavigationManager().reset();

  // ✅ Wait for navigator
  int retries = 0;
  while (NavigationManager().navigatorKey.currentState == null && retries < 20) {
    await Future.delayed(const Duration(milliseconds: 100));
    retries++;
  }

  if (NavigationManager().navigatorKey.currentState == null) {
    // Navigator not ready — fallback to fullScreenIntent notification
    await LocalNotificationService.showIncomingCall(
      title  : data['title'] ?? 'Incoming Call',
      body   : '${data['user_name'] ?? 'Someone'} is calling you',
      payload: data.map((k, v) => MapEntry(k, v.toString())),
    );
    return;
  }

  // ✅ Navigator ready — open incoming screen directly, no notification needed
  if (callType == 'audio') {
    NavigationManager().showIncomingAudioCall(
      token     : agoraToken,
      channelId : channelId,
      userName  : userName,
      userAvatar: userImage,
    );
  } else if (callType == 'video') {
    NavigationManager().showIncomingVideoCall(
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
});

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioCallProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VideoCallProvider()),
      ],
      builder: (context, child) => _PermissionWrapper(child: const MyApp()),
    ),
  );
}

// ── Permission wrapper ────────────────────────────────────────────────────────
class _PermissionWrapper extends StatefulWidget {
  final Widget child;
  const _PermissionWrapper({required this.child});

  @override
  State<_PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<_PermissionWrapper> {
  @override
  void initState() {
    super.initState();
   
  }

  @override
  Widget build(BuildContext context) => widget.child;
}