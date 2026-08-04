import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/chart_screen.dart';

void main() {
  setUpAll(() async {
    await Services.init();
  });

  testWidgets(
    'ChartScreen displays question mark for missing observation days and preserves day alignment',
    (WidgetTester tester) async {
      final startDate = DateTime(2026, 6, 1);
      final day1 = DailyEntry(
        date: startDate,
        resolvedVdrsCode: '2',
        stampType: StampType.green,
        observations: const [],
        painLevel: 0,
        painTypes: const [],
        comments: '',
      );
      final day3Date = DateTime(2026, 6, 3);
      final day3 = DailyEntry(
        date: day3Date,
        resolvedVdrsCode: '10KL',
        stampType: StampType.whiteBaby,
        observations: const [],
        painLevel: 0,
        painTypes: const [],
        comments: '',
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

      // Verify VDRS codes for Day 1 ('2') and Day 3 ('10KL')
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10KL'), findsOneWidget);

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
      final day1 = DailyEntry(
        date: startDate,
        resolvedVdrsCode: '2',
        stampType: StampType.green,
        observations: const [],
        painLevel: 0,
        painTypes: const [],
        comments: '',
      );
      final day3Date = DateTime(2026, 6, 3);
      final day3 = DailyEntry(
        date: day3Date,
        resolvedVdrsCode: '10KL',
        stampType: StampType.whiteBaby,
        observations: const [],
        painLevel: 0,
        painTypes: const [],
        comments: '',
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
}
