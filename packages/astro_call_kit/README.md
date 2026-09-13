# astro_call_kit

Android-only local Flutter plugin. It exists to fix one specific, previously
broken thing: **the incoming-call ringtone never played when the app was
backgrounded or fully killed.**

## Why this needed native code

`firebaseMessagingBackgroundHandler()` (in `lib/main.dart`) runs in a
headless Flutter engine that Android tears down within a few seconds of the
handler returning. Anything that handler starts — like the old
`FlutterRingtonePlayer().playRingtone()` call — dies with that engine. A
real Android `Service` has no such limit: once started with
`startForegroundService()`, it keeps running (and ringing) completely
independently of any Flutter engine, until it's explicitly stopped or its
own safety-net timeout fires.

## Why it's a real Flutter plugin instead of a MethodChannel in MainActivity

A `MethodChannel` set up only inside `MainActivity.configureFlutterEngine()`
is invisible to the headless background engine `firebase_messaging` spins
up — that engine only gets the channels that `GeneratedPluginRegistrant`
attaches to it, which is exactly the pub-plugin registration mechanism.
Shipping this as a proper (if local, `path:`-referenced) Flutter plugin is
what makes `astro_call_kit`'s channel available from
`firebaseMessagingBackgroundHandler`, from the notification's
Accept/Reject background-response isolate, and from the normal
foreground/main isolate — with the exact same Dart API in all three.

## What it does / doesn't own

- **Owns:** the ringtone (native `MediaPlayer` + `AudioAttributes` looping
  the device's default ringtone), continuous vibration, audio focus, a
  wake lock, and a 45s missed-call safety-net timeout.
- **Does NOT own:** the visible call notification. `startRinging()` adopts
  the notification `flutter_local_notifications` already posted (matched
  by the same integer notification ID) via `startForeground()`, so there
  is exactly one notification with its existing Accept/Reject dispatch —
  unchanged, untouched, still fully working in every app state.

## Dart API (`lib/astro_call_kit.dart`)

```dart
await AstroCallKit.startRinging(
  channelId: channelId,
  notifId  : notifId,   // must match LocalNotificationService's notifId
  title    : title,
  body     : body,
);

await AstroCallKit.stopRinging();

final ringing = await AstroCallKit.isRinging();
```

In this app, all three call sites go through
`lib/service/localNotificationService.dart`'s `playRingtone()` /
`stopRingtone()` / `forceStopRingtone()` — nothing else needs to call this
plugin directly.
