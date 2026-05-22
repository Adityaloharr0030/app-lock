import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/fingerprint_scanner_widget.dart';
import '../widgets/pin_pad.dart';
import '../services/auth_manager.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  int _tapCount = 0;
  Timer? _resetTimer;
  bool _isRefreshing = false;

  // Weather data simulator
  String _currentTemp = '24°C';
  final String _condition = 'Partly Cloudy';
  final String _city = 'New York';
  final List<Map<String, String>> _hourlyForecast = [
    {'time': 'Now', 'temp': '24°C', 'icon': 'cloud'},
    {'time': '16:00', 'temp': '25°C', 'icon': 'cloud'},
    {'time': '17:00', 'temp': '23°C', 'icon': 'rain'},
    {'time': '18:00', 'temp': '21°C', 'icon': 'rain'},
    {'time': '19:00', 'temp': '19°C', 'icon': 'wind'},
    {'time': '20:00', 'temp': '18°C', 'icon': 'moon'},
    {'time': '21:00', 'temp': '17°C', 'icon': 'moon'},
  ];

  final List<Map<String, String>> _dailyForecast = [
    {'day': 'Today', 'temp': '25° / 17°', 'condition': 'Partly Cloudy', 'icon': 'cloud'},
    {'day': 'Saturday', 'temp': '24° / 16°', 'condition': 'Rain Showers', 'icon': 'rain'},
    {'day': 'Sunday', 'temp': '21° / 14°', 'condition': 'Heavy Rain', 'icon': 'rain'},
    {'day': 'Monday', 'temp': '19° / 13°', 'condition': 'Windy', 'icon': 'wind'},
    {'day': 'Tuesday', 'temp': '22° / 15°', 'condition': 'Sunny Intervals', 'icon': 'sun'},
  ];

  void _handleWeatherIconTap() {
    _resetTimer?.cancel();
    setState(() {
      _tapCount++;
    });

    if (_tapCount >= 5) {
      _tapCount = 0;
      _triggerSecretEntrance();
    } else {
      _resetTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _tapCount = 0);
        }
      });
    }
  }

  Future<void> _triggerSecretEntrance() async {
    final pinService = ref.read(pinServiceProvider);
    final isPinSet = await pinService.isPinSet();

    if (!mounted) return;

    if (!isPinSet) {
      // First-time setup disguise entry
      context.go('/setup');
    } else {
      // Prompt for unlock before entering Home dashboard
      _showSecuritySheet();
    }
  }

  void _showSecuritySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return const _WeatherSecuritySheet();
      },
    ).then((value) {
      if (value == true && mounted) {
        context.go('/home');
      }
    });
  }

  Future<void> _refreshWeather() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        // Simulate minor temperature change
        _currentTemp = '${22 + (1 + (1 * 2) % 3)}°C';
      });
    }
  }

  IconData _getWeatherIcon(String name) {
    switch (name) {
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'cloud':
        return Icons.cloud_queue_rounded;
      case 'rain':
        return Icons.umbrella_rounded;
      case 'wind':
        return Icons.air_rounded;
      case 'moon':
        return Icons.nightlight_round;
      default:
        return Icons.cloud_rounded;
    }
  }

  Color _getWeatherIconColor(String name) {
    switch (name) {
      case 'sun':
        return Colors.amber;
      case 'cloud':
        return Colors.blue.shade200;
      case 'rain':
        return Colors.lightBlue.shade300;
      case 'wind':
        return Colors.teal.shade200;
      case 'moon':
        return Colors.yellow.shade100;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
          child: RefreshIndicator(
            onRefresh: _refreshWeather,
            color: Colors.blueAccent,
            backgroundColor: const Color(0xFF262E49),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Bar / Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 18, color: Colors.blue.shade300),
                              const SizedBox(width: 4),
                              Text(
                                _city,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Weather Alert: Active Forecast',
                            style: TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _refreshWeather,
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Main Weather Disguise Card
                  GestureDetector(
                    onTap: _handleWeatherIconTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        // Animated Weather Graphic (Disguise)
                        _AnimatedWeatherGraphic(
                          icon: _getWeatherIcon('cloud'),
                          color: _getWeatherIconColor('cloud'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentTemp,
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _condition,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'H:26° L:16°',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Hourly Forecast Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hourly Forecast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Hourly Forecast Row
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _hourlyForecast.length,
                      itemBuilder: (context, index) {
                        final forecast = _hourlyForecast[index];
                        return Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262E49).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                forecast['time']!,
                                style: const TextStyle(fontSize: 12, color: Colors.white60),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                _getWeatherIcon(forecast['icon']!),
                                color: _getWeatherIconColor(forecast['icon']!),
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                forecast['temp']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Weather Info Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricsCard('Wind Speed', '12 km/h', Icons.air, Colors.tealAccent),
                      _buildMetricsCard('Humidity', '64%', Icons.water_drop, Colors.blueAccent),
                      _buildMetricsCard('UV Index', '3 (Mod)', Icons.wb_sunny, Colors.amberAccent),
                      _buildMetricsCard('Visibility', '10 km', Icons.visibility, Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 5-Day Forecast Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '5-Day Forecast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5-Day Forecast List
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF262E49).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Column(
                      children: _dailyForecast.map((day) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  day['day']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getWeatherIcon(day['icon']!),
                                      color: _getWeatherIconColor(day['icon']!),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      day['condition']!.split(' ').first,
                                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                day['temp']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsCard(String title, String val, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262E49).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            val,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWeatherGraphic extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedWeatherGraphic({required this.icon, required this.color});

  @override
  State<_AnimatedWeatherGraphic> createState() => _AnimatedWeatherGraphicState();
}

class _AnimatedWeatherGraphicState extends State<_AnimatedWeatherGraphic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 80,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _WeatherSecuritySheet extends ConsumerStatefulWidget {
  const _WeatherSecuritySheet();

  @override
  ConsumerState<_WeatherSecuritySheet> createState() => _WeatherSecuritySheetState();
}

class _WeatherSecuritySheetState extends ConsumerState<_WeatherSecuritySheet> {
  String _enteredPin = '';
  ScannerState _scannerState = ScannerState.idle;
  String? _fingerLabel;
  bool _showBiometric = false;
  bool _showPinPad = true;
  int _bioRetryCount = 0;
  static const int _maxBioRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
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
      _showPinPad = !shouldShowBiometric;
    });

    if (shouldShowBiometric && autoTrigger) {
      Future.delayed(const Duration(milliseconds: 400), () {
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
      return;
    }

    setState(() => _scannerState = ScannerState.scanning);
    final success = await ref.read(authManagerProvider).authenticate();

    if (!mounted) return;

    if (success) {
      setState(() => _scannerState = ScannerState.success);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } else {
      _bioRetryCount++;
      setState(() => _scannerState = ScannerState.failure);

      if (_bioRetryCount < _maxBioRetries) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _scannerState = ScannerState.idle);
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

  void _handlePinInput(String val) async {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += val);
      if (_enteredPin.length == 4) {
        final success = await ref.read(pinServiceProvider).verifyPin(_enteredPin);
        if (!mounted) return;
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN. Access Denied.')),
          );
          setState(() => _enteredPin = '');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2640).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Header info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 20, color: Colors.blue.shade300),
                const SizedBox(width: 8),
                const Text(
                  'Access Verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Please authenticate to access Weather Alert settings.',
              style: TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 24),

            // Content Area
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showPinPad ? _buildPinPadView(colorScheme) : _buildBiometricView(),
            ),

            // Toggle authentication method
            if (_showBiometric) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _showPinPad = !_showPinPad),
                icon: Icon(
                  _showPinPad ? Icons.fingerprint : Icons.dialpad,
                  color: Colors.blue.shade300,
                ),
                label: Text(
                  _showPinPad ? 'Use Fingerprint' : 'Use PIN',
                  style: TextStyle(color: Colors.blue.shade300),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPinPadView(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('security_pin_pad'),
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
              const SnackBar(content: Text('Please reinstall the app to reset your PIN.')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBiometricView() {
    return Column(
      key: const ValueKey('security_biometric'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
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
