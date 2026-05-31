import 'package:distill/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end happy path in DEMO mode (no Firebase): launch → splash → sign-in
/// → home. Run with: flutter test integration_test/app_test.dart on a device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps frames until [finder] matches or the budget runs out. The splash
  /// uses a real timed delay, so we can't rely on pumpAndSettle alone.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for: $finder');
  }

  testWidgets('user signs in and lands on the home screen', (tester) async {
    // Skip onboarding so the splash routes straight to sign-in.
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    app.main();
    await tester.pump();

    // Splash holds for ~1.6s before routing to sign-in.
    await pumpUntil(tester, find.text('Welcome back'));
    expect(find.text('Sign In'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email_field')), 'alice@test.com');
    await tester.enterText(
        find.byKey(const Key('password_field')), 'password123');

    await tester.tap(find.text('Sign In'));

    // Demo sign-in resolves after ~400ms, then the router redirects to /home.
    await pumpUntil(tester, find.widgetWithText(FloatingActionButton, 'Upload'));
    expect(find.text('Welcome back'), findsNothing);
  });
}
