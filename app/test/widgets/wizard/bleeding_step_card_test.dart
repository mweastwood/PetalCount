import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/observation.dart';
import 'package:petal_count/widgets/wizard/bleeding_step_card.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';

void main() {
  group('BleedingStepCard Unit & Widget Tests', () {
    group('Flow Step (isFlowStep == true)', () {
      testWidgets('renders all options and title when showNoBleeding is true', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BleedingStepCard(isFlowStep: true, showNoBleeding: true),
            ),
          ),
        );

        expect(
          find.text('Are you experiencing bleeding at this point in time?'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Select "No Bleeding" or choose the bleeding flow level observed right now:',
          ),
          findsOneWidget,
        );

        expect(find.text('No Bleeding'), findsOneWidget);
        expect(find.text('No bleeding present'), findsOneWidget);
        expect(find.byIcon(Icons.block), findsOneWidget);

        expect(find.text('Heavy (H)'), findsOneWidget);
        expect(find.text('Heavy flow'), findsOneWidget);
        expect(find.byIcon(Icons.water_drop), findsOneWidget);

        expect(find.text('Moderate (M)'), findsOneWidget);
        expect(find.text('Moderate flow'), findsOneWidget);
        expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

        expect(find.text('Light (L)'), findsOneWidget);
        expect(find.text('Light flow'), findsOneWidget);
        expect(find.byIcon(Icons.opacity), findsOneWidget);

        expect(find.text('Very Light (VL)'), findsOneWidget);
        expect(find.text('Very light flow / spotting'), findsOneWidget);
        expect(find.byIcon(Icons.grain), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(5));
      });

      testWidgets(
        'hides No Bleeding option and renders modified header when showNoBleeding is false',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: BleedingStepCard(isFlowStep: true, showNoBleeding: false),
              ),
            ),
          );

          expect(find.text('Select Bleeding Flow Level'), findsOneWidget);
          expect(
            find.text('Choose the bleeding flow level observed right now:'),
            findsOneWidget,
          );
          expect(find.text('No Bleeding'), findsNothing);
          expect(find.byType(OptionCard), findsNWidgets(4));
        },
      );

      testWidgets('reflects selection state for No Bleeding', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BleedingStepCard(
                isFlowStep: true,
                showNoBleeding: true,
                hasBleeding: false,
              ),
            ),
          ),
        );

        final noBleedingCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'No Bleeding'),
        );
        final heavyCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Heavy (H)'),
        );

        expect(noBleedingCard.isSelected, isTrue);
        expect(heavyCard.isSelected, isFalse);
      });

      testWidgets('reflects selection state for flow levels', (
        WidgetTester tester,
      ) async {
        final flows = [
          (Bleeding.heavy, 'Heavy (H)'),
          (Bleeding.moderate, 'Moderate (M)'),
          (Bleeding.light, 'Light (L)'),
          (Bleeding.veryLight, 'Very Light (VL)'),
        ];

        for (final (flow, label) in flows) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BleedingStepCard(
                  isFlowStep: true,
                  hasBleeding: true,
                  bleedingFlow: flow,
                ),
              ),
            ),
          );

          for (final (_, otherLabel) in flows) {
            final card = tester.widget<OptionCard>(
              find.widgetWithText(OptionCard, otherLabel),
            );
            expect(
              card.isSelected,
              otherLabel == label,
              reason: 'Card $otherLabel selection check for flow $flow',
            );
          }
        }
      });

      testWidgets('reflects unselected state when hasBleeding is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BleedingStepCard(isFlowStep: true, hasBleeding: null),
            ),
          ),
        );

        final cards = tester.widgetList<OptionCard>(find.byType(OptionCard));
        for (final card in cards) {
          expect(card.isSelected, isFalse);
        }
        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      });

      testWidgets(
        'fires onSelectNoBleeding callback when No Bleeding is tapped',
        (WidgetTester tester) async {
          bool noBleedingTapped = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BleedingStepCard(
                  isFlowStep: true,
                  showNoBleeding: true,
                  onSelectNoBleeding: () {
                    noBleedingTapped = true;
                  },
                ),
              ),
            ),
          );

          await tester.tap(find.text('No Bleeding'));
          await tester.pumpAndSettle();

          expect(noBleedingTapped, isTrue);
        },
      );

      testWidgets('fires onSelectFlow callback with correct enum when tapped', (
        WidgetTester tester,
      ) async {
        Bleeding? selectedFlow;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BleedingStepCard(
                isFlowStep: true,
                onSelectFlow: (flow) {
                  selectedFlow = flow;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Heavy (H)'));
        expect(selectedFlow, Bleeding.heavy);

        await tester.tap(find.text('Moderate (M)'));
        expect(selectedFlow, Bleeding.moderate);

        await tester.tap(find.text('Light (L)'));
        expect(selectedFlow, Bleeding.light);

        await tester.tap(find.text('Very Light (VL)'));
        expect(selectedFlow, Bleeding.veryLight);
      });
    });

    group('Color Step (isFlowStep == false)', () {
      testWidgets('renders blood color title, subtitle, and option cards', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: BleedingStepCard(isFlowStep: false)),
          ),
        );

        expect(find.text('Blood Color'), findsOneWidget);
        expect(
          find.text('Select the observed color of blood:'),
          findsOneWidget,
        );

        expect(find.text('Red (R)'), findsOneWidget);
        expect(find.text('Bright or dark red blood'), findsOneWidget);
        expect(find.byIcon(Icons.color_lens), findsOneWidget);

        expect(find.text('Brown (B)'), findsOneWidget);
        expect(find.text('Brownish discharge'), findsOneWidget);
        expect(find.byIcon(Icons.color_lens_outlined), findsOneWidget);

        expect(find.text('Black (K)'), findsOneWidget);
        expect(find.text('Blackish old blood'), findsOneWidget);
        expect(find.byIcon(Icons.circle), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(3));
      });

      testWidgets('reflects selection state for bleeding colors', (
        WidgetTester tester,
      ) async {
        final colors = [
          (Bleeding.red.code, 'Red (R)'),
          (Bleeding.brown.code, 'Brown (B)'),
          (Bleeding.black.code, 'Black (K)'),
        ];

        for (final (code, label) in colors) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BleedingStepCard(isFlowStep: false, bleedingColor: code),
              ),
            ),
          );

          for (final (_, otherLabel) in colors) {
            final card = tester.widget<OptionCard>(
              find.widgetWithText(OptionCard, otherLabel),
            );
            expect(
              card.isSelected,
              otherLabel == label,
              reason: 'Card $otherLabel selection check for color code $code',
            );
          }
        }
      });

      testWidgets('fires onSelectColor callback with correct code string', (
        WidgetTester tester,
      ) async {
        String? selectedColor;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BleedingStepCard(
                isFlowStep: false,
                onSelectColor: (c) {
                  selectedColor = c;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Red (R)'));
        expect(selectedColor, Bleeding.red.code);

        await tester.tap(find.text('Brown (B)'));
        expect(selectedColor, Bleeding.brown.code);

        await tester.tap(find.text('Black (K)'));
        expect(selectedColor, Bleeding.black.code);
      });
    });

    group('Null-Safety', () {
      testWidgets('does not throw when tapped with null callbacks', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BleedingStepCard(
                isFlowStep: true,
                showNoBleeding: true,
                onSelectNoBleeding: null,
                onSelectFlow: null,
              ),
            ),
          ),
        );

        await tester.tap(find.text('No Bleeding'));
        await tester.tap(find.text('Heavy (H)'));
        await tester.tap(find.text('Moderate (M)'));
        await tester.tap(find.text('Light (L)'));
        await tester.tap(find.text('Very Light (VL)'));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BleedingStepCard(isFlowStep: false, onSelectColor: null),
            ),
          ),
        );

        await tester.tap(find.text('Red (R)'));
        await tester.tap(find.text('Brown (B)'));
        await tester.tap(find.text('Black (K)'));
        await tester.pumpAndSettle();
      });
    });
  });
}
