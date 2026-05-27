import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:astrologer_app/features/service/service/navigationManager.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:astrologer_app/service/localNotificationService.dart';
import 'package:astrologer_app/service/notificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  print('📩 BG MESSAGE: $data');

  final type = data['type']; // chat | audio | video
  final notificationType = data['notification_type']; // initiate

  if (notificationType == 'initiate') {
    await LocalNotificationService.showIncomingCall(
      title: data['title'] ?? 'Incoming Call',
      body: '${data['user_name'] ?? 'Someone'} is calling you',
      payload: data.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

final callStatusService = CallStatusService();

void onNotificationAction(NotificationResponse response) async {
  final payload = _parsePayload(response.payload);
  print('🔔 ACTION PAYLOAD: $payload');

  final channelId = payload['channel_id'];
  final type = payload['type']; // chat | audio | video

  if (channelId == null || channelId.isEmpty) {
    print('❌ channel_id missing');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final astroId = prefs.getString('astro_id') ?? '';

  switch (response.actionId) {
    case LocalNotificationService.acceptAction:
      print('✅ ACCEPT CLICKED');

      await callStatusService.updateCallStatus(
        channelId: channelId,
        status: 'accept_astro',
      );

      /// 🚦 ROUTE BY TYPE
      if (type == 'chat') {
        NavigationManager().openChatScreen(
          channelId: channelId,
          astroId: astroId,
          userId: payload['user_id']!,
          userName: payload['user_name']!,
          userAvatar: payload['user_image']!,
        );
      }

      if (type == 'audio') {
        NavigationManager().showIncomingAudioCall(
          token: payload['fb_channel_id']!,
          channelId: channelId,
          userName: payload['user_name']!,
          userAvatar: payload['user_image']!,
        );
      }

      if (type == 'video') {
        NavigationManager().showIncomingVideoCall(
          token: payload['fb_channel_id']!,
          channelId: channelId,
          userName: payload['user_name']!,
          userAvatar: payload['user_image']!,
        );
      }
      break;

    case LocalNotificationService.rejectAction:
      print('❌ REJECT CLICKED');

      await callStatusService.updateCallStatus(
        channelId: channelId,
        status: 'reject_astro',
      );
      break;
  }
}

// final callStatusService = CallStatusService();
// void onNotificationAction(NotificationResponse response) async {
//   final payload = _parsePayload(response.payload);
//   print(payload);
//   final channelId = payload['channel_id'];
//   final prefs = await SharedPreferences.getInstance(); 
//   if (channelId == null || channelId.isEmpty) {
//     print('❌ channel_id missing');
//     return;
//   }

//   switch (response.actionId) {
//     case LocalNotificationService.acceptAction:
//       print('✅ ACCEPT CLICKED');

//       // 🔁 UPDATE BACKEND
//       await callStatusService.updateCallStatus(
//         channelId: channelId,
//         status: 'accept_astro',
//       );

//       // 🧭 OPEN CALL SCREEN
//       NavigationManager().openChatScreen(
//         channelId: channelId,
//         astroId: prefs.getString('astro_id') ?? ''  ,
//         userId: payload['user_id']!,
//         userName: payload['user_name']!,
//         userAvatar: payload['user_image']!,
//       );
//       break;

//     case LocalNotificationService.rejectAction:
//       print('❌ REJECT CLICKED');
//       await callStatusService.updateCallStatus(
//         channelId: channelId,
//         status: 'reject_astro',
//       );
//       // 🔁 UPDATE BACKEND

//       break;
//   }
// }

Map<String, String> _parsePayload(String? payload) {
  if (payload == null) return {};
  return Map.fromEntries(
    payload.split('&').map((e) {
      final parts = e.split('=');
      return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
    }),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

 await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "AIzaSyDMOLSzOQbwUsaSg2576yb92UmNMxuf3Xc",
    appId: "1:307653017355:android:bc17f957ae29d29bc8ec0e", // Change if using different package
    messagingSenderId: "307653017355",
    projectId: "astrogurujii-production",
    storageBucket: "astrogurujii-production.firebasestorage.app",
    databaseURL: "https://astrogurujii-production-default-rtdb.firebaseio.com",
  ),
);
  await LocalNotificationService.initialize(onNotificationAction);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service ONCE
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
