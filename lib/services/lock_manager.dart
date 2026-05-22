import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class LockManager {
  static const String _key = AppConstants.lockedAppsKey;

  Future<List<String>> getLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> lockApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final locked = await getLockedApps();
    if (!locked.contains(packageName)) {
      locked.add(packageName);
      await prefs.setStringList(_key, locked);
    }
  }

  Future<void> unlockApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final locked = await getLockedApps();
    if (locked.contains(packageName)) {
      locked.remove(packageName);
      await prefs.setStringList(_key, locked);
    }
  }

  Future<bool> isLocked(String packageName) async {
    final locked = await getLockedApps();
    return locked.contains(packageName);
  }
}
