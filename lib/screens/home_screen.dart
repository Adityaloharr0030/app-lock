import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../providers/app_list_provider.dart';
import '../widgets/app_tile.dart';
import '../services/native_lock_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initMonitor();
  }

  Future<void> _initMonitor() async {
    // Request usage stats permission if not granted
    try {
      bool? isGranted = await UsageStats.checkUsagePermission();
      if (isGranted != true) {
        await UsageStats.grantUsagePermission();
      }
      
      // Request overlay permission
      if (!await FlutterForegroundTask.canDrawOverlays) {
        await FlutterForegroundTask.openSystemAlertWindowSettings();
      }
      
      // Request battery optimization
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (e) {
      debugPrint("Permission error: $e");
    }

    // Start native background service
    await NativeLockService.startService();
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final lockedApps = ref.watch(lockedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Widget Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: appsAsync.when(
        data: (apps) {
          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final isLocked = lockedApps.contains(app.packageName);
              return AppTile(
                app: app,
                isLocked: isLocked,
                onToggle: (val) => ref.read(lockedAppsProvider.notifier).toggleLock(app.packageName),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
