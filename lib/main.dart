import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:astrologer_app/service/notificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data             = message.data;
  final notificationType = data['notification_type'];

  if (notificationType == 'initiate') {
    await LocalNotificationService.showIncomingCall(
      title  : data['title'] ?? 'Incoming Call',
      body   : '${data['user_name'] ?? 'Someone'} is calling you',
      payload: data.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

final callStatusService = CallStatusService();

void onNotificationAction(NotificationResponse response) async {
  final payload   = _parsePayload(response.payload);
  final channelId = payload['channel_id'];
  final type      = payload['type'];

  if (channelId == null || channelId.isEmpty) return;

  final prefs  = await SharedPreferences.getInstance();
  final astroId = prefs.getString('astro_id') ?? '';

  switch (response.actionId) {
    case LocalNotificationService.acceptAction:
      await callStatusService.updateCallStatus(
        channelId: channelId,
        status   : 'accept_astro',
      );
      if (type == 'chat') {
        NavigationManager().openChatScreen(
          channelId : channelId,
          astroId   : astroId,
          userId    : payload['user_id']!,
          userName  : payload['user_name']!,
          userAvatar: payload['user_image']!,
        );
      }
      if (type == 'audio') {
        NavigationManager().showIncomingAudioCall(
          token     : payload['agora_token'] ?? '',
          channelId : channelId,
          userName  : payload['user_name']!,
          userAvatar: payload['user_image']!,
        );
      }
      if (type == 'video') {
        NavigationManager().showIncomingVideoCall(
          token     : payload['agora_token'] ?? '',
          channelId : channelId,
          userName  : payload['user_name']!,
          userAvatar: payload['user_image']!,
        );
      }
      break;

    case LocalNotificationService.rejectAction:
      await callStatusService.updateCallStatus(
        channelId: channelId,
        status   : 'reject_astro',
      );
      break;
  }
}

Map<String, String> _parsePayload(String? payload) {
  if (payload == null) return {};
  return Map.fromEntries(
    payload.split('&').map((e) {
      final parts = e.split('=');
      return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
    }),
  );
}

// ─── Permission helper ────────────────────────────────────────────────────────

/// Requests camera, microphone, notification and phone-state permissions.
/// Shows a settings-redirect dialog if any critical permission is permanently
/// denied (camera or mic) — the app cannot make calls without them.
Future<void> _requestPermissions(BuildContext context) async {
  // Request all at once
  final statuses = await [
    Permission.camera,
    Permission.microphone,
    Permission.notification,
    Permission.phone,          // needed for audio call integration
    Permission.bluetooth,      // needed for BT headsets on some Android builds
    Permission.bluetoothConnect,
  ].request();

  final camDenied  = statuses[Permission.camera]     == PermissionStatus.permanentlyDenied;
  final micDenied  = statuses[Permission.microphone] == PermissionStatus.permanentlyDenied;

  if ((camDenied || micDenied) && context.mounted) {
    await showDialog<void>(
      context            : context,
      barrierDismissible : false,
      builder: (ctx) => AlertDialog(
        title  : const Text('Permissions Required'),
        content: const Text(
          'Camera and microphone access are required for audio and video calls.\n\n'
          'Please enable them in Settings → App permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child    : const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

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

  await LocalNotificationService.initialize(onNotificationAction);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioCallProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
         ChangeNotifierProvider(create: (_) => VideoCallProvider()),
      ],
      builder: (context, child) => _PermissionWrapper(child: const MyApp())
    ),
  );
}

// ─── Thin wrapper that requests permissions after the first frame ─────────────
// Using a wrapper widget (instead of requesting in main()) lets us show a
// proper dialog with a BuildContext and avoids blocking app startup.

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
    // Request after first frame so MaterialApp / Navigator are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}