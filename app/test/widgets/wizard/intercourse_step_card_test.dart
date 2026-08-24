import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/widgets/wizard/intercourse_step_card.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';

void main() {
  group('IntercourseStepCard Unit & Widget Tests', () {
    testWidgets('renders static texts, headers, icons, and option cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: IntercourseStepCard())),
      );

      expect(find.text('Log Intercourse / Intimacy'), findsOneWidget);
      expect(
        find.text(
          'Record whether intercourse occurred at this observation time:',
        ),
        findsOneWidget,
      );

      expect(find.text('Intercourse (I)'), findsOneWidget);
      expect(find.text('Intercourse occurred'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      expect(find.text('No Intercourse'), findsOneWidget);
      expect(find.text('No intercourse recorded'), findsOneWidget);
      expect(find.byIcon(Icons.do_not_disturb_alt), findsOneWidget);

      expect(find.byType(OptionCard), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('reflects selection state when hasIntercourse is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IntercourseStepCard(hasIntercourse: true)),
        ),
      );

      final yesCard = tester.widget<OptionCard>(
        find.widgetWithText(OptionCard, 'Intercourse (I)'),
      );
      final noCard = tester.widget<OptionCard>(
        find.widgetWithText(OptionCard, 'No Intercourse'),
      );

      expect(yesCard.isSelected, isTrue);
      expect(noCard.isSelected, isFalse);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('reflects selection state when hasIntercourse is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IntercourseStepCard(hasIntercourse: false)),
        ),
      );

      final yesCard = tester.widget<OptionCard>(
        find.widgetWithText(OptionCard, 'Intercourse (I)'),
      );
      final noCard = tester.widget<OptionCard>(
        find.widgetWithText(OptionCard, 'No Intercourse'),
      );

      expect(yesCard.isSelected, isFalse);
      expect(noCard.isSelected, isTrue);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('reflects unselected state when hasIntercourse is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IntercourseStepCard(hasIntercourse: null)),
        ),
      );

      final yesCard = tester.widget<OptionCard>(
        find.widgetWithText(OptionCard, 'Intercourse (I)'),
      );
      final noCard = tester.widget<OptionCard>(
        find.widgetWithText(OptionCard, 'No Intercourse'),
      );

      expect(yesCard.isSelected, isFalse);
      expect(noCard.isSelected, isFalse);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets(
      'triggers onSelectIntercourse callback with true when Intercourse (I) is tapped',
      (WidgetTester tester) async {
        bool? selectedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: IntercourseStepCard(
                onSelectIntercourse: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Intercourse (I)'));
        await tester.pumpAndSettle();

        expect(selectedValue, isTrue);
      },
    );

    testWidgets(
      'triggers onSelectIntercourse callback with false when No Intercourse is tapped',
      (WidgetTester tester) async {
        bool? selectedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: IntercourseStepCard(
                onSelectIntercourse: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('No Intercourse'));
        await tester.pumpAndSettle();

        expect(selectedValue, isFalse);
      },
    );

    testWidgets(
      'does not throw when tapped with null onSelectIntercourse callback',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: IntercourseStepCard(onSelectIntercourse: null),
            ),
          ),
        );

        await tester.tap(find.text('Intercourse (I)'));
        await tester.tap(find.text('No Intercourse'));
        await tester.pumpAndSettle();
      },
    );
  });
}
