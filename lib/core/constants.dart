import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Weather Alert';
  static const String pinKey = 'user_pin_hash';
  static const String authMethodKey = 'auth_method';
  static const String lockedAppsKey = 'locked_apps';
  static const String relockTimerKey = 'relock_timer';
  static const String intruderSelfieKey = 'intruder_selfie';
  static const String darkModeKey = 'dark_mode';
  static const String fingerLabelKey = 'finger_label';
  static const String biometricSetupCompleteKey = 'biometric_setup_complete';
  static const String autoTriggerBiometricKey = 'auto_trigger_biometric';
  
  static const List<int> timerOptions = [0, 5, 30, 60]; // seconds

  static const List<String> fingerLabels = [
    'Right Thumb',
    'Right Index Finger',
    'Right Middle Finger',
    'Left Thumb',
    'Left Index Finger',
    'Left Middle Finger',
    'Other Finger',
  ];
}

class AppColors {
  static const Color primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFF625B71);
  static const Color background = Color(0xFFFEF7FF);
  static const Color surface = Color(0xFFFEF7FF);
  static const Color error = Color(0xFFB3261E);

  // Fingerprint scanner colors
  static const Color scannerIdle = Color(0xFF7C4DFF);
  static const Color scannerScanning = Color(0xFF448AFF);
  static const Color scannerSuccess = Color(0xFF00E676);
  static const Color scannerFailure = Color(0xFFFF5252);
  static const Color scannerGlow = Color(0x40B388FF);
}
