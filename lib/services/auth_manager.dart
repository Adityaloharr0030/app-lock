import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

enum AuthMethod { pin, biometric, both }

class AuthManager {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- Auth Method ---

  Future<AuthMethod> getSelectedAuthMethod() async {
    try {
      final methodStr = await _storage.read(key: AppConstants.authMethodKey);
      if (methodStr == null) return AuthMethod.pin;
      return AuthMethod.values.firstWhere(
        (e) => e.toString() == methodStr,
        orElse: () => AuthMethod.pin,
      );
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return AuthMethod.pin;
    }
  }

  Future<void> setAuthMethod(AuthMethod method) async {
    try {
      await _storage.write(key: AppConstants.authMethodKey, value: method.toString());
    } catch (_) {}
  }

  // --- Finger Label ---

  Future<String?> getEnrolledFingerLabel() async {
    try {
      return await _storage.read(key: AppConstants.fingerLabelKey);
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<void> setFingerLabel(String label) async {
    try {
      await _storage.write(key: AppConstants.fingerLabelKey, value: label);
    } catch (_) {}
  }

  // --- Biometric Setup State ---

  Future<bool> isBiometricSetupComplete() async {
    try {
      final value = await _storage.read(key: AppConstants.biometricSetupCompleteKey);
      return value == 'true';
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return false;
    }
  }

  Future<void> markBiometricSetupComplete() async {
    try {
      await _storage.write(key: AppConstants.biometricSetupCompleteKey, value: 'true');
    } catch (_) {}
  }

  Future<void> resetBiometricSetup() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  // --- Auto-trigger preference ---

  Future<bool> getAutoTriggerBiometric() async {
    try {
      final value = await _storage.read(key: AppConstants.autoTriggerBiometricKey);
      return value != 'false'; // Default true
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return true;
    }
  }

  Future<void> setAutoTriggerBiometric(bool enabled) async {
    try {
      await _storage.write(
        key: AppConstants.autoTriggerBiometricKey, 
        value: enabled.toString(),
      );
    } catch (_) {}
  }

  // --- Authentication ---

  Future<bool> authenticate() async {
    final method = await getSelectedAuthMethod();
    
    switch (method) {
      case AuthMethod.pin:
        // PIN authentication is handled by the UI (LockScreen)
        return false; 
      case AuthMethod.biometric:
        return await _authenticateBiometric();
      case AuthMethod.both:
        final bioResult = await _authenticateBiometric();
        return bioResult; // If bio fails, UI will fall back to PIN
    }
  }

  Future<bool> _authenticateBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheck || !isSupported) return false;

      final fingerLabel = await getEnrolledFingerLabel();
      final reason = fingerLabel != null 
          ? 'Place your $fingerLabel to refresh Weather Widget'
          : 'Verify fingerprint to refresh Weather Widget';

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> canUseBiometrics() async {
    return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
  }

  Future<List<BiometricType>> getAvailableBiometricTypes() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
}

