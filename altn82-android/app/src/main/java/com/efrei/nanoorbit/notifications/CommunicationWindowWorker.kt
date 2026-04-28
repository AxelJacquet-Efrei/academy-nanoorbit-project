package com.efrei.nanoorbit.notifications

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.efrei.nanoorbit.data.repository.NanoOrbitRepository
import java.time.LocalDateTime
import java.util.concurrent.TimeUnit

class CommunicationWindowWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            NanoOrbitNotificationHelper.ensureChannel(applicationContext)

            val repository = NanoOrbitRepository(applicationContext)
            val fenetres = repository.refreshFenetres().data
            val satellites = repository.refreshSatellites().data.associateBy { it.idSatellite }
            val stations = repository.getStations().associateBy { it.codeStation }

            val preferences = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val notifiedIds = preferences.getStringSet(KEY_NOTIFIED_IDS, emptySet()).orEmpty()
                .mapNotNull { it.toIntOrNull() }
                .toSet()
            val newlyNotified = mutableSetOf<Int>()
            val now = LocalDateTime.now()

            fenetres
                .filter { isCommunicationWindowNotificationEligible(it, now, notifiedIds) }
                .forEach { fenetre ->
                    val satelliteName = satellites[fenetre.idSatellite]?.nomSatellite ?: fenetre.idSatellite
                    val stationName = stations[fenetre.codeStation]?.nomStation ?: fenetre.codeStation
                    val shown = NanoOrbitNotificationHelper.showPassageNotification(
                        context = applicationContext,
                        notificationId = fenetre.idFenetre,
                        satelliteName = satelliteName,
                        stationName = stationName,
                        durationSeconds = fenetre.duree
                    )
                    if (shown) {
                        newlyNotified += fenetre.idFenetre
                    }
                }

            if (newlyNotified.isNotEmpty()) {
                val updated = (notifiedIds + newlyNotified).map { it.toString() }.toSet()
                preferences.edit().putStringSet(KEY_NOTIFIED_IDS, updated).apply()
            }

            Log.d(TAG, "Checked ${fenetres.size} windows, notified ${newlyNotified.size}")
            Result.success()
        } catch (exception: Exception) {
            Log.w(TAG, "Notification worker will retry", exception)
            Result.retry()
        }
    }

    companion object {
        private const val TAG = "NanoOrbitNotifications"
        private const val PREFS_NAME = "nanoorbit_notifications"
        private const val KEY_NOTIFIED_IDS = "notified_window_ids"
        private const val UNIQUE_WORK_NAME = "nanoorbit-window-notifications"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<CommunicationWindowWorker>(
                15,
                TimeUnit.MINUTES
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                request
            )
            Log.d(TAG, "Scheduled notification worker")
        }
    }
}
