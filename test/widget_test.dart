import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:applocker/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock flutter_secure_storage
    FlutterSecureStorage.setMockInitialValues({});

    // Mock native lock service method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.aditya.applocker/lock_service'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPendingLock') {
          return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.aditya.applocker/lock_service'),
      null,
    );
  });

  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AppLockerApp()),
    );
    // Verify the splash screen shows
    expect(find.text('Weather Alert'), findsOneWidget);

    // Let the delayed timer in SplashScreen finish without pumpAndSettle timing out
    // due to the infinite CircularProgressIndicator animation.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(); // Pump frame after timer fires
  });
}
