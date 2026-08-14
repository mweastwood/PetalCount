import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/daily_entry.dart';
import 'package:petal_count/theme/creighton_theme.dart';
import 'package:petal_count/widgets/creighton_stamp_widget.dart';

void main() {
  group('CreightonStampWidget Unit & Widget Tests', () {
    testWidgets('Renders badge mode with all StampType variants', (
      tester,
    ) async {
      final stampTypes = [
        StampType.red,
        StampType.green,
        StampType.whiteBaby,
        StampType.greenBaby,
        StampType.yellow,
        StampType.yellowBaby,
      ];

      for (final type in stampTypes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.badge(
                stampType: type,
                peakDayLabel: 'P',
              ),
            ),
          ),
        );

        expect(find.byType(CreightonStampWidget), findsOneWidget);
        expect(find.text('P'), findsOneWidget);

        if (CreightonTheme.hasBabyIcon(type)) {
          expect(find.byIcon(Icons.child_care), findsOneWidget);
        } else {
          expect(find.byIcon(Icons.child_care), findsNothing);
        }
      }
    });

    testWidgets('Renders gridSticker mode for unlogged / null entry with ?', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreightonStampWidget.gridSticker(
              stampType: null,
              peakDayLabel: null,
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsNothing);
    });

    testWidgets('Renders gridSticker mode with peak badge and baby icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreightonStampWidget.gridSticker(
              stampType: StampType.whiteBaby,
              peakDayLabel: 'P',
            ),
          ),
        ),
      );

      expect(find.text('P'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsOneWidget);
    });

    testWidgets('Renders gridSticker mode with greenBaby stamp', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreightonStampWidget.gridSticker(
              stampType: StampType.greenBaby,
              peakDayLabel: '1',
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsOneWidget);
    });

    testWidgets('Renders timelineNode mode with dayNumber and peak labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreightonStampWidget.timelineNode(
              stampType: StampType.red,
              peakDayLabel: null,
              dayNumber: 3,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsNothing);
    });

    testWidgets(
      'Renders timelineNode mode with baby icon overriding dayNumber',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.timelineNode(
                stampType: StampType.yellowBaby,
                peakDayLabel: '2',
                dayNumber: 15,
              ),
            ),
          ),
        );

        expect(find.text('2'), findsOneWidget);
        expect(find.byIcon(Icons.child_care), findsOneWidget);
        expect(find.text('15'), findsNothing);
      },
    );

    testWidgets('Renders default CreightonStampWidget constructor', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreightonStampWidget(
              stampType: StampType.green,
              peakDayLabel: '3',
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsNothing);
    });
  });
}
