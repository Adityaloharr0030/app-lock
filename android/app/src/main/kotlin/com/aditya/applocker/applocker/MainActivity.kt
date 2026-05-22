package com.aditya.applocker.applocker

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.hardware.fingerprint.FingerprintManager
import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.aditya.applocker/lock_service"
    private var methodChannel: MethodChannel? = null
    
    companion object {
        var pendingLockPackage: String? = null
        var pendingLockAppName: String? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLockService" -> {
                    startAppLockService()
                    result.success(true)
                }
                "stopLockService" -> {
                    stopAppLockService()
                    result.success(true)
                }
                "checkPendingLock" -> {
                    if (pendingLockPackage != null) {
                        val response = mapOf(
                            "packageName" to pendingLockPackage,
                            "appName" to pendingLockAppName
                        )
                        pendingLockPackage = null
                        pendingLockAppName = null
                        result.success(response)
                    } else {
                        result.success(null)
                    }
                }
                "openBiometricSettings" -> {
                    openBiometricSettings()
                    result.success(true)
                }
                "getBiometricCount" -> {
                    val count = getEnrolledFingerprintCount()
                    result.success(count)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == "SHOW_LOCK_SCREEN") {
            val packageName = intent.getStringExtra("lock_package") ?: ""
            val appName = intent.getStringExtra("lock_app_name") ?: ""
            if (packageName.isNotEmpty()) {
                pendingLockPackage = packageName
                pendingLockAppName = appName
                
                // Try sending immediately if Dart listener is active
                methodChannel?.invokeMethod("showLockScreen", mapOf(
                    "packageName" to packageName,
                    "appName" to appName
                ))
            }
        }
    }

    private fun startAppLockService() {
        val intent = Intent(this, AppLockService::class.java)
        startForegroundService(intent)
    }

    private fun stopAppLockService() {
        val intent = Intent(this, AppLockService::class.java)
        stopService(intent)
    }

    private fun openBiometricSettings() {
        try {
            // Try Android 9+ biometric enrollment
            val intent = Intent(Settings.ACTION_BIOMETRIC_ENROLL)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            try {
                // Fallback to fingerprint settings
                val intent = Intent(Settings.ACTION_FINGERPRINT_ENROLL)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e2: Exception) {
                // Final fallback to general security settings
                val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun getEnrolledFingerprintCount(): Int {
        return try {
            val fingerprintManager = getSystemService(Context.FINGERPRINT_SERVICE) as? FingerprintManager
            if (fingerprintManager != null && fingerprintManager.isHardwareDetected) {
                // FingerprintManager doesn't expose the count directly,
                // but we can check if any fingerprints are enrolled
                if (fingerprintManager.hasEnrolledFingerprints()) 1 else 0
            } else {
                0
            }
        } catch (e: Exception) {
            0
        }
    }
}

