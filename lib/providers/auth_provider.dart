import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_manager.dart';
import '../services/pin_service.dart';
import '../services/biometric_enrollment_service.dart';

final pinServiceProvider = Provider((ref) => PinService());
final authManagerProvider = Provider((ref) => AuthManager());
final biometricEnrollmentServiceProvider = Provider((ref) => BiometricEnrollmentService());

final authMethodProvider = StateNotifierProvider<AuthMethodNotifier, AuthMethod>((ref) {
  return AuthMethodNotifier(ref.watch(authManagerProvider));
});

class AuthMethodNotifier extends StateNotifier<AuthMethod> {
  final AuthManager _authManager;
  AuthMethodNotifier(this._authManager) : super(AuthMethod.pin) {
    loadMethod();
  }

  Future<void> loadMethod() async {
    state = await _authManager.getSelectedAuthMethod();
  }

  Future<void> setMethod(AuthMethod method) async {
    await _authManager.setAuthMethod(method);
    state = method;
  }
}

