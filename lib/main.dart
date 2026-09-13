// lib/main.dart
// PRODUCTION-GRADE — handles all 3 app states for incoming calls/chat/video

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
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND ISOLATE HANDLER
// Runs in a SEPARATE Dart isolate — no Flutter widgets, no Navigator.
// This isolate is torn down by Android within seconds of this function
// returning, so:
//   ✅ persist() the call data to SharedPreferences
//   ✅ showIncomingCall() — fullscreen notification to wake lock screen
//   ✅ hand off to astro_call_kit — it starts a native Android foreground
//      service that keeps ringing/vibrating long after THIS isolate dies
//   ❌ NEVER navigate here — no Navigator
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  final data = message.data;
  if (!IncomingCallRouter.isCallData(data)) return;

  final stringData = data.map((k, v) => MapEntry(k, v.toString()));
  final channelId  = stringData['channel_id'] ?? '';
  final title      = stringData['title'] ?? 'Incoming Call';
  final body       = '${stringData['user_name'] ?? 'Someone'} is calling';

  // 1. Persist so the main isolate can route when app resumes
  await IncomingCallRouter.persist(stringData);

  // 2. Show fullscreen notification — wakes lock screen, shows Accept/Reject
  //    We must re-init the plugin in THIS isolate
  await LocalNotificationService.initialize(onNotificationAction);
  await LocalNotificationService.showIncomingCall(
    title  : title,
    body   : body,
    payload: stringData,
  );

  // 3. Start native ringing — this is what makes the phone actually ring
  //    while the app is backgrounded or fully killed. astro_call_kit's
  //    CallRingtoneService keeps running (and ringing) independently of
  //    this isolate, which Android will tear down moments after this
  //    function returns.
  if (channelId.isNotEmpty) {
    await LocalNotificationService.playRingtone(
      channelId,
      title: title,
      body : body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION ACTION HANDLER
// Called when user taps Accept / Reject action buttons on the notification.
// This runs in EITHER main isolate (foreground) OR background isolate.
// Must be @pragma('vm:entry-point') and top-level.
//
// IMPORTANT: this is async void — use try/catch, never let it throw.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void onNotificationAction(NotificationResponse response) {
  _handleNotificationAction(response);
}

Future<void> _handleNotificationAction(NotificationResponse response) async {
  try {
    final payload   = LocalNotificationService.decodePayload(
        response.payload ?? '');
    final channelId = payload['channel_id'] ?? '';
    if (channelId.isEmpty) return;

    // Cancel the notification immediately (it has cancelNotification:true
    // on the action buttons but belt-and-suspenders here)
    await LocalNotificationService.cancelCall(channelId);

    // Stop ringtone unconditionally — forceStop works across isolate boundary
    await LocalNotificationService.forceStopRingtone();

    if (response.actionId == LocalNotificationService.rejectAction) {
      // REJECT — tell server, clear pending, done
      await CallStatusService().updateCallStatus(
          channelId: channelId, status: 'reject_astro');
      await IncomingCallRouter.clear();
      return;
    }

    // ACCEPT or BODY TAP — persist with accept flag, then bring app forward.
    // handlePending() fires on resume and navigates directly to call screen.
    final isAccept = response.actionId == LocalNotificationService.acceptAction;
    await IncomingCallRouter.persist(payload, accept: isAccept);

    // If the app is already in foreground we can navigate immediately
    final nav = NavigationManager().navigatorKey.currentState;
    if (nav != null) {
      await IncomingCallRouter.handlePending();
    }
    // If app is in background/killed, handlePending() fires on resume
  } catch (e, st) {
    debugPrint('❌ onNotificationAction error: $e\n$st');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY PERMISSION CHANNEL
// ─────────────────────────────────────────────────────────────────────────────
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
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────
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

  // Prevent FCM from showing its own notification UI (we handle it ourselves)
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: false, badge: false, sound: false,
  );

  // Init local notifications in main isolate
  await LocalNotificationService.initialize(onNotificationAction);

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Init FCM token + background/killed notification tap handlers
  await NotificationService().initialize();

  // Foreground FCM — route via IncomingCallRouter
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

// ─────────────────────────────────────────────────────────────────────────────
// PERMISSION WRAPPER — requests permissions before app loads
// ─────────────────────────────────────────────────────────────────────────────
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
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.phone,
      Permission.bluetooth,
      Permission.bluetoothConnect,
    ].request();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}