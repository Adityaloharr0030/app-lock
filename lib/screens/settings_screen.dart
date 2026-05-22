import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_manager.dart';
import '../services/biometric_enrollment_service.dart';
import '../core/constants.dart';

final _biometricServiceProvider = Provider((ref) => BiometricEnrollmentService());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _fingerLabel;
  bool _biometricSetup = false;
  bool _autoTrigger = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricInfo();
  }

  Future<void> _loadBiometricInfo() async {
    final authManager = ref.read(authManagerProvider);
    final label = await authManager.getEnrolledFingerLabel();
    final setupDone = await authManager.isBiometricSetupComplete();
    final autoTrig = await authManager.getAutoTriggerBiometric();

    if (mounted) {
      setState(() {
        _fingerLabel = label;
        _biometricSetup = setupDone;
        _autoTrigger = autoTrig;
      });
    }
  }

  Future<void> _testBiometric() async {
    final service = ref.read(_biometricServiceProvider);
    final success = await service.verifyBiometric(
      reason: 'Testing your designated fingerprint',
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Fingerprint verified! ✓' : 'Verification failed ✗'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    final settings = ref.watch(settingsProvider);
    final authMethod = ref.watch(authMethodProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // --- Biometric Finger Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'BIOMETRIC SECURITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Biometric finger card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.fingerprint, color: colorScheme.primary),
                  ),
                  title: Text(
                    _biometricSetup ? 'Designated Finger' : 'Set Up Fingerprint',
                  ),
                  subtitle: Text(
                    _biometricSetup
                        ? _fingerLabel ?? 'Finger enrolled'
                        : 'No dedicated finger set up yet',
                  ),
                  trailing: _biometricSetup
                      ? Icon(Icons.check_circle, color: Colors.green.shade400)
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push('/biometric-setup');
                    _loadBiometricInfo(); // Refresh after returning
                  },
                ),
                if (_biometricSetup) ...[
                  const Divider(height: 0),
                  ListTile(
                    leading: const SizedBox(width: 40),
                    title: const Text('Change Finger'),
                    trailing: const Icon(Icons.swap_horiz),
                    onTap: () async {
                      // Reset and re-enroll
                      final router = GoRouter.of(context);
                      await ref.read(authManagerProvider).resetBiometricSetup();
                      await _loadBiometricInfo();
                      router.push('/biometric-setup');
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const SizedBox(width: 40),
                    title: const Text('Test Fingerprint'),
                    trailing: const Icon(Icons.play_arrow_outlined),
                    onTap: _testBiometric,
                  ),
                ],
              ],
            ),
          ),

          if (_biometricSetup) ...[
            SwitchListTile(
              title: const Text('Auto-trigger on Lock Screen'),
              subtitle: const Text('Automatically prompt for fingerprint'),
              value: _autoTrigger,
              onChanged: (val) async {
                await ref.read(authManagerProvider).setAutoTriggerBiometric(val);
                setState(() => _autoTrigger = val);
              },
            ),
          ],

          const Divider(height: 32),

          // --- Authentication Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'AUTHENTICATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),

          ListTile(
            title: const Text('Authentication Method'),
            subtitle: Text(authMethod.toString().split('.').last.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAuthMethodDialog(context, ref),
          ),

          const Divider(height: 32),

          // --- General Settings ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'GENERAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),

          ListTile(
            title: const Text('Re-lock Timer'),
            subtitle: Text(settings.relockTimer == 0 ? 'Immediately' : '${settings.relockTimer} seconds'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimerDialog(context, ref),
          ),
          SwitchListTile(
            title: const Text('Intruder Selfie'),
            subtitle: const Text('Take photo on wrong attempt'),
            value: settings.intruderSelfie,
            onChanged: (val) => ref.read(settingsProvider.notifier).setIntruderSelfie(val),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.darkMode,
            onChanged: (val) => ref.read(settingsProvider.notifier).setDarkMode(val),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.red),
            title: const Text('Change PIN', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Implementation for changing PIN
            },
          ),
        ],
      ),
    );
  }

  void _showAuthMethodDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Auth Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AuthMethod.values.map((m) {
            final label = m.toString().split('.').last.toUpperCase();
            final isSelected = ref.read(authMethodProvider) == m;
            return ListTile(
              leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              title: Text(label),
              subtitle: _getAuthMethodDescription(m),
              onTap: () {
                if (m != AuthMethod.pin && !_biometricSetup) {
                  // Need biometric setup first
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please set up your fingerprint first'),
                    ),
                  );
                  context.push('/biometric-setup');
                  return;
                }
                ref.read(authMethodProvider.notifier).setMethod(m);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget? _getAuthMethodDescription(AuthMethod method) {
    switch (method) {
      case AuthMethod.pin:
        return const Text('4-digit PIN only', style: TextStyle(fontSize: 12));
      case AuthMethod.biometric:
        return const Text('Fingerprint only', style: TextStyle(fontSize: 12));
      case AuthMethod.both:
        return const Text('Fingerprint with PIN fallback', style: TextStyle(fontSize: 12));
    }
  }

  void _showTimerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Re-lock Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.timerOptions.map((t) => ListTile(
            title: Text(t == 0 ? 'Immediately' : '$t seconds'),
            onTap: () {
              ref.read(settingsProvider.notifier).setRelockTimer(t);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}
