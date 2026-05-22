import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class NativeLockService {
  static const _channel = MethodChannel('com.aditya.applocker/lock_service');

  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startLockService');
      debugPrint('Native lock service started successfully');
    } on PlatformException catch (e) {
      debugPrint('Failed to start native lock service: ${e.message}');
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopLockService');
      debugPrint('Native lock service stopped successfully');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop native lock service: ${e.message}');
    }
  }

  static void registerLockListener(GoRouter router) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'showLockScreen') {
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        final String packageName = args['packageName'] as String;
        final String appName = args['appName'] as String;
        
        debugPrint('Navigating to lock screen for $packageName ($appName)');
        router.push('/lock/$packageName/$appName');
      }
    });

    // Handle any pending lock screen from launch/new intent
    _checkPendingLock(router);
  }

  static Future<void> _checkPendingLock(GoRouter router) async {
    try {
      final Map<dynamic, dynamic>? pending = 
          await _channel.invokeMethod<Map<dynamic, dynamic>>('checkPendingLock');
      if (pending != null) {
        final String packageName = pending['packageName'] as String;
        final String appName = pending['appName'] as String;
        debugPrint('Found pending lock screen for $packageName ($appName)');
        router.push('/lock/$packageName/$appName');
      }
    } catch (e) {
      debugPrint('Error checking pending lock: $e');
    }
  }
}
