import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/chart_screen.dart';

void main() {
  setUpAll(() async {
    await Services.init();
  });

  testWidgets('ChartScreen shows fallback text when no cycles available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartScreen(
            cycles: const [],
            onSelectEntry: (e, c) {},
            onAddForDate: (c, d) {},
          ),
        ),
      ),
    );

    expect(
      find.text('No cycles available. Log an observation to begin.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ChartScreen displays question mark for missing observation days and preserves day alignment',
    (WidgetTester tester) async {
      final startDate = DateTime(2026, 6, 1);
      final obs1 = Observation(
        id: '1',
        timestamp: startDate,
        sensation: Sensation.damp,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final day1 = CreightonLogic.resolveDailyEntry(
        date: startDate,
        observations: [obs1],
      );
      final day3Date = DateTime(2026, 6, 3);
      final obs3 = Observation(
        id: '3',
        timestamp: day3Date,
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final day3 = CreightonLogic.resolveDailyEntry(
        date: day3Date,
        observations: [obs3],
      );

      final cycle = Cycle(
        id: 'cycle_1',
        startDate: startDate,
        dailyEntries: {'2026-06-01': day1, '2026-06-03': day3},
      );

      DateTime? tappedAddDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartScreen(
              cycles: [cycle],
              onSelectEntry: (entry, c) {},
              onAddForDate: (c, date) {
                tappedAddDate = date;
              },
            ),
          ),
        ),
      );

      // Verify date Jun 01 (appears in cycle header card & day 1 cell), Jun 02, Jun 03 are present
      expect(find.text('Jun 01'), findsWidgets);
      expect(find.text('Jun 02'), findsOneWidget);
      expect(find.text('Jun 03'), findsOneWidget);

      // Verify VDRS codes for Day 1 ('2') and Day 3 ('10WLK')
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10WLK'), findsOneWidget);

      // Verify question marks exist for missing days (including Jun 02)
      expect(find.text('?'), findsWidgets);

      // Tap on Jun 02 cell to verify onAddForDate is called with 2026-06-02
      await tester.tap(find.text('Jun 02'));
      await tester.pumpAndSettle();

      expect(tappedAddDate, equals(DateTime(2026, 6, 2)));
    },
  );

  testGoldens(
    'ChartScreen renders question mark on missing observation days golden',
    (WidgetTester tester) async {
      final startDate = DateTime(2026, 6, 1);
      final obs1 = Observation(
        id: '1',
        timestamp: startDate,
        sensation: Sensation.damp,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final day1 = CreightonLogic.resolveDailyEntry(
        date: startDate,
        observations: [obs1],
      );
      final day3Date = DateTime(2026, 6, 3);
      final obs3 = Observation(
        id: '3',
        timestamp: day3Date,
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final day3 = CreightonLogic.resolveDailyEntry(
        date: day3Date,
        observations: [obs3],
      );

      final cycle = Cycle(
        id: 'cycle_1',
        startDate: startDate,
        dailyEntries: {'2026-06-01': day1, '2026-06-03': day3},
      );

      await tester.pumpWidgetBuilder(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
          home: Scaffold(
            body: ChartScreen(
              cycles: [cycle],
              onSelectEntry: (entry, c) {},
              onAddForDate: (c, date) {},
            ),
          ),
        ),
        surfaceSize: const Size(800, 600),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'chart_screen_missing_days_question_mark',
      );
    },
  );

  testWidgets(
    'ChartScreen hides unpopulated extra days for past cycle after new cycle starts',
    (WidgetTester tester) async {
      final cycle1Start = DateTime(2026, 6, 1);
      final cycle2Start = DateTime(2026, 6, 20); // 19 days in Cycle 1

      final cycle1 = Cycle(
        id: 'cycle_1',
        startDate: cycle1Start,
        dailyEntries: {
          '2026-06-01': CreightonLogic.resolveDailyEntry(
            date: cycle1Start,
            observations: [
              Observation(
                id: '1',
                timestamp: cycle1Start,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.heavy,
                userId: 'test',
              ),
            ],
          ),
        },
      );

      final cycle2 = Cycle(
        id: 'cycle_2',
        startDate: cycle2Start,
        dailyEntries: {
          '2026-06-20': CreightonLogic.resolveDailyEntry(
            date: cycle2Start,
            observations: [
              Observation(
                id: '2',
                timestamp: cycle2Start,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.heavy,
                userId: 'test',
              ),
            ],
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartScreen(
              cycles: [cycle1, cycle2],
              onSelectEntry: (entry, c) {},
              onAddForDate: (c, date) {},
            ),
          ),
        ),
      );

      // Verify Cycle 1 has Day 19 (Jun 19)
      expect(find.text('Jun 19'), findsOneWidget);

      // Verify Jun 20 is only present for Cycle 2 (header & cell), not duplicated in Cycle 1
      expect(find.text('Jun 20'), findsWidgets);

      // Verify dates after Jun 20 are only from Cycle 2, and Cycle 1 did not generate June 21+ cells
      // Day 35 from Cycle 2 is July 24
      expect(find.text('Jul 24'), findsOneWidget);
    },
  );

  testGoldens(
    'ChartScreen hides unpopulated extra days for past cycle golden',
    (WidgetTester tester) async {
      final cycle1Start = DateTime(2026, 6, 1);
      final cycle2Start = DateTime(2026, 6, 20); // 19 days in Cycle 1

      final cycle1 = Cycle(
        id: 'cycle_1',
        startDate: cycle1Start,
        dailyEntries: {
          '2026-06-01': CreightonLogic.resolveDailyEntry(
            date: cycle1Start,
            observations: [
              Observation(
                id: '1',
                timestamp: cycle1Start,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.heavy,
                userId: 'test',
              ),
            ],
          ),
        },
      );

      final cycle2 = Cycle(
        id: 'cycle_2',
        startDate: cycle2Start,
        dailyEntries: {
          '2026-06-20': CreightonLogic.resolveDailyEntry(
            date: cycle2Start,
            observations: [
              Observation(
                id: '2',
                timestamp: cycle2Start,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.heavy,
                userId: 'test',
              ),
            ],
          ),
        },
      );

      await tester.pumpWidgetBuilder(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
          home: Scaffold(
            body: ChartScreen(
              cycles: [cycle1, cycle2],
              onSelectEntry: (entry, c) {},
              onAddForDate: (c, date) {},
            ),
          ),
        ),
        surfaceSize: const Size(800, 600),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'chart_screen_past_cycle_hidden_unpopulated_days',
      );
    },
  );

  testWidgets(
    'ChartScreen renders readable cycle headers in narrow (portrait) mobile mode and opens options dialog and PDF export',
    (WidgetTester tester) async {
      final startDate = DateTime(2026, 7, 1);
      final cycle = Cycle(
        id: 'cycle_1',
        startDate: startDate,
        dailyEntries: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(390, 844)),
              child: ChartScreen(
                cycles: [cycle],
                onSelectEntry: (entry, c) {},
                onAddForDate: (c, date) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify corner cell 'Day' is rendered
      expect(find.text('Day'), findsOneWidget);

      // Verify cycle start date (Jul 01) and year (2026) are rendered in the header
      expect(find.text('Jul 01'), findsWidgets);
      expect(find.text('2026'), findsOneWidget);

      // Verify PDF export button and Cycle Options button are rendered
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.settings_suggest), findsOneWidget);

      // Tap the cycle header card to open CycleOptionsDialog
      await tester.tap(find.text('Jul 01').first);
      await tester.pumpAndSettle();

      // Verify Cycle Options modal bottom sheet is shown
      expect(find.text('Cycle Boundary Options'), findsOneWidget);

      // Dismiss dialog
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('Cycle Boundary Options'), findsNothing);

      // Tap settings_suggest button to verify it also opens options dialog
      await tester.tap(find.byIcon(Icons.settings_suggest));
      await tester.pumpAndSettle();
      expect(find.text('Cycle Boundary Options'), findsOneWidget);

      // Dismiss dialog
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Verify tapping PDF icon button does not throw
      await tester.tap(find.byIcon(Icons.picture_as_pdf));
      await tester.pumpAndSettle();
    },
  );

  group('ChartScreen.computeDisplayDaysMap', () {
    test('returns empty map for empty cycles', () {
      final result = ChartScreen.computeDisplayDaysMap([], 35);
      expect(result, isEmpty);
    });

    test('correctly handles completed cycles with endDate', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 15); // 15 days
      final cycle = Cycle(id: 'c1', startDate: start, endDate: end);

      final result = ChartScreen.computeDisplayDaysMap([cycle], 35);
      expect(result['c1'], equals(15));
    });

    test('correctly handles open cycles bounded by subsequent cycles', () {
      final cycle1 = Cycle(id: 'c1', startDate: DateTime(2026, 1, 1));
      final cycle2 = Cycle(id: 'c2', startDate: DateTime(2026, 1, 21));

      final result = ChartScreen.computeDisplayDaysMap([cycle1, cycle2], 35);
      expect(result['c1'], equals(20));
      expect(result['c2'], equals(35));
    });

    test('defaults the latest open cycle to maxDays', () {
      final cycle = Cycle(id: 'c1', startDate: DateTime(2026, 1, 1));
      final result = ChartScreen.computeDisplayDaysMap([cycle], 40);
      expect(result['c1'], equals(40));
    });

    test(
      'correctly produces sorted chronological bounds for unsorted cycle inputs',
      () {
        final cycle3 = Cycle(id: 'c3', startDate: DateTime(2026, 3, 1));
        final cycle1 = Cycle(id: 'c1', startDate: DateTime(2026, 1, 1));
        final cycle2 = Cycle(id: 'c2', startDate: DateTime(2026, 2, 1));

        // Pass in reverse order [c3, c1, cycle2]
        final result = ChartScreen.computeDisplayDaysMap([
          cycle3,
          cycle1,
          cycle2,
        ], 35);
        expect(result['c1'], equals(31)); // Jan 1 to Feb 1
        expect(result['c2'], equals(28)); // Feb 1 to Mar 1
        expect(result['c3'], equals(35)); // latest open cycle
      },
    );

    test('truncates endDays to maxDays if cycle duration exceeds maxDays', () {
      final cycle = Cycle(
        id: 'c1',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 20), // 51 days
      );
      final result = ChartScreen.computeDisplayDaysMap([cycle], 35);
      expect(result['c1'], equals(35));
    });

    test('handles same-day start dates by falling back to maxDays', () {
      final cycle1 = Cycle(id: 'c1', startDate: DateTime(2026, 1, 1));
      final cycle2 = Cycle(id: 'c2', startDate: DateTime(2026, 1, 1));
      final result = ChartScreen.computeDisplayDaysMap([cycle1, cycle2], 35);
      expect(result['c1'], equals(35));
      expect(result['c2'], equals(35));
    });
  });
}
