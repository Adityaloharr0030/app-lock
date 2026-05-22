import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/biometric_setup_screen.dart';
import 'screens/weather_screen.dart';
import 'providers/settings_provider.dart';
import 'services/native_lock_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

// Global router so HomeScreen can register the listener after startService()
late final GoRouter appRouter;

class AppLockerApp extends ConsumerStatefulWidget {
  const AppLockerApp({super.key});

  @override
  ConsumerState<AppLockerApp> createState() => _AppLockerAppState();
}

class _AppLockerAppState extends ConsumerState<AppLockerApp> {
  @override
  void initState() {
    super.initState();
    appRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        GoRoute(path: '/weather', builder: (context, state) => const WeatherScreen()),
        GoRoute(
          path: '/biometric-setup',
          builder: (context, state) => BiometricSetupScreen(
            isInitialSetup: state.uri.queryParameters['initial'] == 'true',
          ),
        ),
        GoRoute(
          path: '/lock/:pkg/:name',
          builder: (context, state) => LockScreen(
            packageName: state.pathParameters['pkg']!,
            appName: state.pathParameters['name']!,
          ),
        ),
      ],
    );
    NativeLockService.registerLockListener(appRouter);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return WithForegroundTask(
      child: MaterialApp.router(
        title: 'Weather Alert',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
        routerConfig: appRouter,
      ),
    );
  }
}
