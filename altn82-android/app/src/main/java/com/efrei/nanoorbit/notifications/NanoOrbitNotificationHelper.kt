package com.efrei.nanoorbit.notifications

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.efrei.nanoorbit.MainActivity
import com.efrei.nanoorbit.R
import com.efrei.nanoorbit.ui.navigation.Routes

object NanoOrbitNotificationHelper {
    const val CHANNEL_ID = "nanoorbit_passages"
    private const val CHANNEL_NAME = "Passages NanoOrbit"
    private const val CHANNEL_DESCRIPTION = "Alertes avant les fenetres de communication planifiees"
    private const val TEST_NOTIFICATION_ID = 900_001

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = CHANNEL_DESCRIPTION
        }

        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    fun hasNotificationPermission(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    fun showPassageNotification(
        context: Context,
        notificationId: Int,
        satelliteName: String,
        stationName: String,
        durationSeconds: Int
    ): Boolean {
        return showNotification(
            context = context,
            notificationId = notificationId,
            title = "Passage imminent",
            body = "$satelliteName avec $stationName dans 15 min - ${durationSeconds}s"
        )
    }

    fun showTestNotification(context: Context): Boolean {
        return showNotification(
            context = context,
            notificationId = TEST_NOTIFICATION_ID,
            title = "Passage imminent",
            body = "SAT-001 avec GS-KIR-01 dans 15 min - 420s"
        )
    }

    @SuppressLint("MissingPermission")
    private fun showNotification(
        context: Context,
        notificationId: Int,
        title: String,
        body: String
    ): Boolean {
        ensureChannel(context)
        if (!hasNotificationPermission(context)) return false

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(planningPendingIntent(context))
            .build()

        return runCatching {
            NotificationManagerCompat.from(context).notify(notificationId, notification)
        }.isSuccess
    }

    private fun planningPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_START_ROUTE, Routes.Planning)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
