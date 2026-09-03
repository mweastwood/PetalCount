import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/observation.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';
import 'package:petal_count/widgets/wizard/sensation_step_card.dart';

void main() {
  group('SensationStepCard Unit & Widget Tests', () {
    group('Vulva Sensation Step (isLubricationStep == false)', () {
      testWidgets('renders title, subtitle, and sensation option cards', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SensationStepCard(isLubricationStep: false)),
          ),
        );

        expect(find.text('Sensation at Vulva'), findsOneWidget);
        expect(
          find.text(
            'What sensation do you feel at the vulva right now during normal daily routine?',
          ),
          findsOneWidget,
        );

        expect(find.text('Dry'), findsOneWidget);
        expect(find.text('No sensation of moisture'), findsOneWidget);
        expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);

        expect(find.text('Wet'), findsOneWidget);
        expect(find.text('Definite sensation of moisture'), findsOneWidget);
        expect(find.byIcon(Icons.water), findsOneWidget);

        expect(find.text('Damp'), findsOneWidget);
        expect(find.text('Slight feeling of dampness'), findsOneWidget);
        expect(find.byIcon(Icons.opacity), findsOneWidget);

        expect(find.text('Shiny / Smooth'), findsOneWidget);
        expect(find.text('Slick or smooth feeling'), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(4));
      });

      testWidgets('reflects selection state for each Sensation enum', (
        WidgetTester tester,
      ) async {
        final sensations = [
          (Sensation.dry, 'Dry'),
          (Sensation.wet, 'Wet'),
          (Sensation.damp, 'Damp'),
          (Sensation.shiny, 'Shiny / Smooth'),
        ];

        for (final (sens, label) in sensations) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SensationStepCard(
                  isLubricationStep: false,
                  sensation: sens,
                ),
              ),
            ),
          );

          for (final (_, otherLabel) in sensations) {
            final card = tester.widget<OptionCard>(
              find.widgetWithText(OptionCard, otherLabel),
            );
            expect(
              card.isSelected,
              otherLabel == label,
              reason: 'Card $otherLabel selection check for sensation $sens',
            );
          }
        }
      });

      testWidgets('reflects unselected state when sensation is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SensationStepCard(
                isLubricationStep: false,
                sensation: null,
              ),
            ),
          ),
        );

        final cards = tester.widgetList<OptionCard>(find.byType(OptionCard));
        for (final card in cards) {
          expect(card.isSelected, isFalse);
        }
      });

      testWidgets(
        'fires onSelectSensation callback with correct enum when tapped',
        (WidgetTester tester) async {
          Sensation? selected;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SensationStepCard(
                  isLubricationStep: false,
                  onSelectSensation: (val) {
                    selected = val;
                  },
                ),
              ),
            ),
          );

          await tester.tap(find.text('Dry'));
          expect(selected, Sensation.dry);

          await tester.tap(find.text('Wet'));
          expect(selected, Sensation.wet);

          await tester.tap(find.text('Damp'));
          expect(selected, Sensation.damp);

          await tester.tap(find.text('Shiny / Smooth'));
          expect(selected, Sensation.shiny);
        },
      );
    });

    group('Lubrication Step (isLubricationStep == true)', () {
      testWidgets('renders title, subtitle, and lubrication option cards', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SensationStepCard(isLubricationStep: true)),
          ),
        );

        expect(find.text('Lubricative Sensation'), findsOneWidget);
        expect(
          find.text(
            'Was there a distinctly lubricative or slippery sensation?',
          ),
          findsOneWidget,
        );

        expect(find.text('Not Lubricative'), findsOneWidget);
        expect(find.text('No slippery feeling'), findsOneWidget);
        expect(find.byIcon(Icons.do_not_disturb), findsOneWidget);

        expect(find.text('Yes Lubrication'), findsOneWidget);
        expect(find.text('Slippery / lubricative feel'), findsOneWidget);
        expect(find.byIcon(Icons.clean_hands), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(2));
      });

      testWidgets('reflects selection state for hasLubrication', (
        WidgetTester tester,
      ) async {
        // hasLubrication == false
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SensationStepCard(
                isLubricationStep: true,
                hasLubrication: false,
              ),
            ),
          ),
        );

        var notLubCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Not Lubricative'),
        );
        var yesLubCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes Lubrication'),
        );
        expect(notLubCard.isSelected, isTrue);
        expect(yesLubCard.isSelected, isFalse);

        // hasLubrication == true
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SensationStepCard(
                isLubricationStep: true,
                hasLubrication: true,
              ),
            ),
          ),
        );

        notLubCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Not Lubricative'),
        );
        yesLubCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes Lubrication'),
        );
        expect(notLubCard.isSelected, isFalse);
        expect(yesLubCard.isSelected, isTrue);

        // hasLubrication == null
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SensationStepCard(
                isLubricationStep: true,
                hasLubrication: null,
              ),
            ),
          ),
        );

        notLubCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Not Lubricative'),
        );
        yesLubCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes Lubrication'),
        );
        expect(notLubCard.isSelected, isFalse);
        expect(yesLubCard.isSelected, isFalse);
      });

      testWidgets('fires onSelectLubrication callback with boolean parameter', (
        WidgetTester tester,
      ) async {
        bool? selectedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SensationStepCard(
                isLubricationStep: true,
                onSelectLubrication: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Not Lubricative'));
        expect(selectedValue, isFalse);

        await tester.tap(find.text('Yes Lubrication'));
        expect(selectedValue, isTrue);
      });
    });

    group('Null-Safety', () {
      testWidgets('does not throw when tapped with null callbacks', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SensationStepCard(
                isLubricationStep: false,
                onSelectSensation: null,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Dry'));
        await tester.tap(find.text('Wet'));
        await tester.tap(find.text('Damp'));
        await tester.tap(find.text('Shiny / Smooth'));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SensationStepCard(
                isLubricationStep: true,
                onSelectLubrication: null,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Not Lubricative'));
        await tester.tap(find.text('Yes Lubrication'));
        await tester.pumpAndSettle();
      });
    });
  });
}
