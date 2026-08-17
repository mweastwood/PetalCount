import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/timeline/observation_details_card.dart';
import 'package:petal_count/widgets/timeline/timeline_summary_chip.dart';

void main() {
  group('ObservationDetailsCard Unit & Widget Tests', () {
    testWidgets('renders single observation header and VDRS code badge', (
      WidgetTester tester,
    ) async {
      final obs = Observation(
        id: 'obs-1',
        userId: 'user-1',
        timestamp: DateTime(2026, 8, 3, 14, 30),
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: 'Very lubricative',
        isVdrsExplicit: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationDetailsCard(
              observation: obs,
              index: 0,
              totalCount: 1,
            ),
          ),
        ),
      );

      expect(find.text('Observation • 2:30 PM'), findsOneWidget);
      expect(find.text('10WLK'), findsOneWidget);
      expect(find.text('"Very lubricative"'), findsOneWidget);
      expect(find.byType(TimelineSummaryChip), findsOneWidget);
      expect(
        find.text('Wet • Stretchy (1 inch or more) • Clear • Lubricative'),
        findsOneWidget,
      );
    });

    testWidgets('renders numbered header for multi-observation days', (
      WidgetTester tester,
    ) async {
      final obs = Observation(
        id: 'obs-2',
        userId: 'user-1',
        timestamp: DateTime(2026, 8, 3, 9, 15),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.moderate,
        bleedingColor: 'R',
        painLevel: 4,
        painTypes: ['Cramping'],
        comment: '',
        isVdrsExplicit: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationDetailsCard(
              observation: obs,
              index: 1,
              totalCount: 3,
            ),
          ),
        ),
      );

      expect(find.text('Observation #2 • 9:15 AM'), findsOneWidget);
      expect(find.text('Moderate (Red)'), findsOneWidget);
      expect(find.text('Pain: 4/10 (Cramping)'), findsOneWidget);
      expect(find.byType(TimelineSummaryChip), findsNWidgets(2));
    });

    testWidgets('renders bleeding color brown correctly', (
      WidgetTester tester,
    ) async {
      final obs = Observation(
        id: 'obs-3',
        userId: 'user-1',
        timestamp: DateTime(2026, 8, 3, 18, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.veryLight,
        bleedingColor: 'B',
        painLevel: 0,
        painTypes: [],
        comment: 'Spotting noted',
        isVdrsExplicit: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationDetailsCard(
              observation: obs,
              index: 0,
              totalCount: 1,
            ),
          ),
        ),
      );

      expect(find.text('Very Light (Brown)'), findsOneWidget);
      expect(find.text('"Spotting noted"'), findsOneWidget);
    });
  });
}
