import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import '../core/constants.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AppMonitorHandler());
}

class AppMonitorHandler extends TaskHandler {
  List<String> _lockedApps = [];
  String? _lastApp;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    final prefs = await SharedPreferences.getInstance();
    _lockedApps = prefs.getStringList(AppConstants.lockedAppsKey) ?? [];
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Refresh locked apps list on each check
    final prefs = await SharedPreferences.getInstance();
    _lockedApps = prefs.getStringList(AppConstants.lockedAppsKey) ?? [];

    if (_lockedApps.isEmpty) return;

    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(seconds: 10));
    try {
      final events = await UsageStats.queryEvents(startDate, endDate);
      events.sort((a, b) => int.parse(b.timeStamp!).compareTo(int.parse(a.timeStamp!)));
      
      for (var event in events) {
        if (event.eventType == '1') {
          final foregroundPackage = event.packageName!;
          if (_lockedApps.contains(foregroundPackage) && foregroundPackage != _lastApp) {
            _lastApp = foregroundPackage;
            sendPort?.send(foregroundPackage);
          } else if (foregroundPackage != _lastApp) {
            _lastApp = foregroundPackage;
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('Error checking usage stats: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup
  }
}

class AppMonitorService {
  static Future<void> initService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'weather_sync_channel',
        channelName: 'Weather Sync Service',
        channelDescription: 'Synchronizes weather alerts and widgets',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 500,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Weather Service Active',
        notificationText: 'Monitoring local weather alerts',
        callback: startCallback,
      );
    }
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}
