import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/daily_entry.dart';
import 'package:petal_count/theme/creighton_theme.dart';
import 'package:petal_count/widgets/baby_icon.dart';
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
          expect(find.byType(BabyIcon), findsOneWidget);
        } else {
          expect(find.byType(BabyIcon), findsNothing);
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
      expect(find.byType(BabyIcon), findsNothing);
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
      expect(find.byType(BabyIcon), findsOneWidget);
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
      expect(find.byType(BabyIcon), findsOneWidget);
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
      expect(find.byType(BabyIcon), findsNothing);
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
        expect(find.byType(BabyIcon), findsOneWidget);
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
      expect(find.byType(BabyIcon), findsNothing);
    });
  });

  group('BabyIcon scaling and positioning', () {
    Positioned getBabyPositioned(WidgetTester tester) {
      return tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(BabyIcon),
          matching: find.byType(Positioned),
        ),
      );
    }

    testWidgets(
      'BabyIcon size scales to 75% of container height across modes without label',
      (tester) async {
        // Badge mode (48.0 height -> 36.0 icon size, vertically centered)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.badge(stampType: StampType.greenBaby),
            ),
          ),
        );
        var babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        var positioned = getBabyPositioned(tester);
        expect(babyIcon.size, equals(36.0));
        expect(positioned.bottom, equals(6.0));

        // Grid sticker mode (46.0 height -> 34.5 icon size)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.gridSticker(
                stampType: StampType.whiteBaby,
              ),
            ),
          ),
        );
        babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        expect(babyIcon.size, equals(34.5));

        // Timeline node mode (52.0 height -> 39.0 icon size)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.timelineNode(
                stampType: StampType.yellowBaby,
              ),
            ),
          ),
        );
        babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        expect(babyIcon.size, equals(39.0));
      },
    );

    testWidgets(
      'BabyIcon size scales with explicit height override across modes',
      (tester) async {
        // Badge mode with explicit height = 100 -> 75.0 icon size, centered
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.badge(
                stampType: StampType.greenBaby,
                height: 100.0,
              ),
            ),
          ),
        );
        var babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        var positioned = getBabyPositioned(tester);
        expect(babyIcon.size, equals(75.0));
        expect(positioned.bottom, equals(12.5));

        // Grid sticker mode with explicit height = 100 -> 75.0 icon size
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.gridSticker(
                stampType: StampType.whiteBaby,
                height: 100.0,
              ),
            ),
          ),
        );
        babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        expect(babyIcon.size, equals(75.0));

        // Timeline node mode with explicit size = 100 -> 75.0 icon size
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.timelineNode(
                stampType: StampType.yellowBaby,
                size: 100.0,
              ),
            ),
          ),
        );
        babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        expect(babyIcon.size, equals(75.0));
      },
    );

    testWidgets(
      'Badge caps baby size and pins bottom: 2 when peakDayLabel is present',
      (tester) async {
        // Default height (48.0) with peakDayLabel:
        // 48.0 * 0.75 = 36.0 would overlap label at top: 2.
        // Capped to 48.0 - 16.0 = 32.0, pinned at bottom: 2.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.badge(
                stampType: StampType.whiteBaby,
                peakDayLabel: 'P',
              ),
            ),
          ),
        );
        var babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        var positioned = getBabyPositioned(tester);
        expect(babyIcon.size, equals(32.0));
        expect(positioned.bottom, equals(2.0));
        expect(find.text('P'), findsOneWidget);

        // Height override (100.0) with peakDayLabel:
        // 100.0 * 0.75 = 75.0 fits within maxIconHeight (100 - 16 = 84), pinned at bottom: 2.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.badge(
                stampType: StampType.greenBaby,
                peakDayLabel: '1',
                height: 100.0,
              ),
            ),
          ),
        );
        babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
        positioned = getBabyPositioned(tester);
        expect(babyIcon.size, equals(75.0));
        expect(positioned.bottom, equals(2.0));
        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets('Badge with small height does not throw ArgumentError', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreightonStampWidget.badge(
              stampType: StampType.whiteBaby,
              peakDayLabel: 'P',
              height: 12.0,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final babyIcon = tester.widget<BabyIcon>(find.byType(BabyIcon));
      expect(babyIcon.size, equals(0.0));
    });

    testWidgets(
      'Stack children order ensures peakDayLabel renders on top of BabyIcon across modes',
      (tester) async {
        // Badge mode: BabyIcon at index 0, peakDayLabel at index 1
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.badge(
                stampType: StampType.whiteBaby,
                peakDayLabel: 'P',
              ),
            ),
          ),
        );
        var stack = tester.widget<Stack>(find.byType(Stack));
        expect(stack.children.length, equals(2));
        expect(
          find.descendant(
            of: find.byWidget(stack.children[0]),
            matching: find.byType(BabyIcon),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byWidget(stack.children[1]),
            matching: find.text('P'),
          ),
          findsOneWidget,
        );

        // Grid sticker mode: BabyIcon at index 0, peakDayLabel at index 1
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
        stack = tester.widget<Stack>(find.byType(Stack));
        expect(stack.children.length, equals(2));
        expect(
          find.descendant(
            of: find.byWidget(stack.children[0]),
            matching: find.byType(BabyIcon),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byWidget(stack.children[1]),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );

        // Timeline node mode: BabyIcon at index 0, peakDayLabel at index 1
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreightonStampWidget.timelineNode(
                stampType: StampType.yellowBaby,
                peakDayLabel: '2',
              ),
            ),
          ),
        );
        stack = tester.widget<Stack>(find.byType(Stack));
        expect(stack.children.length, equals(2));
        expect(
          find.descendant(
            of: find.byWidget(stack.children[0]),
            matching: find.byType(BabyIcon),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byWidget(stack.children[1]),
            matching: find.text('2'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
