import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isRingtonePlaying = false;
  static const String acceptAction = 'ACCEPT_CALL';
  static const String rejectAction = 'REJECT_CALL';

  static Future<void> initialize(
    void Function(NotificationResponse) onAction,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse          : onAction,
      onDidReceiveBackgroundNotificationResponse: onAction,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'astro_incoming_call',
            'Incoming Calls',
            description    : 'Incoming call & chat from users',
            importance     : Importance.max,
            playSound      : false,
            enableVibration: false,
            showBadge      : false,
          ),
        );
  }

  static Future<void> showIncomingCall({
    required String              title,
    required String              body,
    required Map<String, String> payload,
  }) async {
    final payloadStr = payload.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    // ✅ Play ringtone when call arrives
    _isRingtonePlaying = true;
    FlutterRingtonePlayer().playRingtone(looping: true, volume: 1.0, asAlarm: false);

    final androidDetails = AndroidNotificationDetails(
      'astro_incoming_call',
      'Incoming Calls',
      channelDescription: 'Incoming call & chat from users',
      importance        : Importance.max,
      priority          : Priority.high,
      fullScreenIntent  : true,
      visibility        : NotificationVisibility.public,
      category          : AndroidNotificationCategory.call,
      ongoing           : true,
      autoCancel        : false,
      timeoutAfter      : 45000,
      playSound         : false,
      enableVibration   : false,
      silent            : true,
      actions           : const [
        AndroidNotificationAction(
          acceptAction,
          'Accept ✅',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          rejectAction,
          'Reject ❌',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      (payload['channel_id'] ?? 'call').hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payloadStr,
    );
  }

  // ✅ Stop ringtone when call is cancelled/accepted/rejected
  static Future<void> cancelCall(String channelId) async {
    FlutterRingtonePlayer().stop();
    await _plugin.cancel(channelId.hashCode);
  }

  static Future<void> cancelAll() async {
    FlutterRingtonePlayer().stop();
    await _plugin.cancelAll();
  }
static Future<void> stopRingtone() async {
  // ✅ Always call stop — don't rely on _isRingtonePlaying flag
  // The flag can be false if ringtone was started in a background isolate
  await FlutterRingtonePlayer().stop();
  _isRingtonePlaying = false;
}

  // ✅ Centralized play — call from IncomingCallScreen only
  static Future<void> playRingtone() async {
    if (!_isRingtonePlaying) {
      _isRingtonePlaying = true;
      await FlutterRingtonePlayer().playRingtone(
        looping: true,
        volume : 1.0,
        asAlarm: false,
      );
    }
  }

  static Future<Map<String, String>?> launchPayload() async {
  final details = await _plugin.getNotificationAppLaunchDetails();
  if (details?.didNotificationLaunchApp != true) return null;
  final p = details?.notificationResponse?.payload;
  if (p == null || p.isEmpty) return null;
  return decodePayload(p);
}

static Map<String, String> decodePayload(String raw) {
  final map = <String, String>{};
  for (final part in raw.split('&')) {
    final i = part.indexOf('=');
    if (i <= 0) continue;
    map[part.substring(0, i)] = Uri.decodeComponent(part.substring(i + 1));
  }
  return map;
}
}