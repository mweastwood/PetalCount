import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/main.dart';
import 'package:petal_count/services/services.dart';

void main() {
  setUpAll(() async {
    // Initialize our Services layer with mock/in-memory services for golden screenshot testing
    await Services.init();
  });

  testGoldens('Dashboard renders correctly in initial state', (tester) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'dashboard_screen_initial');
  });

  testGoldens('CycleChartScreen renders grid correctly', (tester) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap on the cycle card to open CycleChartScreen
    await tester.tap(find.textContaining('Cycle starting'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'cycle_chart_screen');
  });

  testGoldens('ChartSelectionScreen renders correctly', (tester) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap the switch chart icon to open the selection screen
    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'chart_selection_screen');
  });

  testGoldens('SettingsScreen danger zone renders correctly', (tester) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap settings icon
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Scroll to the delete button to bring it into view
    await tester.scrollUntilVisible(
      find.text('Delete Chart'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'settings_screen_danger_zone');
  });

  testGoldens('Delete chart confirmation dialog renders correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap settings icon
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Scroll to the delete button
    await tester.scrollUntilVisible(
      find.text('Delete Chart'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Tap "Delete Chart"
    await tester.tap(find.text('Delete Chart'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'delete_chart_confirmation_dialog');
  });
}
