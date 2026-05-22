import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../core/constants.dart';

/// Manages the custom fingerprint enrollment flow.
/// 
/// Since Android doesn't allow apps to register fingerprints directly,
/// this service guides the user to enroll a specific finger in system settings
/// and tracks which finger they designated for AppLocker use.
class BiometricEnrollmentService {
  static const _channel = MethodChannel('com.aditya.applocker/lock_service');
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Opens the Android system biometric/fingerprint enrollment settings.
  Future<bool> openSystemBiometricSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openBiometricSettings');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to open biometric settings: ${e.message}');
      return false;
    }
  }

  /// Gets the number of currently enrolled biometrics on the device.
  Future<int> getEnrolledBiometricCount() async {
    try {
      final count = await _channel.invokeMethod<int>('getBiometricCount');
      return count ?? 0;
    } on PlatformException catch (e) {
      debugPrint('Failed to get biometric count: ${e.message}');
      return 0;
    }
  }

  /// Gets available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Checks if the device supports biometrics at all.
  Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Verifies biometric authentication with the user.
  /// Returns true if the user successfully authenticates.
  Future<bool> verifyBiometric({String reason = 'Verify your designated finger'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric verification error: $e');
      return false;
    }
  }

  /// Saves the label of the finger the user designated for AppLocker.
  Future<void> setFingerLabel(String label) async {
    await _storage.write(key: AppConstants.fingerLabelKey, value: label);
  }

  /// Gets the saved finger label, or null if not set.
  Future<String?> getFingerLabel() async {
    return await _storage.read(key: AppConstants.fingerLabelKey);
  }

  /// Marks the biometric setup as complete.
  Future<void> markSetupComplete() async {
    await _storage.write(
      key: AppConstants.biometricSetupCompleteKey, 
      value: 'true',
    );
  }

  /// Checks if the biometric setup flow has been completed.
  Future<bool> isSetupComplete() async {
    final value = await _storage.read(key: AppConstants.biometricSetupCompleteKey);
    return value == 'true';
  }

  /// Resets the biometric setup (for re-enrollment).
  Future<void> resetSetup() async {
    await _storage.delete(key: AppConstants.biometricSetupCompleteKey);
    await _storage.delete(key: AppConstants.fingerLabelKey);
  }
}
