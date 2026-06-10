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
import 'package:astrologer_app/service/incoming_call_router.dart';
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
  await Firebase.initializeApp(
    options: const FirebaseOptions(           // reuse your exact options
      apiKey           : "AIzaSyDMOLSzOQbwUsaSg2576yb92UmNMxuf3Xc",
      appId            : "1:307653017355:android:bc17f957ae29d29bc8ec0e",
      messagingSenderId: "307653017355",
      projectId        : "astrogurujii-production",
      storageBucket    : "astrogurujii-production.firebasestorage.app",
      databaseURL      : "https://astrogurujii-production-default-rtdb.firebaseio.com",
    ),
  );

  final data = message.data;
  if (!IncomingCallRouter.isCallData(data)) return;

  // Persist so the app can replay it on first frame / resume (fixes #3).
  await IncomingCallRouter.persist(data);

  // Re-init the plugin in THIS isolate, then show the silent full-screen banner.
  await LocalNotificationService.initialize(onNotificationAction);
  await LocalNotificationService.showIncomingCall(
    title  : data['title'] ?? 'Incoming Call',
    body   : '${data['user_name'] ?? 'Someone'} is calling you',
    payload: data.map((k, v) => MapEntry(k, v.toString())),
  );
  // NOTE: no FlutterRingtonePlayer here — the incoming screen owns the ring.
}

final callStatusService = CallStatusService();

// ── Notification action handler (Accept / Reject button taps) ────────────────

@pragma('vm:entry-point')
void onNotificationAction(NotificationResponse response) async {
  final payload   = LocalNotificationService.decodePayload(response.payload ?? '');
  final channelId = payload['channel_id'] ?? '';
  if (channelId.isEmpty) return;

  // banner is cancelled by cancelNotification:true; make sure ring is dead too
  await LocalNotificationService.stopRingtone();
  await LocalNotificationService.cancelCall(channelId);

  if (response.actionId == LocalNotificationService.rejectAction) {
    await callStatusService.updateCallStatus(
        channelId: channelId, status: 'reject_astro');
    await IncomingCallRouter.clear();
    return;
  }

  // ACCEPT button OR body tap -> persist + bring app forward.
  // Actual navigation happens in handlePending() when the UI is visible,
  // which is what makes accept-from-killed / accept-from-lockscreen reliable.
  final accept = response.actionId == LocalNotificationService.acceptAction;
  await IncomingCallRouter.persist(payload, accept: accept);
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
  
FirebaseMessaging.onMessage.listen(IncomingCallRouter.handleForeground);

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