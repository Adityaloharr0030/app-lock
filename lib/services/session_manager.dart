import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SessionManager {
  final Map<String, DateTime> _unlockedApps = {};
  
  Future<bool> shouldLock(String packageName) async {
    if (!_unlockedApps.containsKey(packageName)) return true;
    
    final prefs = await SharedPreferences.getInstance();
    final timerSeconds = prefs.getInt(AppConstants.relockTimerKey) ?? 0;
    
    if (timerSeconds == 0) return true; // Lock immediately
    
    final unlockedAt = _unlockedApps[packageName]!;
    final now = DateTime.now();
    
    if (now.difference(unlockedAt).inSeconds > timerSeconds) {
      _unlockedApps.remove(packageName);
      return true;
    }
    
    return false;
  }

  void markAsUnlocked(String packageName) {
    _unlockedApps[packageName] = DateTime.now();
  }

  void lockAll() {
    _unlockedApps.clear();
  }
}
