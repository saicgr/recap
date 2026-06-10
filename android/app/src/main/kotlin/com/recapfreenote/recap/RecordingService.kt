package com.recapfreenote.recap

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that keeps recording alive when the app is backgrounded
 * or the screen is locked. Started from MainActivity via the
 * `com.recapfreenote.recap/background_recorder` MethodChannel.
 *
 * Posts a persistent notification with FOREGROUND_SERVICE_TYPE_MICROPHONE so
 * Android keeps our process running while we hold the mic.
 */
class RecordingService : Service() {

    companion object {
        const val NOTIFICATION_ID = 1042
        const val CHANNEL_ID = "recap.recording"
        const val CHANNEL_NAME = "Recording"

        const val ACTION_START = "com.recapfreenote.recap.START_RECORDING"
        const val ACTION_STOP = "com.recapfreenote.recap.STOP_RECORDING"
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startInForeground(
                intent.getStringExtra(EXTRA_TITLE) ?: "Recording…",
                intent.getStringExtra(EXTRA_TEXT) ?: "Tap to return to Recap"
            )
            ACTION_STOP -> stopForegroundCompat()
        }
        return START_STICKY
    }

    private fun startInForeground(title: String, text: String) {
        ensureChannel()
        val pi = openAppIntent()
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pi)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return
        val ch = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Persistent notification while Recap is recording."
            setShowBadge(false)
        }
        mgr.createNotificationChannel(ch)
    }

    private fun openAppIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, 0, intent, flags)
    }
}
