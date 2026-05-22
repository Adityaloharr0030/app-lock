import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_apps/device_apps.dart';
import '../services/lock_manager.dart';

final lockManagerProvider = Provider((ref) => LockManager());

final installedAppsProvider = FutureProvider<List<Application>>((ref) async {
  return await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps: true,
    onlyAppsWithLaunchIntent: true,
  );
});

final lockedAppsProvider = StateNotifierProvider<LockedAppsNotifier, List<String>>((ref) {
  return LockedAppsNotifier(ref.watch(lockManagerProvider));
});

class LockedAppsNotifier extends StateNotifier<List<String>> {
  final LockManager _lockManager;
  LockedAppsNotifier(this._lockManager) : super([]) {
    loadLockedApps();
  }

  Future<void> loadLockedApps() async {
    state = await _lockManager.getLockedApps();
  }

  Future<void> toggleLock(String packageName) async {
    if (state.contains(packageName)) {
      await _lockManager.unlockApp(packageName);
      state = state.where((p) => p != packageName).toList();
    } else {
      await _lockManager.lockApp(packageName);
      state = [...state, packageName];
    }
  }
}
