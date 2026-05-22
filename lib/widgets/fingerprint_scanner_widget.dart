import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

enum ScannerState { idle, scanning, success, failure }

/// A beautiful animated fingerprint scanner widget with four visual states:
/// - Idle: gentle pulse glow
/// - Scanning: radiating ripple effect 
/// - Success: green check morph with haptic
/// - Failure: red X with shake animation
class FingerprintScannerWidget extends StatefulWidget {
  final VoidCallback onTap;
  final ScannerState state;
  final String? fingerLabel;
  final double size;

  const FingerprintScannerWidget({
    super.key,
    required this.onTap,
    this.state = ScannerState.idle,
    this.fingerLabel,
    this.size = 120,
  });

  @override
  State<FingerprintScannerWidget> createState() => _FingerprintScannerWidgetState();
}

class _FingerprintScannerWidgetState extends State<FingerprintScannerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _resultController;
  late AnimationController _shakeController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _updateAnimationsForState(widget.state);
  }

  void _initAnimations() {
    // Idle pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scanning ripple
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Success/failure result
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Shake for failure
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(FingerprintScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationsForState(widget.state);
    }
  }

  void _updateAnimationsForState(ScannerState state) {
    // Stop all
    _pulseController.stop();
    _rippleController.stop();
    _resultController.reset();
    _shakeController.reset();

    switch (state) {
      case ScannerState.idle:
        _pulseController.repeat(reverse: true);
        break;
      case ScannerState.scanning:
        _rippleController.repeat();
        break;
      case ScannerState.success:
        HapticFeedback.heavyImpact();
        _resultController.forward();
        break;
      case ScannerState.failure:
        HapticFeedback.vibrate();
        _resultController.forward();
        _shakeController.forward();
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _resultController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Color _getColor(FingerprintScannerTheme scannerTheme) {
    switch (widget.state) {
      case ScannerState.idle:
        return scannerTheme.idleColor;
      case ScannerState.scanning:
        return scannerTheme.scanningColor;
      case ScannerState.success:
        return scannerTheme.successColor;
      case ScannerState.failure:
        return scannerTheme.failureColor;
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case ScannerState.idle:
      case ScannerState.scanning:
        return Icons.fingerprint;
      case ScannerState.success:
        return Icons.check_circle_outline;
      case ScannerState.failure:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerTheme = Theme.of(context).extension<FingerprintScannerTheme>()!;
    final color = _getColor(scannerTheme);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.state == ScannerState.idle ? widget.onTap : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseController,
              _rippleController,
              _resultController,
              _shakeController,
            ]),
            builder: (context, child) {
              // Calculate shake offset
              double shakeOffset = 0;
              if (widget.state == ScannerState.failure) {
                shakeOffset = sin(_shakeAnimation.value * pi * 4) * 8;
              }

              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: SizedBox(
                  width: widget.size * 1.6,
                  height: widget.size * 1.6,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple rings (scanning state)
                      if (widget.state == ScannerState.scanning) ...[
                        _buildRipple(color, 0.0),
                        _buildRipple(color, 0.33),
                        _buildRipple(color, 0.66),
                      ],

                      // Glow background (idle state)
                      if (widget.state == ScannerState.idle)
                        Container(
                          width: widget.size * _pulseAnimation.value,
                          height: widget.size * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 30 * _pulseAnimation.value,
                                spreadRadius: 5 * _pulseAnimation.value,
                              ),
                            ],
                          ),
                        ),

                      // Main circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              color.withValues(alpha: 0.2),
                              color.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: color.withValues(alpha: 0.6),
                            width: 2.5,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            _getIcon(),
                            key: ValueKey(widget.state),
                            size: widget.size * 0.5,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Status text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _getStatusText(),
            key: ValueKey(widget.state),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Finger label
        if (widget.fingerLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            'Use your ${widget.fingerLabel}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRipple(Color color, double delayFraction) {
    final progress = (_rippleAnimation.value + delayFraction) % 1.0;
    final opacity = (1.0 - progress).clamp(0.0, 0.5);
    final scale = 1.0 + progress * 0.6;

    return Container(
      width: widget.size * scale,
      height: widget.size * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (widget.state) {
      case ScannerState.idle:
        return 'Tap to unlock';
      case ScannerState.scanning:
        return 'Scanning...';
      case ScannerState.success:
        return 'Authenticated!';
      case ScannerState.failure:
        return 'Try again';
    }
  }
}
