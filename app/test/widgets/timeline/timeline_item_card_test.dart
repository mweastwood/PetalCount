import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/timeline/observation_details_card.dart';
import 'package:petal_count/widgets/timeline/timeline_item_card.dart';

void main() {
  group('TimelineItemCard Unit & Widget Tests', () {
    testWidgets('renders empty day placeholder and handles tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      final date = DateTime(2026, 8, 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineItemCard(
              date: date,
              entry: null,
              cycle: null,
              dayNumber: 3,
              isCycleStart: false,
              isToday: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Monday, Aug 03, 2026'), findsOneWidget);
      expect(find.text('Day 3 • Tap to log observation'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('renders Today highlighted styling and cycle start banner', (
      WidgetTester tester,
    ) async {
      bool cycleOptionsTapped = false;
      final date = DateTime(2026, 8, 3);
      final cycle = Cycle(id: 'cycle-1', startDate: date);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineItemCard(
              date: date,
              entry: null,
              cycle: cycle,
              dayNumber: 1,
              isCycleStart: true,
              isToday: true,
              onTap: () {},
              onCycleOptionsTap: () {
                cycleOptionsTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Today – Monday, Aug 03, 2026'), findsOneWidget);
      expect(find.text('Cycle starting August 03, 2026'), findsOneWidget);

      // Tap cycle banner
      await tester.tap(find.text('Cycle starting August 03, 2026'));
      expect(cycleOptionsTapped, isTrue);
    });

    testWidgets('renders nested ObservationDetailsCard for modern entries', (
      WidgetTester tester,
    ) async {
      final date = DateTime(2026, 8, 3);
      final obs = Observation(
        id: 'obs-1',
        userId: 'user-1',
        timestamp: DateTime(2026, 8, 3, 11, 0),
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: '',
        isVdrsExplicit: true,
      );

      final entry = DailyEntry(
        date: date,
        resolvedVdrsCode: '10K',
        stampType: StampType.whiteBaby,
        observations: [obs],
        painLevel: 0,
        painTypes: [],
        comments: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineItemCard(
              date: date,
              entry: entry,
              cycle: null,
              dayNumber: 10,
              isCycleStart: false,
              isToday: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Day 10'), findsOneWidget);
      expect(find.byType(ObservationDetailsCard), findsOneWidget);
    });

    testWidgets(
      'renders legacy summary chips and comments when observations list is empty',
      (WidgetTester tester) async {
        final date = DateTime(2026, 8, 3);
        final entry = DailyEntry(
          date: date,
          resolvedVdrsCode: '10K',
          stampType: StampType.whiteBaby,
          observations: [],
          painLevel: 5,
          painTypes: ['Cramping'],
          comments: 'Legacy comment notes',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimelineItemCard(
                date: date,
                entry: entry,
                cycle: null,
                dayNumber: 2,
                isCycleStart: false,
                isToday: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('10K'), findsWidgets);
        expect(find.text('Pain: 5/10 (Cramping)'), findsOneWidget);
        expect(find.text('"Legacy comment notes"'), findsOneWidget);
      },
    );
  });
}
