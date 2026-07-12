import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/main.dart';
import 'package:petal_count/services/services.dart';

void main() {
  setUp(() async {
    // Initialize our Services layer with mock/in-memory services for the test
    await Services.init();
  });

  testWidgets('Creighton Dashboard interactive widget test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PetalCountApp());
    await tester.pumpAndSettle();

    // Verify Dashboard Screen title is shown
    expect(find.text('Petal Count'), findsOneWidget);

    // Verify that the cycle list shows the cycle entry
    expect(find.textContaining('Cycle starting'), findsOneWidget);

    // Tap on the cycle card to open the CycleChartScreen
    await tester.tap(find.textContaining('Cycle starting'));
    await tester.pumpAndSettle();

    // Verify standard Log Observation button is present
    expect(find.text('Log Observation'), findsOneWidget);

    // Find the settings button and tap it
    final settingsBtn = find.byIcon(Icons.settings);
    expect(settingsBtn, findsOneWidget);

    await tester.tap(settingsBtn);
    await tester.pumpAndSettle();

    // Verify we are in the settings screen
    expect(find.text('Settings & Configuration'), findsOneWidget);
    expect(find.textContaining('Active Profile'), findsOneWidget);
  });
}
