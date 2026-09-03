import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/widgets/timeline/timeline_summary_chip.dart';

void main() {
  group('TimelineSummaryChip Unit & Widget Tests', () {
    testWidgets(
      'renders icon, label, background color, and border decoration',
      (WidgetTester tester) async {
        const iconData = Icons.water_drop;
        const labelText = '10WLK';
        const foregroundColor = Colors.blue;
        const backgroundColor = Color(0x332196F3);
        const borderColor = Colors.blueAccent;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: TimelineSummaryChip(
                  icon: iconData,
                  label: labelText,
                  color: foregroundColor,
                  bgColor: backgroundColor,
                  borderColor: borderColor,
                ),
              ),
            ),
          ),
        );

        // Verify Icon widget
        final iconFinder = find.byIcon(iconData);
        expect(iconFinder, findsOneWidget);
        final iconWidget = tester.widget<Icon>(iconFinder);
        expect(iconWidget.icon, equals(iconData));
        expect(iconWidget.size, equals(14));
        expect(iconWidget.color, equals(foregroundColor));

        // Verify Text widget
        final textFinder = find.text(labelText);
        expect(textFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.data, equals(labelText));

        // Verify Container decoration and padding
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);
        final containerWidget = tester.widget<Container>(containerFinder);
        expect(
          containerWidget.padding,
          equals(const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        );

        final decoration = containerWidget.decoration as BoxDecoration;
        expect(decoration.color, equals(backgroundColor));
        expect(decoration.borderRadius, equals(BorderRadius.circular(6)));
        expect(decoration.border, equals(Border.all(color: borderColor)));
      },
    );

    testWidgets('verifies text styling, typography, and Row layout structure', (
      WidgetTester tester,
    ) async {
      const textColor = Colors.red;
      const labelText = 'Heavy (Red)';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimelineSummaryChip(
              icon: Icons.bloodtype,
              label: labelText,
              color: textColor,
              bgColor: Colors.redAccent,
              borderColor: Colors.red,
            ),
          ),
        ),
      );

      // Verify Text style
      final textWidget = tester.widget<Text>(find.text(labelText));
      expect(textWidget.style?.fontSize, equals(11));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w600));
      expect(textWidget.style?.color, equals(textColor));

      // Verify Row structure and sizing
      final rowFinder = find.byType(Row);
      expect(rowFinder, findsOneWidget);
      final rowWidget = tester.widget<Row>(rowFinder);
      expect(rowWidget.mainAxisSize, equals(MainAxisSize.min));
      expect(rowWidget.children.length, equals(3));

      // Verify Icon child
      final iconChild = rowWidget.children[0] as Icon;
      expect(iconChild.icon, equals(Icons.bloodtype));
      expect(iconChild.size, equals(14));
      expect(iconChild.color, equals(textColor));

      // Verify SizedBox spacing between icon and text
      final sizedBoxChild = rowWidget.children[1] as SizedBox;
      expect(sizedBoxChild.width, equals(4));

      // Verify Flexible wrapper on Text
      final flexibleChild = rowWidget.children[2] as Flexible;
      expect(flexibleChild.child, isA<Text>());
      final innerText = flexibleChild.child as Text;
      expect(innerText.data, equals(labelText));
    });

    testWidgets(
      'renders cleanly without overflow exceptions when label is long',
      (WidgetTester tester) async {
        const longLabel =
            'Extremely long sensation description that exceeds typical chip boundaries in narrow containers';

        // Constrain parent width to a narrow 80 pixels
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 80,
                  child: TimelineSummaryChip(
                    icon: Icons.bubble_chart,
                    label: longLabel,
                    color: Colors.teal,
                    bgColor: Colors.tealAccent,
                    borderColor: Colors.teal,
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify widget rendered and no overflow FlutterError was thrown
        expect(find.text(longLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('adapts properly within light and dark theme contexts', (
      WidgetTester tester,
    ) async {
      for (final themeData in [ThemeData.light(), ThemeData.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: themeData,
            home: const Scaffold(
              body: Center(
                child: TimelineSummaryChip(
                  icon: Icons.healing,
                  label: 'Pain: 3/10',
                  color: Colors.purple,
                  bgColor: Colors.purpleAccent,
                  borderColor: Colors.deepPurple,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(TimelineSummaryChip), findsOneWidget);
        expect(find.text('Pain: 3/10'), findsOneWidget);
        expect(find.byIcon(Icons.healing), findsOneWidget);

        final containerWidget = tester.widget<Container>(
          find.byType(Container),
        );
        final decoration = containerWidget.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.purpleAccent));
        expect(decoration.border, equals(Border.all(color: Colors.deepPurple)));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
