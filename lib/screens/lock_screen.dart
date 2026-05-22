import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad.dart';
import '../widgets/fingerprint_scanner_widget.dart';
import '../services/auth_manager.dart';
import '../services/native_lock_service.dart';


class LockScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;

  const LockScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSeconds = 30;
  Timer? _lockoutTimer;

  // Biometric state
  ScannerState _scannerState = ScannerState.idle;
  String? _fingerLabel;
  bool _showBiometric = false;
  int _bioRetryCount = 0;
  static const int _maxBioRetries = 3;

  // View mode
  bool _showPinPad = false; // Hidden by default for stealth
  int _secretTapCount = 0;
  Timer? _secretTapTimer;

  @override
  void initState() {
    super.initState();
    NativeLockService.isLockScreenActive = true;
    _loadBiometricState();
  }

  @override
  void dispose() {
    NativeLockService.isLockScreenActive = false;
    _lockoutTimer?.cancel();
    _secretTapTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final authManager = ref.read(authManagerProvider);
    final method = await authManager.getSelectedAuthMethod();
    final fingerLabel = await authManager.getEnrolledFingerLabel();
    final autoTrigger = await authManager.getAutoTriggerBiometric();
    final biometricReady = await authManager.isBiometricSetupComplete();

    if (!mounted) return;

    final shouldShowBiometric = biometricReady &&
        (method == AuthMethod.biometric || method == AuthMethod.both);

    setState(() {
      _fingerLabel = fingerLabel;
      _showBiometric = shouldShowBiometric;
      // If biometric is not available, default to PIN (disguised)
      _showPinPad = !shouldShowBiometric;
    });

    if (shouldShowBiometric && autoTrigger) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _triggerBiometric();
      });
    }
  }

  Future<void> _triggerBiometric() async {
    if (_bioRetryCount >= _maxBioRetries) {
      setState(() {
        _showPinPad = true;
        _scannerState = ScannerState.idle;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification failed. Use manual sync.')),
      );
      return;
    }

    setState(() => _scannerState = ScannerState.scanning);

    final success = await ref.read(authManagerProvider).authenticate();

    if (!mounted) return;

    if (success) {
      setState(() => _scannerState = ScannerState.success);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _unlock();
    } else {
      _bioRetryCount++;
      setState(() => _scannerState = ScannerState.failure);

      if (_bioRetryCount < _maxBioRetries) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _scannerState = ScannerState.idle);
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showPinPad = true;
              _scannerState = ScannerState.idle;
            });
          }
        });
      }
    }
  }

  void _unlock() {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  void _handlePinInput(String val) async {
    if (_isLockedOut) return;

    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += val);
      if (_enteredPin.length == 4) {
        final success = await ref.read(pinServiceProvider).verifyPin(_enteredPin);
        if (!mounted) return;
        if (success) {
          _unlock();
        } else {
          _failedAttempts++;
          if (_failedAttempts >= 3) {
            _triggerLockout();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid sync code. Attempt $_failedAttempts/3')),
            );
            setState(() => _enteredPin = '');
          }
        }
      }
    }
  }

  void _triggerLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutSeconds = 30;
      _enteredPin = '';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _failedAttempts = 0;
        });
      } else {
        setState(() => _lockoutSeconds--);
      }
    });
  }

  void _handleSecretTap() {
    _secretTapTimer?.cancel();
    setState(() {
      _secretTapCount++;
    });

    if (_secretTapCount >= 5) {
      setState(() {
        _showPinPad = true;
        _secretTapCount = 0;
      });
    } else {
      _secretTapTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _secretTapCount = 0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E2640),
                const Color(0xFF111625),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),

                // Disguised Weather Widget Header
                GestureDetector(
                  onTap: _handleSecretTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 56,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Weather Widget Alert',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Connection lost. Authentication required to refresh service widgets and verify permissions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lockout Warning (styled subtly as a system notice)
                if (_isLockedOut) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Security Lockout: Try again in $_lockoutSeconds s',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Verification Content: Biometric Scanner or PIN Pad
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _showPinPad
                      ? _buildPinPadView(colorScheme)
                      : _buildBiometricView(),
                ),

                const SizedBox(height: 16),

                // Disguised manual sync trigger (reveals PIN)
                if (!_showPinPad)
                  TextButton.icon(
                    onPressed: () => setState(() => _showPinPad = true),
                    icon: const Icon(Icons.sync, size: 16, color: Colors.white38),
                    label: const Text(
                      'Manual Sync Options',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),

                // Switch back to biometric if shown
                if (_showPinPad && _showBiometric)
                  TextButton.icon(
                    onPressed: () => setState(() => _showPinPad = false),
                    icon: const Icon(Icons.fingerprint, size: 16, color: Colors.blueAccent),
                    label: const Text(
                      'Use Biometrics',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinPadView(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('lock_pin_pad'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < _enteredPin.length ? Colors.blue.shade400 : Colors.white24,
            ),
          )),
        ),
        const SizedBox(height: 24),
        PinPad(
          onPinEntered: _handlePinInput,
          onBackspace: () {
            if (_enteredPin.isNotEmpty) {
              setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
            }
          },
          onForgotPin: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please contact administrator or reinstall widget.')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBiometricView() {
    return Column(
      key: const ValueKey('lock_biometric'),
      mainAxisSize: MainAxisSize.min,
      children: [
        FingerprintScannerWidget(
          onTap: _triggerBiometric,
          state: _scannerState,
          fingerLabel: _fingerLabel,
          size: 110,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
