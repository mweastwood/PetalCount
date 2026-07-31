import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/main.dart';
import 'package:petal_count/logic/logic.dart';

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

    // Verify view mode switcher bottom navigation destinations are present
    expect(find.text('Observations'), findsOneWidget);
    expect(find.text('Chart'), findsOneWidget);

    // Tap on Chart to switch to chart view
    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();

    // Verify that the Creighton grid shows the cycle entry
    expect(find.textContaining('Cycle starting'), findsOneWidget);

    // Verify standard Log Observation speed dial toggle button (+) is present
    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify speed dial reveals the 4 options: Log mucus, Log bleeding, Log intercourse, Log pain
    expect(find.text('Log mucus'), findsOneWidget);
    expect(find.text('Log bleeding'), findsOneWidget);
    expect(find.text('Log intercourse'), findsOneWidget);
    expect(find.text('Log pain'), findsOneWidget);

    // Find the settings button and tap it
    final settingsBtn = find.byIcon(Icons.settings);
    expect(settingsBtn, findsOneWidget);

    await tester.tap(settingsBtn);
    await tester.pumpAndSettle();

    // Verify we are in the settings screen
    expect(find.text('Settings & Configuration'), findsOneWidget);
    expect(find.textContaining('Active Profile'), findsOneWidget);
  });

  testWidgets(
    'Vertical Timeline View displays today at bottom and scrolls up',
    (WidgetTester tester) async {
      await tester.pumpWidget(const PetalCountApp());
      await tester.pumpAndSettle();

      // Verify Observations navigation tab is selected by default
      expect(find.text('Observations'), findsOneWidget);

      // Verify "Today" entry is rendered
      expect(find.textContaining('Today'), findsOneWidget);

      // Drag to scroll up to view previous days
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();

      // Verify timeline items exist in scroll view
      expect(find.byType(InkWell), findsWidgets);
    },
  );
}
