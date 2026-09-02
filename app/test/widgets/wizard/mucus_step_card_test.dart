import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/observation.dart';
import 'package:petal_count/widgets/wizard/mucus_step_card.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';

void main() {
  group('MucusStepCard Unit & Widget Tests', () {
    group('Presence Sub-Step (MucusSubStep.presence)', () {
      testWidgets('renders title, subtitle, and presence option cards', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: MucusStepCard(subStep: MucusSubStep.presence)),
          ),
        );

        expect(find.text('Mucus Observation'), findsOneWidget);
        expect(
          find.text('Do you observe any visible mucus at this observation?'),
          findsOneWidget,
        );

        expect(find.text('No Mucus'), findsOneWidget);
        expect(find.text('No visible mucus observed'), findsOneWidget);
        expect(find.byIcon(Icons.block), findsOneWidget);

        expect(find.text('Yes Mucus'), findsOneWidget);
        expect(find.text('Visible mucus present'), findsOneWidget);
        expect(find.byIcon(Icons.bubble_chart), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(2));
      });

      testWidgets('reflects selection state for hasMucus', (
        WidgetTester tester,
      ) async {
        // hasMucus == false
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.presence,
                hasMucus: false,
              ),
            ),
          ),
        );

        var noCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'No Mucus'),
        );
        var yesCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes Mucus'),
        );
        expect(noCard.isSelected, isTrue);
        expect(yesCard.isSelected, isFalse);

        // hasMucus == true
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.presence,
                hasMucus: true,
              ),
            ),
          ),
        );

        noCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'No Mucus'),
        );
        yesCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes Mucus'),
        );
        expect(noCard.isSelected, isFalse);
        expect(yesCard.isSelected, isTrue);

        // hasMucus == null
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.presence,
                hasMucus: null,
              ),
            ),
          ),
        );

        noCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'No Mucus'),
        );
        yesCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes Mucus'),
        );
        expect(noCard.isSelected, isFalse);
        expect(yesCard.isSelected, isFalse);
      });

      testWidgets(
        'fires onSelectHasMucus callback with boolean value when tapped',
        (WidgetTester tester) async {
          bool? selectedValue;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MucusStepCard(
                  subStep: MucusSubStep.presence,
                  onSelectHasMucus: (val) {
                    selectedValue = val;
                  },
                ),
              ),
            ),
          );

          await tester.tap(find.text('No Mucus'));
          expect(selectedValue, isFalse);

          await tester.tap(find.text('Yes Mucus'));
          expect(selectedValue, isTrue);
        },
      );
    });

    group('Stretch Sub-Step (MucusSubStep.stretch)', () {
      testWidgets(
        'renders title, subtitle, stretch option cards with width factors',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: MucusStepCard(subStep: MucusSubStep.stretch),
              ),
            ),
          );

          expect(find.text('Finger Test Stretch'), findsOneWidget);
          expect(
            find.text(
              'When performing the finger test, how far does the mucus stretch before breaking?',
            ),
            findsOneWidget,
          );

          expect(find.text('Sticky'), findsOneWidget);
          expect(find.text('< 1/4 inch stretch'), findsOneWidget);
          expect(find.byIcon(Icons.straighten), findsOneWidget);

          expect(find.text('Tacky'), findsOneWidget);
          expect(find.text('1/4 to 3/4 inch stretch'), findsOneWidget);
          expect(find.byIcon(Icons.height), findsOneWidget);

          expect(find.text('Stretchy (10)'), findsOneWidget);
          expect(find.text('>= 1 inch stretch'), findsOneWidget);
          expect(find.byIcon(Icons.unfold_more), findsOneWidget);

          final fractionBoxes = tester
              .widgetList<FractionallySizedBox>(
                find.byType(FractionallySizedBox),
              )
              .toList();
          expect(fractionBoxes.length, 3);
          expect(fractionBoxes[0].widthFactor, 0.5);
          expect(fractionBoxes[1].widthFactor, 0.75);
          expect(fractionBoxes[2].widthFactor, 1.0);
        },
      );

      testWidgets('reflects selection state for Stretch enums', (
        WidgetTester tester,
      ) async {
        final stretches = [
          (Stretch.sticky, 'Sticky'),
          (Stretch.tacky, 'Tacky'),
          (Stretch.stretchy, 'Stretchy (10)'),
        ];

        for (final (stretchVal, label) in stretches) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MucusStepCard(
                  subStep: MucusSubStep.stretch,
                  stretch: stretchVal,
                ),
              ),
            ),
          );

          for (final (_, otherLabel) in stretches) {
            final card = tester.widget<OptionCard>(
              find.widgetWithText(OptionCard, otherLabel),
            );
            expect(
              card.isSelected,
              otherLabel == label,
              reason:
                  'Card $otherLabel selection check for stretch $stretchVal',
            );
          }
        }
      });

      testWidgets('fires onSelectStretch callback with correct Stretch enum', (
        WidgetTester tester,
      ) async {
        Stretch? selectedStretch;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.stretch,
                onSelectStretch: (s) {
                  selectedStretch = s;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Sticky'));
        expect(selectedStretch, Stretch.sticky);

        await tester.tap(find.text('Tacky'));
        expect(selectedStretch, Stretch.tacky);

        await tester.tap(find.text('Stretchy (10)'));
        expect(selectedStretch, Stretch.stretchy);
      });
    });

    group('Color Sub-Step (MucusSubStep.color)', () {
      testWidgets('renders title, subtitle, and 6 mucus color options', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: MucusStepCard(subStep: MucusSubStep.color)),
          ),
        );

        expect(find.text('Mucus Color'), findsOneWidget);
        expect(
          find.text('Select the observed color of the mucus:'),
          findsOneWidget,
        );

        expect(find.text('Cloudy (C)'), findsOneWidget);
        expect(find.text('Opaque / off-white'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);

        expect(find.text('Clear (K)'), findsOneWidget);
        expect(find.text('Transparent egg-white'), findsOneWidget);
        expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

        expect(find.text('Cloudy/Clear (C/K)'), findsOneWidget);
        expect(find.text('Mix of clear & cloudy'), findsOneWidget);
        expect(find.byIcon(Icons.wb_cloudy_outlined), findsOneWidget);

        expect(find.text('Yellow (Y)'), findsOneWidget);
        expect(find.text('Yellowish tinge'), findsOneWidget);
        expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

        expect(find.text('Red (R)'), findsOneWidget);
        expect(find.text('Red-tinged / bleeding'), findsOneWidget);
        expect(find.byIcon(Icons.water_drop), findsOneWidget);

        expect(find.text('Black/Brown (B)'), findsOneWidget);
        expect(find.text('Brown or blackish'), findsOneWidget);
        expect(find.byIcon(Icons.circle), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(6));
      });

      testWidgets(
        'reflects single-selection and combo-selection state for colors',
        (WidgetTester tester) async {
          final scenarios = [
            ([MucusColor.cloudy], 'Cloudy (C)'),
            ([MucusColor.clear], 'Clear (K)'),
            ([MucusColor.cloudy, MucusColor.clear], 'Cloudy/Clear (C/K)'),
            ([MucusColor.yellow], 'Yellow (Y)'),
            ([MucusColor.red], 'Red (R)'),
            ([MucusColor.brown], 'Black/Brown (B)'),
          ];

          for (final (colorList, expectedLabel) in scenarios) {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: MucusStepCard(
                    subStep: MucusSubStep.color,
                    selectedColors: colorList,
                  ),
                ),
              ),
            );

            for (final (_, label) in scenarios) {
              final finder = find.widgetWithText(OptionCard, label);
              await tester.ensureVisible(finder);
              final card = tester.widget<OptionCard>(finder);
              expect(
                card.isSelected,
                label == expectedLabel,
                reason: 'Card $label selection check for $colorList',
              );
            }
          }
        },
      );

      testWidgets(
        'fires onSelectColors callback with corresponding color lists',
        (WidgetTester tester) async {
          List<MucusColor>? selectedList;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MucusStepCard(
                  subStep: MucusSubStep.color,
                  onSelectColors: (list) {
                    selectedList = list;
                  },
                ),
              ),
            ),
          );

          final cloudyFinder = find.text('Cloudy (C)');
          await tester.ensureVisible(cloudyFinder);
          await tester.tap(cloudyFinder);
          expect(selectedList, [MucusColor.cloudy]);

          final clearFinder = find.text('Clear (K)');
          await tester.ensureVisible(clearFinder);
          await tester.tap(clearFinder);
          expect(selectedList, [MucusColor.clear]);

          final comboFinder = find.text('Cloudy/Clear (C/K)');
          await tester.ensureVisible(comboFinder);
          await tester.tap(comboFinder);
          expect(selectedList, [MucusColor.cloudy, MucusColor.clear]);

          final yellowFinder = find.text('Yellow (Y)');
          await tester.ensureVisible(yellowFinder);
          await tester.tap(yellowFinder);
          expect(selectedList, [MucusColor.yellow]);

          final redFinder = find.text('Red (R)');
          await tester.ensureVisible(redFinder);
          await tester.tap(redFinder);
          expect(selectedList, [MucusColor.red]);

          final brownFinder = find.text('Black/Brown (B)');
          await tester.ensureVisible(brownFinder);
          await tester.tap(brownFinder);
          expect(selectedList, [MucusColor.brown]);
        },
      );
    });

    group('Consistency Sub-Step (MucusSubStep.consistency)', () {
      testWidgets('renders title, subtitle, and consistency option cards', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(subStep: MucusSubStep.consistency),
            ),
          ),
        );

        expect(find.text('Mucus Consistency'), findsOneWidget);
        expect(
          find.text(
            'Optionally select special physical characteristics of the mucus:',
          ),
          findsOneWidget,
        );

        expect(find.text('Neither'), findsOneWidget);
        expect(find.text('Standard mucus consistency'), findsOneWidget);
        expect(find.byIcon(Icons.do_not_disturb_alt), findsOneWidget);

        expect(find.text('Gummy (Gluey)'), findsOneWidget);
        expect(find.text('Rubber-like or gluey texture'), findsOneWidget);
        expect(find.byIcon(Icons.bubble_chart_outlined), findsOneWidget);

        expect(find.text('Pasty (Creamy)'), findsOneWidget);
        expect(find.text('Creamy or pasty texture'), findsOneWidget);
        expect(find.byIcon(Icons.format_paint_outlined), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(3));
      });

      testWidgets('reflects selection state for Neither, Gummy, and Pasty', (
        WidgetTester tester,
      ) async {
        // Neither selected
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.consistency,
                isGummy: false,
                isPasty: false,
                hasSelectedConsistency: true,
              ),
            ),
          ),
        );

        var neitherCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Neither'),
        );
        var gummyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Gummy (Gluey)'),
        );
        var pastyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Pasty (Creamy)'),
        );
        expect(neitherCard.isSelected, isTrue);
        expect(gummyCard.isSelected, isFalse);
        expect(pastyCard.isSelected, isFalse);

        // Gummy selected
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.consistency,
                isGummy: true,
                isPasty: false,
                hasSelectedConsistency: true,
              ),
            ),
          ),
        );

        neitherCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Neither'),
        );
        gummyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Gummy (Gluey)'),
        );
        pastyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Pasty (Creamy)'),
        );
        expect(neitherCard.isSelected, isFalse);
        expect(gummyCard.isSelected, isTrue);
        expect(pastyCard.isSelected, isFalse);

        // Pasty selected
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.consistency,
                isGummy: false,
                isPasty: true,
                hasSelectedConsistency: true,
              ),
            ),
          ),
        );

        neitherCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Neither'),
        );
        gummyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Gummy (Gluey)'),
        );
        pastyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Pasty (Creamy)'),
        );
        expect(neitherCard.isSelected, isFalse);
        expect(gummyCard.isSelected, isFalse);
        expect(pastyCard.isSelected, isTrue);

        // Nothing selected
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.consistency,
                isGummy: false,
                isPasty: false,
                hasSelectedConsistency: false,
              ),
            ),
          ),
        );

        neitherCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Neither'),
        );
        gummyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Gummy (Gluey)'),
        );
        pastyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Pasty (Creamy)'),
        );
        expect(neitherCard.isSelected, isFalse);
        expect(gummyCard.isSelected, isFalse);
        expect(pastyCard.isSelected, isFalse);
      });

      testWidgets('fires onSelectConsistency callback with named parameters', (
        WidgetTester tester,
      ) async {
        bool? passedGummy;
        bool? passedPasty;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MucusStepCard(
                subStep: MucusSubStep.consistency,
                onSelectConsistency:
                    ({required bool isGummy, required bool isPasty}) {
                      passedGummy = isGummy;
                      passedPasty = isPasty;
                    },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Neither'));
        expect(passedGummy, isFalse);
        expect(passedPasty, isFalse);

        await tester.tap(find.text('Gummy (Gluey)'));
        expect(passedGummy, isTrue);
        expect(passedPasty, isFalse);

        await tester.tap(find.text('Pasty (Creamy)'));
        expect(passedGummy, isFalse);
        expect(passedPasty, isTrue);
      });
    });

    group('Null-Safety', () {
      testWidgets(
        'does not throw when tapped with null callbacks across substeps',
        (WidgetTester tester) async {
          // Presence
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: MucusStepCard(
                  subStep: MucusSubStep.presence,
                  onSelectHasMucus: null,
                ),
              ),
            ),
          );
          await tester.tap(find.text('No Mucus'));
          await tester.tap(find.text('Yes Mucus'));
          await tester.pumpAndSettle();

          // Stretch
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: MucusStepCard(
                  subStep: MucusSubStep.stretch,
                  onSelectStretch: null,
                ),
              ),
            ),
          );
          await tester.tap(find.text('Sticky'));
          await tester.tap(find.text('Tacky'));
          await tester.tap(find.text('Stretchy (10)'));
          await tester.pumpAndSettle();

          // Color
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: MucusStepCard(
                  subStep: MucusSubStep.color,
                  onSelectColors: null,
                ),
              ),
            ),
          );
          final colorItem = find.text('Cloudy (C)');
          await tester.ensureVisible(colorItem);
          await tester.tap(colorItem);
          await tester.pumpAndSettle();

          // Consistency
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: MucusStepCard(
                  subStep: MucusSubStep.consistency,
                  onSelectConsistency: null,
                ),
              ),
            ),
          );
          await tester.tap(find.text('Neither'));
          await tester.tap(find.text('Gummy (Gluey)'));
          await tester.tap(find.text('Pasty (Creamy)'));
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
