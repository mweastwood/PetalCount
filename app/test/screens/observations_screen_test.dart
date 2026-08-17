import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/observations_screen.dart';
import 'package:petal_count/widgets/timeline/timeline.dart';

void main() {
  setUpAll(() async {
    await Services.init();
  });

  group('ObservationsScreen Widget Tests', () {
    testWidgets('displays single month header for entries in the same month', (
      WidgetTester tester,
    ) async {
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

      final cycle = Cycle(
        id: 'cycle_1',
        startDate: startDate,
        dailyEntries: {'2026-06-01': day1},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationsScreen(
              cycles: [cycle],
              todayOverride: DateTime(2026, 6, 3),
              onSelectEntry: (entry, cycle) {},
              onAddForDate: (cycle, date) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimelineMonthHeader), findsOneWidget);
      expect(find.text('JUNE 2026'), findsOneWidget);
    });

    testWidgets(
      'displays multiple month headers across month and year boundaries',
      (WidgetTester tester) async {
        final startDate = DateTime(2025, 12, 30);
        final cycle = Cycle(
          id: 'cycle_1',
          startDate: startDate,
          dailyEntries: {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ObservationsScreen(
                cycles: [cycle],
                todayOverride: DateTime(2026, 1, 2),
                onSelectEntry: (entry, cycle) {},
                onAddForDate: (cycle, date) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Both JANUARY 2026 and DECEMBER 2025 headers should render
        expect(find.byType(TimelineMonthHeader), findsNWidgets(2));
        expect(find.text('JANUARY 2026'), findsOneWidget);
        expect(find.text('DECEMBER 2025'), findsOneWidget);
      },
    );

    testWidgets('triggers onSelectEntry when existing entry item is tapped', (
      WidgetTester tester,
    ) async {
      final targetDate = DateTime(2026, 6, 1);
      final obs = Observation(
        id: 'obs_1',
        timestamp: targetDate,
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final dailyEntry = CreightonLogic.resolveDailyEntry(
        date: targetDate,
        observations: [obs],
      );

      final cycle = Cycle(
        id: 'cycle_1',
        startDate: targetDate,
        dailyEntries: {'2026-06-01': dailyEntry},
      );

      DailyEntry? selectedEntry;
      Cycle? selectedCycle;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationsScreen(
              cycles: [cycle],
              todayOverride: targetDate,
              onSelectEntry: (entry, c) {
                selectedEntry = entry;
                selectedCycle = c;
              },
              onAddForDate: (c, date) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TimelineItemCard).first);
      await tester.pumpAndSettle();

      expect(selectedEntry, isNotNull);
      expect(selectedEntry?.date, equals(targetDate));
      expect(selectedCycle?.id, equals('cycle_1'));
    });

    testWidgets('triggers onAddForDate when empty day item is tapped', (
      WidgetTester tester,
    ) async {
      final startDate = DateTime(2026, 6, 1);
      final cycle = Cycle(
        id: 'cycle_1',
        startDate: startDate,
        dailyEntries: {},
      );

      Cycle? targetCycle;
      DateTime? targetDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationsScreen(
              cycles: [cycle],
              todayOverride: DateTime(2026, 6, 2),
              onSelectEntry: (entry, c) {},
              onAddForDate: (c, date) {
                targetCycle = c;
                targetDate = date;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Tap to log observation').first);
      await tester.pumpAndSettle();

      expect(targetDate, isNotNull);
      expect(targetCycle?.id, equals('cycle_1'));
    });

    testWidgets(
      'renders fallback placeholder and month header when cycles list is empty',
      (WidgetTester tester) async {
        final today = DateTime(2026, 8, 17);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ObservationsScreen(
                cycles: const [],
                todayOverride: today,
                onSelectEntry: (e, c) {},
                onAddForDate: (c, d) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TimelineMonthHeader), findsOneWidget);
        expect(find.text('AUGUST 2026'), findsOneWidget);
        expect(find.textContaining('Tap to log observation'), findsOneWidget);
      },
    );
  });
}
