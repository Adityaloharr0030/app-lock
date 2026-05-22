import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class PinService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> savePin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: AppConstants.pinKey, value: hash);
  }

  Future<bool> verifyPin(String enteredPin) async {
    try {
      final savedHash = await _storage.read(key: AppConstants.pinKey);
      if (savedHash == null) return false;
      return savedHash == _hashPin(enteredPin);
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return false;
    }
  }

  Future<void> clearPin() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<bool> isPinSet() async {
    try {
      final savedHash = await _storage.read(key: AppConstants.pinKey);
      return savedHash != null;
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return false;
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
