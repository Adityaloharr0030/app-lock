package com.aditya.applocker.applocker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class AppLockService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences
    private var lastForegroundPackage = ""

    private val monitorRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, 500)
        }
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        startForeground(1, buildNotification())
        handler.post(monitorRunnable)
        Log.d("AppLockService", "Service started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(monitorRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun checkForegroundApp() {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 2000 // last 2 seconds

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = android.app.usage.UsageEvents.Event()
        var latestPackage = ""
        var latestTime = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                if (event.timeStamp > latestTime) {
                    latestTime = event.timeStamp
                    latestPackage = event.packageName
                }
            }
        }

        if (latestPackage.isEmpty() || latestPackage == packageName) return
        if (latestPackage == lastForegroundPackage) return

        // Read locked apps from shared preferences (Flutter stores with "flutter." prefix)
        val lockedAppsJson = prefs.getString("flutter.locked_apps", null) ?: return
        // Flutter stores StringList as JSON array: ["pkg1","pkg2"]
        val lockedApps = parseStringList(lockedAppsJson)

        Log.d("AppLockService", "Foreground: $latestPackage, Locked: $lockedApps")

        if (lockedApps.contains(latestPackage)) {
            Log.d("AppLockService", "LOCKED APP DETECTED: $latestPackage")
            lastForegroundPackage = latestPackage
            showLockScreen(latestPackage)
        } else {
            lastForegroundPackage = latestPackage
        }
    }

    private fun parseStringList(json: String): List<String> {
        // Parse Flutter's SharedPreferences StringList format: ["pkg1","pkg2",...]
        return try {
            json.trim()
                .removePrefix("[")
                .removeSuffix("]")
                .split(",")
                .map { it.trim().removeSurrounding("\"") }
                .filter { it.isNotEmpty() }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun showLockScreen(packageName: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("lock_package", packageName)
            putExtra("lock_app_name", getAppName(packageName))
            action = "SHOW_LOCK_SCREEN"
        }
        startActivity(intent)
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun buildNotification(): Notification {
        val channelId = "app_lock_service"
        val channelName = "AppLocker Service"
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_LOW
        )
        manager.createNotificationChannel(channel)

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("AppLocker Active")
            .setContentText("Protecting your selected apps")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
