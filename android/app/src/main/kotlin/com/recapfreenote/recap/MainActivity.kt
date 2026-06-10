package com.recapfreenote.recap

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val backgroundRecorderChannel =
        "com.recapfreenote.recap/background_recorder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Native ASR bridge — Android on-device SpeechRecognizer for live
        // captions when available (Android 13+ with on-device support).
        AndroidAsrBridge(applicationContext, flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backgroundRecorderChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForeground" -> {
                    val title = call.argument<String>("title") ?: "Recording…"
                    val text = call.argument<String>("notificationText")
                        ?: "Tap to return to Recap"
                    val svc = Intent(this, RecordingService::class.java).apply {
                        action = RecordingService.ACTION_START
                        putExtra(RecordingService.EXTRA_TITLE, title)
                        putExtra(RecordingService.EXTRA_TEXT, text)
                    }
                    if (android.os.Build.VERSION.SDK_INT >=
                        android.os.Build.VERSION_CODES.O
                    ) {
                        startForegroundService(svc)
                    } else {
                        startService(svc)
                    }
                    result.success(null)
                }
                "stopForeground" -> {
                    val svc = Intent(this, RecordingService::class.java).apply {
                        action = RecordingService.ACTION_STOP
                    }
                    startService(svc)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
