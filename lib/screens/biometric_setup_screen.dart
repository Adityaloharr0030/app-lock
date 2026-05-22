import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_enrollment_service.dart';
import '../services/auth_manager.dart';
import '../widgets/fingerprint_scanner_widget.dart';

final biometricEnrollmentProvider = Provider((ref) => BiometricEnrollmentService());

class BiometricSetupScreen extends ConsumerStatefulWidget {
  /// If true, navigates to /home after completion. If false, just pops.
  final bool isInitialSetup;

  const BiometricSetupScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  int _currentStep = 0;
  String? _selectedFingerLabel;
  bool _isVerifying = false;
  ScannerState _scannerState = ScannerState.idle;
  bool _deviceSupported = true;
  int _preEnrollCount = 0;

  @override
  void initState() {
    super.initState();
    _checkDeviceSupport();
  }

  Future<void> _checkDeviceSupport() async {
    final service = ref.read(biometricEnrollmentProvider);
    final supported = await service.isDeviceSupported();
    final count = await service.getEnrolledBiometricCount();
    if (mounted) {
      setState(() {
        _deviceSupported = supported;
        _preEnrollCount = count;
      });
    }
  }

  Future<void> _openSystemSettings() async {
    final service = ref.read(biometricEnrollmentProvider);
    await service.openSystemBiometricSettings();
    // After returning from settings, check if a new fingerprint was added
    final newCount = await service.getEnrolledBiometricCount();
    if (mounted && newCount > _preEnrollCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New fingerprint detected! ✓'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _preEnrollCount = newCount);
    }
  }

  Future<void> _verifyAndComplete() async {
    if (_selectedFingerLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select which finger you enrolled')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _scannerState = ScannerState.scanning;
    });

    final service = ref.read(biometricEnrollmentProvider);
    final success = await service.verifyBiometric(
      reason: 'Verify your ${_selectedFingerLabel!} for Weather Widget',
    );

    if (!mounted) return;

    if (success) {
      setState(() => _scannerState = ScannerState.success);

      // Save everything
      await service.setFingerLabel(_selectedFingerLabel!);
      await service.markSetupComplete();
      await ref.read(authManagerProvider).setFingerLabel(_selectedFingerLabel!);
      await ref.read(authManagerProvider).markBiometricSetupComplete();
      await ref.read(authMethodProvider.notifier).setMethod(AuthMethod.biometric);

      // Wait for success animation then navigate
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      if (widget.isInitialSetup) {
        context.go('/home');
      } else {
        context.pop();
      }
    } else {
      setState(() {
        _scannerState = ScannerState.failure;
        _isVerifying = false;
      });

      // Reset to idle after failure animation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _scannerState = ScannerState.idle);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerprint Setup'),
        leading: widget.isInitialSetup
            ? TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip'),
              )
            : null,
      ),
      body: !_deviceSupported
          ? _buildUnsupportedView(context)
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (_currentStep < 2)
                        FilledButton(
                          onPressed: details.onStepContinue,
                          child: Text(_currentStep == 1 ? 'Next' : 'Continue'),
                        ),
                      if (_currentStep == 2)
                        FilledButton.icon(
                          onPressed: _isVerifying ? null : _verifyAndComplete,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(_isVerifying ? 'Verifying...' : 'Verify & Save'),
                        ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Explanation
                Step(
                  title: const Text('Dedicate a Finger'),
                  subtitle: const Text('Choose a finger just for Weather Widget sync'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primaryContainer,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Why a separate finger?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'By using a different finger than your phone unlock, '
                              'even someone who borrows your unlocked phone can\'t '
                              'refresh widget settings — they won\'t know which finger to use!',
                              style: TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: _openSystemSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Fingerprint Settings'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a new fingerprint in your phone settings if you haven\'t already.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 2: Select finger
                Step(
                  title: const Text('Label Your Finger'),
                  subtitle: const Text('Which finger did you enroll?'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.fingerLabels.map((label) {
                          final isSelected = _selectedFingerLabel == label;
                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFingerLabel = selected ? label : null;
                              });
                            },
                            selectedColor: colorScheme.primaryContainer,
                            avatar: isSelected
                                ? Icon(Icons.check, size: 18, color: colorScheme.primary)
                                : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Step 3: Verify
                Step(
                  title: const Text('Verify'),
                  subtitle: Text(
                    _selectedFingerLabel != null
                        ? 'Test your ${_selectedFingerLabel!}'
                        : 'Confirm your finger works',
                  ),
                  isActive: _currentStep >= 2,
                  state: _scannerState == ScannerState.success
                      ? StepState.complete
                      : StepState.indexed,
                  content: Column(
                    children: [
                      const SizedBox(height: 16),
                      FingerprintScannerWidget(
                        onTap: _verifyAndComplete,
                        state: _scannerState,
                        fingerLabel: _selectedFingerLabel,
                        size: 100,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 1 && _selectedFingerLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a finger label first')),
      );
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Widget _buildUnsupportedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Biometrics Not Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your device doesn\'t support biometric authentication. '
              'Please use PIN-only mode.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (widget.isInitialSetup) {
                  context.go('/home');
                } else {
                  context.pop();
                }
              },
              child: const Text('Continue with PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
