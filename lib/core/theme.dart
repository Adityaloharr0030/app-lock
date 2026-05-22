import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      FingerprintScannerTheme(
        idleColor: AppColors.scannerIdle,
        scanningColor: AppColors.scannerScanning,
        successColor: AppColors.scannerSuccess,
        failureColor: AppColors.scannerFailure,
        glowColor: AppColors.scannerGlow,
      ),
    ],
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      FingerprintScannerTheme(
        idleColor: AppColors.scannerIdle,
        scanningColor: AppColors.scannerScanning,
        successColor: AppColors.scannerSuccess,
        failureColor: AppColors.scannerFailure,
        glowColor: AppColors.scannerGlow,
      ),
    ],
  );
}

@immutable
class FingerprintScannerTheme extends ThemeExtension<FingerprintScannerTheme> {
  final Color idleColor;
  final Color scanningColor;
  final Color successColor;
  final Color failureColor;
  final Color glowColor;

  const FingerprintScannerTheme({
    required this.idleColor,
    required this.scanningColor,
    required this.successColor,
    required this.failureColor,
    required this.glowColor,
  });

  @override
  FingerprintScannerTheme copyWith({
    Color? idleColor,
    Color? scanningColor,
    Color? successColor,
    Color? failureColor,
    Color? glowColor,
  }) {
    return FingerprintScannerTheme(
      idleColor: idleColor ?? this.idleColor,
      scanningColor: scanningColor ?? this.scanningColor,
      successColor: successColor ?? this.successColor,
      failureColor: failureColor ?? this.failureColor,
      glowColor: glowColor ?? this.glowColor,
    );
  }

  @override
  FingerprintScannerTheme lerp(FingerprintScannerTheme? other, double t) {
    if (other is! FingerprintScannerTheme) return this;
    return FingerprintScannerTheme(
      idleColor: Color.lerp(idleColor, other.idleColor, t)!,
      scanningColor: Color.lerp(scanningColor, other.scanningColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      failureColor: Color.lerp(failureColor, other.failureColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
    );
  }
}

