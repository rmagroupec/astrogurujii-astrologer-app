package com.astrologer.vaidikguru.astrocallkit

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground service that owns the ringtone + vibration for an incoming
 * call/chat/video request, and keeps them going independently of the
 * Dart/Flutter engine.
 *
 * That independence is the entire point: Dart's FCM background isolate is
 * torn down within seconds of `firebaseMessagingBackgroundHandler()`
 * returning, so anything it started there (the old
 * `FlutterRingtonePlayer` call) died with it — which is exactly why the
 * ringtone never used to play when the app was backgrounded or killed. A
 * real Android [Service] has no such lifetime limit; once started with
 * `startForegroundService`, it keeps running (and ringing) until it is
 * explicitly stopped or the ring timeout fires, regardless of what happens
 * to any Flutter engine.
 *
 * This service never builds its own *visible* call notification — on the
 * normal path it looks up the one `flutter_local_notifications` already
 * posted (same [Intent] extra `notifId`) and "adopts" it via
 * `startForeground()`, so there is exactly one call notification on
 * screen, with its existing Accept/Reject buttons untouched. It only
 * builds a minimal fallback notification if that lookup fails, purely to
 * satisfy Android's "call startForeground() within a few seconds" contract
 * for a phoneCall-type foreground service.
 */
class CallRingtoneService : Service() {

    companion object {
        private const val FALLBACK_CHANNEL_ID = "astro_incoming_call_service"
        private const val FALLBACK_CHANNEL_NAME = "Incoming Calls"
        private const val RING_TIMEOUT_MS = 45_000L
        private const val FALLBACK_NOTIF_ID = 999_001

        private const val ACTION_START = "com.astrologer.vaidikguru.astrocallkit.action.START"
        private const val ACTION_STOP = "com.astrologer.vaidikguru.astrocallkit.action.STOP"

        @Volatile
        var isRinging: Boolean = false
            private set

        /** Starts (or renews) native ringing. [channelId] is only used for
         * logging/extras today but is passed through in case a future
         * change needs to disambiguate concurrent calls. */
        fun start(context: Context, channelId: String, notifId: Int, title: String, body: String) {
            val intent = Intent(context, CallRingtoneService::class.java).apply {
                action = ACTION_START
                putExtra("channelId", channelId)
                putExtra("notifId", notifId)
                putExtra("title", title)
                putExtra("body", body)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Exception) {
                // Extremely defensive — e.g. an OEM background-start
                // restriction slipping through. Nothing more we can do
                // from here; the visible notification (already posted by
                // flutter_local_notifications) still shows.
            }
        }

        fun stop(context: Context) {
            // Deliberately a plain startService(), never startForegroundService():
            // the STOP branch in onStartCommand() never calls startForeground(),
            // so forcing the foreground-service contract here would risk an
            // ANR/crash on a call where nothing was ringing to begin with.
            // When the service IS already running as a foreground service
            // (the normal case — stop() is always called moments after our
            // own ring started), that existing foreground state is exemption
            // enough for the app to message its own service.
            val intent = Intent(context, CallRingtoneService::class.java).apply {
                action = ACTION_STOP
            }
            try {
                context.startService(intent)
            } catch (_: Exception) {
                // Service is probably already gone — nothing to stop.
            }
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private val timeoutHandler = Handler(Looper.getMainLooper())
    private var timeoutRunnable: Runnable? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopRingingInternal()
                stopSelf()
            }
            else -> {
                val channelId = intent?.getStringExtra("channelId") ?: ""
                val notifId = intent?.getIntExtra("notifId", -1) ?: -1
                val title = intent?.getStringExtra("title") ?: "Incoming Call"
                val body = intent?.getStringExtra("body") ?: "is calling"
                beginRinging(channelId, notifId, title, body)
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopRingingInternal()
        super.onDestroy()
    }

    // ── Start ────────────────────────────────────────────────────────────
    private fun beginRinging(channelId: String, notifId: Int, title: String, body: String) {
        promoteToForeground(notifId, title, body)

        if (isRinging) {
            // Already ringing (e.g. IncomingCallScreen re-confirmed after
            // the app resumed into the foreground) — the foreground
            // notification above was refreshed; leave the ringtone/
            // vibration/timeout that are already running alone so there's
            // no audible restart glitch.
            return
        }

        isRinging = true
        acquireWakeLock()
        startRingtone()
        startVibration()
        scheduleTimeout()
    }

    private fun promoteToForeground(notifId: Int, title: String, body: String) {
        val id = if (notifId > 0) notifId else FALLBACK_NOTIF_ID
        val notification = adoptedOrFallbackNotification(notifId, title, body)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceCompat.startForeground(
                    this,
                    id,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL,
                )
            } else {
                startForeground(id, notification)
            }
        } catch (_: Exception) {
            try {
                startForeground(id, notification)
            } catch (_: Exception) {
                // If even this fails the OS is refusing foreground starts
                // outright (rare OEM lockdown) — ringtone/vibration below
                // still run for as long as the process stays alive.
            }
        }
    }

    /** Reuses the notification flutter_local_notifications already posted
     * at [notifId] (same title/body/Accept/Reject buttons) so the user
     * never sees a second, duplicate call notification. Falls back to a
     * minimal notification built here only if that lookup fails. */
    private fun adoptedOrFallbackNotification(
        notifId: Int,
        title: String,
        body: String,
    ): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notifId > 0) {
            try {
                val nm = getSystemService(NotificationManager::class.java)
                val existing = nm?.activeNotifications?.firstOrNull { it.id == notifId }
                if (existing != null) return existing.notification
            } catch (_: Exception) {
                // fall through to the minimal notification below
            }
        }
        return buildFallbackNotification(title, body)
    }

    private fun buildFallbackNotification(title: String, body: String): Notification {
        createFallbackChannelIfNeeded()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        return NotificationCompat.Builder(this, FALLBACK_CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentIntent)
            .build()
    }

    private fun createFallbackChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java) ?: return
            if (nm.getNotificationChannel(FALLBACK_CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    FALLBACK_CHANNEL_ID,
                    FALLBACK_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Fallback incoming call notification"
                    // The ringtone/vibration are handled by this service
                    // directly — the channel itself stays silent so
                    // Android never plays a second, competing sound.
                    setSound(null, null)
                    enableVibration(false)
                }
                nm.createNotificationChannel(channel)
            }
        }
    }

    // ── Ringtone ─────────────────────────────────────────────────────────
    private fun startRingtone() {
        try {
            val uri = RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: return

            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(attributes)
                setDataSource(this@CallRingtoneService, uri)
                isLooping = true
                setOnErrorListener { _, _, _ -> true } // swallow — never crash the ring
                prepare()
                start()
            }

            requestAudioFocus(attributes)
        } catch (_: Exception) {
            // Never let a missing/broken ringtone crash the service —
            // vibration + the visible notification still work.
        }
    }

    private fun requestAudioFocus(attributes: AudioAttributes) {
        try {
            audioManager = getSystemService(AUDIO_SERVICE) as? AudioManager
            val am = audioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(attributes)
                    .setOnAudioFocusChangeListener { /* a ringing call always wins */ }
                    .build()
                audioFocusRequest = request
                am.requestAudioFocus(request)
            } else {
                @Suppress("DEPRECATION")
                am.requestAudioFocus(
                    { /* ignored */ },
                    AudioManager.STREAM_RING,
                    AudioManager.AUDIOFOCUS_GAIN,
                )
            }
        } catch (_: Exception) {
        }
    }

    private fun abandonAudioFocus() {
        try {
            val am = audioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                am.abandonAudioFocus { }
            }
        } catch (_: Exception) {
        }
        audioFocusRequest = null
        audioManager = null
    }

    // ── Vibration ────────────────────────────────────────────────────────
    private fun startVibration() {
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                (getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(VIBRATOR_SERVICE) as Vibrator
            }
            // Mirrors a real incoming call: buzz, pause, buzz, pause, buzz,
            // long pause, repeat — index 0 means "repeat the whole array".
            val pattern = longArrayOf(0, 1000, 500, 1000, 500, 1000, 1500)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {
        }
    }

    // ── Wake lock ────────────────────────────────────────────────────────
    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "astro_call_kit:ring_wake_lock",
            ).apply { acquire(RING_TIMEOUT_MS + 5_000L) }
        } catch (_: Exception) {
        }
    }

    // ── Timeout — missed-call safety net ────────────────────────────────
    // If nothing ever calls stopRinging() (app force-killed mid-ring,
    // notification action broadcast lost, etc.) this guarantees the phone
    // stops ringing on its own after RING_TIMEOUT_MS, matching the 45s
    // `timeoutAfter` already used on the Dart-side notification.
    private fun scheduleTimeout() {
        val runnable = Runnable {
            stopRingingInternal()
            stopSelf()
        }
        timeoutRunnable = runnable
        timeoutHandler.postDelayed(runnable, RING_TIMEOUT_MS)
    }

    // ── Stop everything ──────────────────────────────────────────────────
    private fun stopRingingInternal() {
        isRinging = false

        timeoutRunnable?.let { timeoutHandler.removeCallbacks(it) }
        timeoutRunnable = null

        try { mediaPlayer?.stop() } catch (_: Exception) {}
        try { mediaPlayer?.release() } catch (_: Exception) {}
        mediaPlayer = null
        abandonAudioFocus()

        try { vibrator?.cancel() } catch (_: Exception) {}
        vibrator = null

        try { if (wakeLock?.isHeld == true) wakeLock?.release() } catch (_: Exception) {}
        wakeLock = null

        try {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        } catch (_: Exception) {
            @Suppress("DEPRECATION")
            try { stopForeground(true) } catch (_: Exception) {}
        }
    }
}
