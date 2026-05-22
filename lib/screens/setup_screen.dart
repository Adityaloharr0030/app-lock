import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad.dart';
import '../services/auth_manager.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _pinSaved = false;
  final AuthMethod _selectedMethod = AuthMethod.pin;

  void _handlePinInput(String val) {
    if (_pinSaved) return; // Don't accept PIN input after save

    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += val);
        if (_confirmPin.length == 4) _verifyAndSave();
      }
    } else {
      if (_pin.length < 4) {
        setState(() => _pin += val);
        if (_pin.length == 4) {
          setState(() => _isConfirming = true);
        }
      }
    }
  }

  void _verifyAndSave() async {
    if (_pin == _confirmPin) {
      await ref.read(pinServiceProvider).savePin(_pin);
      await ref.read(authMethodProvider.notifier).setMethod(_selectedMethod);
      if (mounted) {
        setState(() => _pinSaved = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match! Start over.')),
      );
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_pinSaved) {
      // Show biometric enrollment option
      return Scaffold(
        appBar: AppBar(title: const Text('Configure Weather Widget')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'PIN Created!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Now set up a dedicated fingerprint for extra security.\n'
                  'Use a different finger than your phone unlock!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/biometric-setup?initial=true'),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Set up Fingerprint'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configure Weather Widget')),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            _isConfirming ? 'Confirm your 4-digit PIN' : 'Choose a 4-digit PIN',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final currentPin = _isConfirming ? _confirmPin : _pin;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < currentPin.length 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.outlineVariant,
                ),
              );
            }),
          ),
          const Spacer(),
          PinPad(
            onPinEntered: _handlePinInput,
            onBackspace: () {
              setState(() {
                if (_isConfirming) {
                  if (_confirmPin.isNotEmpty) {
                    _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
                  } else {
                    _isConfirming = false;
                  }
                } else {
                  if (_pin.isNotEmpty) {
                    _pin = _pin.substring(0, _pin.length - 1);
                  }
                }
              });
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

