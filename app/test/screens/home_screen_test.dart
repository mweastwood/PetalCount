import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/main.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  setUpAll(() async {
    // Initialize our Services layer with mock/in-memory services for golden screenshot testing
    await Services.init();
  });

  testGoldens('Dashboard renders Vertical Timeline view correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'dashboard_vertical_timeline_view');
  });

  testGoldens('Dashboard renders Creighton Grid view in Portrait correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap on "Creighton Grid" segment button to switch to grid view
    await tester.tap(find.text('Creighton Grid'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'dashboard_creighton_grid_portrait');
  });

  testGoldens('Dashboard renders Creighton Grid view in Landscape correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(800, 400),
    );
    await tester.pumpAndSettle();

    // Tap on "Creighton Grid" segment button to switch to grid view
    await tester.tap(find.text('Creighton Grid'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'dashboard_creighton_grid_landscape');
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

    // Add collaborator so Leave Chart button is rendered
    await Services.db.invitePartner('partner@example.com');
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

  testGoldens('Leave chart confirmation dialog renders correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      const PetalCountApp(),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Add collaborator so Leave Chart button is rendered
    await Services.db.invitePartner('partner@example.com');
    await tester.pumpAndSettle();

    // Tap settings icon
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Scroll to the leave button
    await tester.scrollUntilVisible(
      find.text('Leave Chart'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Tap "Leave Chart"
    await tester.tap(find.text('Leave Chart'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'leave_chart_confirmation_dialog');
  });

  testGoldens(
    'SettingsScreen danger zone sole collaborator renders correctly',
    (tester) async {
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

      await screenMatchesGolden(tester, 'settings_screen_danger_zone_sole');
    },
  );
}
