import 'package:flutter/services.dart';

/// Native Android call-style ringtone + foreground service.
///
/// This plugin owns the *audio / vibration / foreground-service* side of an
/// incoming call, video, or chat-request push notification. It keeps
/// ringing reliably whether the app is in the foreground, backgrounded, or
/// fully killed — because it lives in a real Android [Service], not in a
/// Dart isolate that Android can (and does) tear down within seconds of
/// `firebaseMessagingBackgroundHandler()` returning.
///
/// It deliberately does NOT touch the visible notification (title, body,
/// Accept / Reject buttons) — that stays owned by
/// `flutter_local_notifications`, so the already-working accept/reject
/// dispatch (including its own background-isolate handling) keeps working
/// completely unmodified. This plugin only *attaches itself* — via
/// Android's `startForeground` contract — to the notification that is
/// already posted, using [notifId], so the user only ever sees one call
/// notification, never a duplicate.
///
/// Because this ships as a real Flutter plugin (not a one-off MethodChannel
/// wired only inside `MainActivity`), its native side is registered on
/// *every* FlutterEngine the app creates — including the headless
/// background engine `firebase_messaging` spins up to run
/// `firebaseMessagingBackgroundHandler` when a push arrives while the app
/// is backgrounded or killed. That is what makes it possible to reliably
/// start ringing from that background handler at all.
class AstroCallKit {
  AstroCallKit._();

  static const MethodChannel _channel = MethodChannel('astro_call_kit');

  /// Starts (or renews) native ringing + vibration for an incoming
  /// call/chat/video request, and promotes the app to a foreground service
  /// so Android cannot kill the ringing early.
  ///
  /// Safe to call multiple times — idempotent while already ringing.
  ///
  /// [notifId] MUST be the exact integer notification ID that
  /// `LocalNotificationService` used to post the visible call notification
  /// (see `LocalNotificationService._notifId`). Passing it lets the native
  /// service attach to that same notification instead of creating a
  /// second, duplicate one.
  static Future<void> startRinging({
    required String channelId,
    required int notifId,
    String title = 'Incoming Call',
    String body = 'is calling',
  }) async {
    try {
      await _channel.invokeMethod<void>('startRinging', {
        'channelId': channelId,
        'notifId': notifId,
        'title': title,
        'body': body,
      });
    } catch (_) {
      // Ringing is best-effort — never let a platform hiccup crash the
      // caller. The visible notification still shows either way.
    }
  }

  /// Stops native ringing/vibration and releases the foreground service.
  /// Safe to call even when nothing is currently ringing.
  static Future<void> stopRinging() async {
    try {
      await _channel.invokeMethod<void>('stopRinging');
    } catch (_) {}
  }

  /// True if the native service currently believes it is ringing.
  static Future<bool> isRinging() async {
    try {
      return await _channel.invokeMethod<bool>('isRinging') ?? false;
    } catch (_) {
      return false;
    }
  }
}
