// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     // 1. Request Permissions
//     await _fcm.requestPermission(alert: true, badge: true, sound: true);

//     // 2. Setup Local Notifications for Foreground Alerts
//     const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
//     await _localNotifications.initialize(initSettings);

//     // 3. Listen for Foreground Messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showLocalNotification(message);
//     });

//     // 4. Handle Background/Terminated state actions
//     FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
//   }

//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'chat_channel', 'Chat Notifications',
//       importance: Importance.max, priority: Priority.high,
//     );
//     const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

//     await _localNotifications.show(
//       message.hashCode,
//       message.notification?.title,
//       message.notification?.body,
//       platformDetails,
//     );
//   }
// }

// // Global top-level function for background execution
// @pragma('vm:entry-point')
// Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
//   // Logic to handle specific data payloads like "end_chat"
//   if (message.data['action'] == 'end_chat') {
//     // Clean up local resources if needed
//   }
// }