package com.astrologer.vaidikguru.astrocallkit

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Registers the "astro_call_kit" MethodChannel on EVERY FlutterEngine the
 * app creates — the main-isolate engine AND the headless background engine
 * that `firebase_messaging` spins up for background/killed push delivery.
 *
 * That's the whole point of shipping this as a real Flutter plugin instead
 * of a one-off MethodChannel wired only inside MainActivity: a channel set
 * up only in `MainActivity.configureFlutterEngine()` is invisible to the
 * headless background engine, so a "start ringing" call issued from
 * `firebaseMessagingBackgroundHandler` would silently go nowhere. Flutter's
 * plugin auto-registration (`GeneratedPluginRegistrant`) is what guarantees
 * this class gets attached to both.
 */
class AstroCallKitPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var appContext: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "astro_call_kit")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startRinging" -> {
                val channelId = call.argument<String>("channelId") ?: ""
                val notifId = call.argument<Int>("notifId") ?: -1
                val title = call.argument<String>("title") ?: "Incoming Call"
                val body = call.argument<String>("body") ?: "is calling"
                CallRingtoneService.start(appContext, channelId, notifId, title, body)
                result.success(null)
            }
            "stopRinging" -> {
                CallRingtoneService.stop(appContext)
                result.success(null)
            }
            "isRinging" -> result.success(CallRingtoneService.isRinging)
            else -> result.notImplemented()
        }
    }
}
