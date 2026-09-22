# astro_call_kit

Android-only local Flutter plugin. It exists to fix one specific thing:
**the incoming-call ringtone did not play when the app was backgrounded or
killed.**

## Why this needs native code at all

`firebaseMessagingBackgroundHandler()` (in `lib/main.dart`) runs in a
headless Flutter engine that Android tears down within seconds of the
handler returning. Anything that handler starts in Dart — like the old
`FlutterRingtonePlayer().playRingtone()` call — dies with that engine.

## Why it's a real Flutter plugin instead of a MethodChannel in MainActivity

A `MethodChannel` set up only inside `MainActivity.configureFlutterEngine()`
is invisible to the headless background engine `firebase_messaging` spins
up. Shipping this as a proper (local, `path:`-referenced) plugin is what
makes its channel available from `firebaseMessagingBackgroundHandler`, from
the notification's Accept/Reject background-response isolate, and from the
normal foreground isolate — same Dart API in all three.

## How the ringtone is played (and two dead ends that came before it)

`RingtonePlayer` plays the phone's **default ringtone** through
`android.media.Ringtone`. That class tries a local `MediaPlayer` first and,
when that throws `SecurityException`/`IOException`, delegates playback to
the system's remote `IRingtonePlayer` (`AudioManager.getRingtonePlayer()`),
which runs in the **system audio process** and can read the user's ringtone.
This is how the Phone app rings without holding storage permissions.

Two consequences worth knowing:

1. No media/storage permission is ever needed.
2. The audio does not come from this app's process, so ringing does not
   depend on our process priority — and if our process is killed, the
   system stops the sound via its binder death recipient, so a ringtone can
   never get stuck playing forever.

Silent/DND behaves like a normal incoming call, because the system player
applies the ringer mode itself.

### Dead end 1: MediaPlayer directly

Playing the ringtone URI with `MediaPlayer.setDataSource()` opens it **as
this app**, which failed in the field:

```
SecurityException: com.astrologer.vaidikguru has no access to
content://media/external/audio/media/1000058470
```

The user's chosen ringtone was their own media file. Using
`content://settings/system/ringtone` instead did not help — the same
resolution happens underneath. `Ringtone` is the fix, not a different URI.

### Dead end 2: a foreground service

An earlier version ran the ringtone inside a foreground `Service`
(`CallRingtoneService`). It crashed the app:

```
RemoteServiceException$ForegroundServiceDidNotStartInTimeException:
Context.startForegroundService() did not then call Service.startForeground()
```

A foreground service promises Android it will call `startForeground()`
within seconds, and Android kills the process when that promise breaks.
Keeping it reliably meant fighting Android 14+ service-type gating
(`phoneCall` requires the dialer role or `MANAGE_OWN_CALLS`), notification
ownership (the service must own a notification, colliding with the one
`flutter_local_notifications` already posts), and start/stop races when a
call is answered immediately. Since the audio lives in the system process,
none of that was ever needed — the service is gone, and so is that entire
class of crashes.

## What it does / doesn't own

- **Owns:** the ringtone (system default, looping), continuous vibration, a
  45-second auto-stop, and a bundled fallback tone
  (`res/raw/astro_ringtone.ogg`) used only if the system ringtone cannot be
  played at all.
- **Does NOT own:** the visible call notification. That stays entirely with
  `flutter_local_notifications`, including its Accept/Reject dispatch —
  untouched, still working in every app state.

## Dart API (`lib/astro_call_kit.dart`)

```dart
await AstroCallKit.startRinging(channelId: channelId, notifId: notifId);
await AstroCallKit.stopRinging();
final ringing = await AstroCallKit.isRinging();
```

`notifId`, `title` and `body` are still accepted so the Dart API didn't have
to change, but are no longer used natively (there's no notification or
service to attach to any more).

In this app every call site goes through
`lib/service/localNotificationService.dart`'s `playRingtone()` /
`stopRingtone()` / `forceStopRingtone()` — nothing else should call this
plugin directly.

## Debugging

Everything logs under the tag `AstroCallKit`:

```
adb logcat -s AstroCallKit
```

You should see `startRinging(channelId=…)` followed by
`system ringtone playing via content://…` when a call arrives.
