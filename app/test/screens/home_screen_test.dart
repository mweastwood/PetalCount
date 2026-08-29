import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/main.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/screens.dart';

void main() {
  setUpAll(() async {
    // Initialize our Services layer with mock/in-memory services for golden screenshot testing
    await Services.init();
  });

  testWidgets('Dashboard drawer opens and navigates to switch chart', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Verify drawer is closed initially
    expect(find.byType(Drawer), findsNothing);

    // Open drawer using the menu icon
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify drawer is now open
    expect(find.byType(Drawer), findsOneWidget);

    // Verify drawer header and list tiles
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('Menu')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('drawer_switch_chart_tile')), findsOneWidget);
    expect(find.byKey(const Key('drawer_settings_tile')), findsOneWidget);
    expect(find.byKey(const Key('drawer_logout_tile')), findsOneWidget);
    expect(find.byKey(const Key('drawer_version_tile')), findsOneWidget);
    expect(find.text(AppVersion.display), findsOneWidget);

    // Tap on switch chart tile and verify navigation
    await tester.tap(find.byKey(const Key('drawer_switch_chart_tile')));
    await tester.pumpAndSettle();

    expect(find.byType(ChartSelectionScreen), findsOneWidget);
  });

  testWidgets('Dashboard drawer opens and navigates to settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Open drawer using the menu icon
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Tap on settings tile and verify navigation
    await tester.tap(find.byKey(const Key('drawer_settings_tile')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Dashboard navigation bar switches to Supplements tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Verify Supplements tab exists in NavigationBar
    expect(find.text('Observations'), findsOneWidget);
    expect(find.text('Chart'), findsOneWidget);
    expect(find.text('Supplements'), findsOneWidget);

    // Tap on Supplements tab
    await tester.tap(find.text('Supplements'));
    await tester.pumpAndSettle();

    // Verify SupplementScreen content is rendered
    expect(find.byType(SupplementScreen), findsOneWidget);
    expect(find.text('Daily Intake'), findsOneWidget);
    expect(find.text('Cycle Plan'), findsOneWidget);
    expect(find.text('Formulary'), findsOneWidget);
  });

  testWidgets('Dashboard drawer opens and switches to Supplements tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Open drawer using the menu icon
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Tap on supplements tile in drawer
    expect(find.byKey(const Key('drawer_supplements_tile')), findsOneWidget);
    await tester.tap(find.byKey(const Key('drawer_supplements_tile')));
    await tester.pumpAndSettle();

    // Verify drawer closed and supplements tab is shown
    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(SupplementScreen), findsOneWidget);
    expect(find.text('Daily Intake'), findsOneWidget);
  });

  testGoldens('Dashboard hamburger menu drawer open state golden', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Match golden
    await screenMatchesGolden(tester, 'dashboard_drawer_open');
  });

  testGoldens('Dashboard renders Vertical Timeline view correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'dashboard_vertical_timeline_view');
  });

  testGoldens('Dashboard renders Speed Dial expanded view correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap + FAB to expand speed dial options
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'dashboard_speed_dial_open');
  });

  testGoldens('Dashboard renders Creighton Grid view in Portrait correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap on "Chart" navigation tab to switch to chart view
    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'dashboard_creighton_grid_portrait');
  });

  testGoldens('Dashboard renders Creighton Grid view in Landscape correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(800, 400),
    );
    await tester.pumpAndSettle();

    // Tap on "Chart" navigation tab to switch to chart view
    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'dashboard_creighton_grid_landscape');
  });

  testGoldens('Dashboard renders Supplements view in Portrait correctly', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Tap on "Supplements" navigation tab to switch to supplements view
    await tester.tap(find.text('Supplements'));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'dashboard_supplements_portrait');
  });

  testGoldens('ChartSelectionScreen renders correctly', (tester) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
      surfaceSize: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    // Open drawer and tap switch chart tile
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer_switch_chart_tile')));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'chart_selection_screen');
  });

  testGoldens('SettingsScreen danger zone renders correctly', (tester) async {
    await tester.pumpWidgetBuilder(
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
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
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
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
      PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
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
        PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
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

  testGoldens(
    'Creighton Chart Screen renders multiple cycles in Portrait correctly',
    (tester) async {
      await Services.init();

      // Create Cycle 1 starting May 1, 2026
      await Services.db.saveObservation(
        date: DateTime(2026, 5, 1, 9, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Period Start Cycle 1',
        isVdrsExplicit: true,
      );
      await Services.db.saveObservation(
        date: DateTime(2026, 5, 5, 10, 0),
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: 'Mucus entry Cycle 1',
        isVdrsExplicit: true,
      );

      // Create Cycle 2 starting June 1, 2026
      await Services.db.saveObservation(
        date: DateTime(2026, 6, 1, 8, 30),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Period Start Cycle 2',
        isVdrsExplicit: true,
      );
      await Services.db.saveObservation(
        date: DateTime(2026, 6, 8, 14, 0),
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear, MucusColor.cloudy],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: 'Peak mucus Cycle 2',
        isVdrsExplicit: true,
      );

      // Create Cycle 3 starting July 1, 2026
      await Services.db.saveObservation(
        date: DateTime(2026, 7, 1, 9, 15),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Period Start Cycle 3',
        isVdrsExplicit: true,
      );

      await tester.pumpWidgetBuilder(
        PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
        surfaceSize: const Size(400, 800),
      );
      await tester.pumpAndSettle();

      // Tap on "Chart" navigation tab
      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'creighton_chart_multi_cycle_portrait');
    },
  );

  testGoldens(
    'Creighton Chart Screen renders multiple cycles in Landscape correctly',
    (tester) async {
      await Services.init();

      // Create Cycle 1 starting May 1, 2026
      await Services.db.saveObservation(
        date: DateTime(2026, 5, 1, 9, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Period Start Cycle 1',
        isVdrsExplicit: true,
      );
      await Services.db.saveObservation(
        date: DateTime(2026, 5, 5, 10, 0),
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: 'Mucus entry Cycle 1',
        isVdrsExplicit: true,
      );

      // Create Cycle 2 starting June 1, 2026
      await Services.db.saveObservation(
        date: DateTime(2026, 6, 1, 8, 30),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Period Start Cycle 2',
        isVdrsExplicit: true,
      );
      await Services.db.saveObservation(
        date: DateTime(2026, 6, 8, 14, 0),
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear, MucusColor.cloudy],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: 'Peak mucus Cycle 2',
        isVdrsExplicit: true,
      );

      // Create Cycle 3 starting July 1, 2026
      await Services.db.saveObservation(
        date: DateTime(2026, 7, 1, 9, 15),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Period Start Cycle 3',
        isVdrsExplicit: true,
      );

      await tester.pumpWidgetBuilder(
        PetalCountApp(todayOverride: DateTime(2026, 8, 3)),
        surfaceSize: const Size(800, 400),
      );
      await tester.pumpAndSettle();

      // Tap on "Chart" navigation tab
      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'creighton_chart_multi_cycle_landscape',
      );
    },
  );

  testGoldens(
    'Dashboard displays Day 7 BSE banner when current cycle is on Day 7',
    (tester) async {
      await Services.init();
      // Cycle starts on Aug 1, 2026. Day 7 is Aug 7, 2026.
      await Services.db.saveObservation(
        date: DateTime(2026, 8, 1, 8, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Cycle start',
        isVdrsExplicit: true,
      );

      // On Day 6 (Aug 6), banner should not be displayed
      await tester.pumpWidgetBuilder(
        PetalCountApp(todayOverride: DateTime(2026, 8, 6)),
        surfaceSize: const Size(400, 800),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_day_7_bse')), findsNothing);

      // On Day 7 (Aug 7), banner should be displayed
      await tester.pumpWidgetBuilder(
        PetalCountApp(todayOverride: DateTime(2026, 8, 7)),
        surfaceSize: const Size(400, 800),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_day_7_bse')), findsOneWidget);
      expect(
        find.text('Cycle Day 7: Routine Breast Self-Exam'),
        findsOneWidget,
      );

      await screenMatchesGolden(tester, 'dashboard_day_7_bse_banner');
    },
  );

  testWidgets(
    'Dashboard hides Day 7 BSE banner when breastSelfExamReminder is disabled',
    (WidgetTester tester) async {
      await Services.init();
      final chartId = Services.db.currentChartId!;

      // Disable breast self exam reminder in preferences
      await Services.db.updateNotificationPreferences(
        chartId,
        const NotificationPreferences(breastSelfExamReminder: false),
      );

      // Cycle starts on Aug 1, 2026. Day 7 is Aug 7, 2026.
      await Services.db.saveObservation(
        date: DateTime(2026, 8, 1, 8, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Cycle start',
        isVdrsExplicit: true,
      );

      // On Day 7 (Aug 7) with reminder disabled, banner should NOT be displayed
      await tester.pumpWidgetBuilder(
        PetalCountApp(todayOverride: DateTime(2026, 8, 7)),
        surfaceSize: const Size(400, 800),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_day_7_bse')), findsNothing);
    },
  );
}
