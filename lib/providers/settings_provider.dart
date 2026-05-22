import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final int relockTimer;
  final bool intruderSelfie;
  final bool darkMode;

  SettingsState({
    required this.relockTimer,
    required this.intruderSelfie,
    required this.darkMode,
  });

  SettingsState copyWith({
    int? relockTimer,
    bool? intruderSelfie,
    bool? darkMode,
  }) {
    return SettingsState(
      relockTimer: relockTimer ?? this.relockTimer,
      intruderSelfie: intruderSelfie ?? this.intruderSelfie,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(relockTimer: 0, intruderSelfie: false, darkMode: false)) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      relockTimer: prefs.getInt(AppConstants.relockTimerKey) ?? 0,
      intruderSelfie: prefs.getBool(AppConstants.intruderSelfieKey) ?? false,
      darkMode: prefs.getBool(AppConstants.darkModeKey) ?? false,
    );
  }

  Future<void> setRelockTimer(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.relockTimerKey, seconds);
    state = state.copyWith(relockTimer: seconds);
  }

  Future<void> setIntruderSelfie(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.intruderSelfieKey, enabled);
    state = state.copyWith(intruderSelfie: enabled);
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.darkModeKey, enabled);
    state = state.copyWith(darkMode: enabled);
  }
}
