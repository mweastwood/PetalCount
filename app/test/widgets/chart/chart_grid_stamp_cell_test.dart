import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/chart/chart_grid_stamp_cell.dart';

void main() {
  group('ChartGridStampCell Tests', () {
    final dayDate = DateTime(2026, 8, 3);
    final cycle = Cycle(
      id: 'cycle-1',
      startDate: DateTime(2026, 8, 1),
      bipCodes: const [],
    );

    Widget buildCell(DailyEntry? entry) {
      return MaterialApp(
        home: Scaffold(
          body: ChartGridStampCell(
            entry: entry,
            dayNum: 3,
            dayDate: dayDate,
            cycle: cycle,
            onSelectEntry: (_, _) {},
            onAddForDate: (_, _) {},
          ),
        ),
      );
    }

    testWidgets(
      'hides notes indicator when entry only contains legacy Intercourse comment',
      (WidgetTester tester) async {
        final obs = Observation(
          id: 'obs-1',
          timestamp: DateTime(2026, 8, 3, 22, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          intercourse: true,
          comment: 'Intercourse',
          userId: 'user-1',
        );
        final entry = DailyEntry(
          date: dayDate,
          resolvedVdrsCode: '0 I',
          stampType: StampType.green,
          observations: [obs],
          painLevel: 0,
          painTypes: const [],
          comments: 'Intercourse',
        );

        await tester.pumpWidget(buildCell(entry));

        expect(find.byIcon(Icons.notes), findsNothing);
      },
    );

    testWidgets(
      'shows notes indicator when legacy Intercourse comment includes user note',
      (WidgetTester tester) async {
        final obs = Observation(
          id: 'obs-2',
          timestamp: DateTime(2026, 8, 3, 22, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          intercourse: true,
          comment: 'Intercourse • Evening note',
          userId: 'user-1',
        );
        final entry = DailyEntry(
          date: dayDate,
          resolvedVdrsCode: '0 I',
          stampType: StampType.green,
          observations: [obs],
          painLevel: 0,
          painTypes: const [],
          comments: 'Intercourse • Evening note',
        );

        await tester.pumpWidget(buildCell(entry));

        expect(find.byIcon(Icons.notes), findsOneWidget);
      },
    );

    testWidgets(
      'shows notes indicator when literal Intercourse comment has intercourse false',
      (WidgetTester tester) async {
        final obs = Observation(
          id: 'obs-3',
          timestamp: DateTime(2026, 8, 3, 22, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          intercourse: false,
          comment: 'Intercourse',
          userId: 'user-1',
        );
        final entry = DailyEntry(
          date: dayDate,
          resolvedVdrsCode: '0',
          stampType: StampType.green,
          observations: [obs],
          painLevel: 0,
          painTypes: const [],
          comments: 'Intercourse',
        );

        await tester.pumpWidget(buildCell(entry));

        expect(find.byIcon(Icons.notes), findsOneWidget);
      },
    );
  });
}
