import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ralph_cos_app/main.dart';
import 'package:ralph_cos_app/screens/splash_screen.dart';

void main() {
  testWidgets('App launch shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RalphCoSApp());

    // Verify that Splash Screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('RALPH'), findsOneWidget);
    expect(find.text('Chief of Staff'), findsOneWidget);
    expect(find.byIcon(Icons.military_tech), findsOneWidget);
  });
}
