package com.astrologer.vaidikguru.astrocallkit

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Plays the incoming-call ringtone + vibration.
 *
 * ─────────────────────────────────────────────────────────────────────────
 * WHY THERE IS NO FOREGROUND SERVICE HERE ANYMORE
 * ─────────────────────────────────────────────────────────────────────────
 * The previous version used a foreground Service (CallRingtoneService).
 * It crashed the app in the field with:
 *
 *   RemoteServiceException$ForegroundServiceDidNotStartInTimeException:
 *   Context.startForegroundService() did not then call
 *   Service.startForeground()
 *
 * A foreground service makes a hard promise to Android that it will call
 * startForeground() within a few seconds, and Android kills the whole
 * process when that promise is broken. Meeting that promise reliably means
 * fighting three separate moving targets — Android 14+ foreground service
 * TYPE restrictions, notification ownership (the service must own a
 * notification, which collided with the one flutter_local_notifications
 * already posts), and start/stop lifecycle races when a call is answered
 * within milliseconds of ringing.
 *
 * None of that complexity buys anything here, because of how Android
 * actually plays ringtones (see below): the audio does NOT come from our
 * process, so our process does not need elevated priority to keep it
 * playing. So the foreground service is gone, and with it that entire
 * class of crashes.
 *
 * ─────────────────────────────────────────────────────────────────────────
 * WHY Ringtone AND NOT MediaPlayer
 * ─────────────────────────────────────────────────────────────────────────
 * The previous version played the ringtone with MediaPlayer.setDataSource()
 * and failed in the field with:
 *
 *   SecurityException: com.astrologer.vaidikguru has no access to
 *   content://media/external/audio/media/1000058470
 *
 * MediaPlayer opens the ringtone URI *as this app*. When the user's chosen
 * ringtone is their own media file, this app has no permission to read it
 * — and asking for broad media/storage permission just to ring would be
 * the wrong fix.
 *
 * android.media.Ringtone does the right thing instead: it tries a local
 * MediaPlayer first and, when that throws SecurityException/IOException,
 * it delegates playback to the system's remote IRingtonePlayer
 * (AudioManager.getRingtonePlayer()), which runs in the system audio
 * process and CAN read the user's ringtone. That is exactly how the Phone
 * app plays your ringtone without holding storage permissions.
 *
 * Two useful consequences of the audio living in the system process:
 *   1. No storage/media permission is ever needed.
 *   2. Playback is not tied to our process priority, so a plain call from
 *      any Dart isolate keeps ringing after that isolate is torn down.
 *      (If our process is killed outright, the system stops the sound via
 *      its binder death recipient — so a ringtone can never get stuck on.)
 *
 * Silent/DND is respected the way a normal incoming call is, because the
 * system player applies the ringer mode itself.
 */
object RingtonePlayer {

    private const val TAG = "AstroCallKit"

    /** Hard cap so the phone can never ring forever if nothing stops it. */
    private const val RING_TIMEOUT_MS = 45_000L

    /** Re-check interval for the pre-Android-9 manual looping fallback. */
    private const val LEGACY_LOOP_CHECK_MS = 400L

    @Volatile
    var isRinging: Boolean = false
        private set

    private val handler = Handler(Looper.getMainLooper())

    private var ringtone: Ringtone? = null
    private var fallbackPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var legacyFocusListener: AudioManager.OnAudioFocusChangeListener? = null

    private var timeoutRunnable: Runnable? = null
    private var legacyLoopRunnable: Runnable? = null

    private val ringAttributes: AudioAttributes by lazy {
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    /**
     * Starts ringing + vibrating. Idempotent: calling it again while
     * already ringing does nothing, so the incoming-call screen
     * re-confirming on resume never restarts the sound.
     */
    @Synchronized
    fun start(context: Context) {
        if (isRinging) {
            Log.d(TAG, "start() ignored — already ringing")
            return
        }
        isRinging = true

        val playing = startSystemRingtone(context) || startBundledFallback(context)
        Log.d(TAG, "start() ringing=$playing")

        startVibration(context)
        scheduleTimeout()
    }

    /** Stops ringing + vibrating. Safe to call any number of times. */
    @Synchronized
    fun stop() {
        Log.d(TAG, "stop() called (wasRinging=$isRinging)")
        isRinging = false

        timeoutRunnable?.let { handler.removeCallbacks(it) }
        timeoutRunnable = null
        legacyLoopRunnable?.let { handler.removeCallbacks(it) }
        legacyLoopRunnable = null

        try { ringtone?.stop() } catch (t: Throwable) { Log.w(TAG, "ringtone.stop failed", t) }
        ringtone = null

        try { fallbackPlayer?.stop() } catch (_: Throwable) {}
        try { fallbackPlayer?.release() } catch (_: Throwable) {}
        fallbackPlayer = null

        abandonAudioFocus()

        try { vibrator?.cancel() } catch (t: Throwable) { Log.w(TAG, "vibrator.cancel failed", t) }
        vibrator = null
    }

    // ── System (device default) ringtone ─────────────────────────────────
    /**
     * Plays the phone's default ringtone — whatever the user has set under
     * Settings > Sound > Phone ringtone — via [Ringtone], so the system
     * process opens the file and no permission is needed.
     */
    private fun startSystemRingtone(context: Context): Boolean {
        for (uri in defaultRingtoneUris(context)) {
            try {
                val r = RingtoneManager.getRingtone(context, uri)
                if (r == null) {
                    Log.w(TAG, "getRingtone returned null for $uri")
                    continue
                }
                r.audioAttributes = ringAttributes
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    r.isLooping = true
                }
                r.play()
                ringtone = r
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                    scheduleLegacyLoop()
                }
                Log.d(TAG, "system ringtone playing via $uri")
                return true
            } catch (t: Throwable) {
                // Ringtone handles the SecurityException case internally by
                // delegating to the system player, so reaching here means
                // something more unusual went wrong — try the next URI.
                Log.w(TAG, "system ringtone failed for $uri", t)
            }
        }
        return false
    }

    private fun defaultRingtoneUris(context: Context): List<Uri> {
        val uris = ArrayList<Uri>(2)
        try {
            RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE)
                ?.let { uris.add(it) }
        } catch (t: Throwable) {
            Log.w(TAG, "getActualDefaultRingtoneUri failed", t)
        }
        try {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?.let { if (!uris.contains(it)) uris.add(it) }
        } catch (t: Throwable) {
            Log.w(TAG, "getDefaultUri failed", t)
        }
        return uris
    }

    /**
     * Ringtone.setLooping() only exists on Android 9+. Below that, re-start
     * playback whenever it finishes, until stop() is called.
     */
    private fun scheduleLegacyLoop() {
        val runnable = object : Runnable {
            override fun run() {
                if (!isRinging) return
                val r = ringtone ?: return
                try {
                    if (!r.isPlaying) r.play()
                } catch (t: Throwable) {
                    Log.w(TAG, "legacy loop re-play failed", t)
                    return
                }
                handler.postDelayed(this, LEGACY_LOOP_CHECK_MS)
            }
        }
        legacyLoopRunnable = runnable
        handler.postDelayed(runnable, LEGACY_LOOP_CHECK_MS)
    }

    // ── Bundled fallback tone ────────────────────────────────────────────
    /**
     * Last-resort ringtone bundled with the app (res/raw/astro_ringtone.ogg).
     * Only used if the system ringtone could not be played at all — this
     * one needs no URI, no ContentResolver and no permission, so the phone
     * always makes a sound for an incoming call.
     *
     * Note this deliberately does NOT run when the ringer is simply
     * silent/DND: in that case the system player above succeeds and
     * correctly stays quiet.
     */
    private fun startBundledFallback(context: Context): Boolean {
        return try {
            val afd = context.resources.openRawResourceFd(R.raw.astro_ringtone)
                ?: return false
            val mp = MediaPlayer()
            mp.setAudioAttributes(ringAttributes)
            afd.use { mp.setDataSource(it.fileDescriptor, it.startOffset, it.length) }
            mp.isLooping = true
            mp.setOnErrorListener { _, what, extra ->
                Log.w(TAG, "fallback player error what=$what extra=$extra")
                true
            }
            mp.prepare()
            mp.start()
            fallbackPlayer = mp
            requestAudioFocus(context)
            Log.d(TAG, "bundled fallback ringtone playing")
            true
        } catch (t: Throwable) {
            Log.w(TAG, "bundled fallback ringtone failed", t)
            try { fallbackPlayer?.release() } catch (_: Throwable) {}
            fallbackPlayer = null
            false
        }
    }

    // ── Audio focus (only needed for the in-process fallback player) ─────
    private fun requestAudioFocus(context: Context) {
        try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
            audioManager = am
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(ringAttributes)
                    .setOnAudioFocusChangeListener { /* a ringing call always wins */ }
                    .build()
                audioFocusRequest = request
                am.requestAudioFocus(request)
            } else {
                val listener = AudioManager.OnAudioFocusChangeListener { }
                legacyFocusListener = listener
                @Suppress("DEPRECATION")
                am.requestAudioFocus(
                    listener,
                    AudioManager.STREAM_RING,
                    AudioManager.AUDIOFOCUS_GAIN,
                )
            }
        } catch (t: Throwable) {
            Log.w(TAG, "requestAudioFocus failed", t)
        }
    }

    private fun abandonAudioFocus() {
        try {
            val am = audioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            } else {
                legacyFocusListener?.let {
                    @Suppress("DEPRECATION")
                    am.abandonAudioFocus(it)
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "abandonAudioFocus failed", t)
        }
        audioFocusRequest = null
        legacyFocusListener = null
        audioManager = null
    }

    // ── Vibration ────────────────────────────────────────────────────────
    private fun startVibration(context: Context) {
        try {
            val v = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager)
                    .defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            // Mirrors a real incoming call: buzz, pause, buzz, pause, buzz,
            // long pause — index 0 repeats the whole pattern.
            val pattern = longArrayOf(0, 1000, 500, 1000, 500, 1000, 1500)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(pattern, 0)
            }
            vibrator = v
        } catch (t: Throwable) {
            Log.w(TAG, "startVibration failed", t)
        }
    }

    // ── Timeout ──────────────────────────────────────────────────────────
    private fun scheduleTimeout() {
        val runnable = Runnable {
            Log.d(TAG, "ring timeout reached — stopping")
            stop()
        }
        timeoutRunnable = runnable
        handler.postDelayed(runnable, RING_TIMEOUT_MS)
    }
}
