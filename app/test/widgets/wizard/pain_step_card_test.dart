import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';
import 'package:petal_count/widgets/wizard/pain_step_card.dart';

void main() {
  group('PainStepCard Unit & Widget Tests', () {
    group('Presence Mode (isDetailsStep == false)', () {
      testWidgets('renders title, subtitle, and option cards', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: PainStepCard(isDetailsStep: false)),
          ),
        );

        expect(find.text('Pain or Symptoms'), findsOneWidget);
        expect(
          find.text(
            'Are you experiencing any physical pain or cramps right now?',
          ),
          findsOneWidget,
        );

        expect(find.text('No Pain'), findsOneWidget);
        expect(find.text('No discomfort experienced'), findsOneWidget);
        expect(find.byIcon(Icons.sentiment_satisfied_alt), findsOneWidget);

        expect(find.text('Yes (Log Pain)'), findsOneWidget);
        expect(find.text('Cramps, abdominal pain, etc.'), findsOneWidget);
        expect(find.byIcon(Icons.healing), findsOneWidget);

        expect(find.byType(OptionCard), findsNWidgets(2));
      });

      testWidgets('reflects selection state for hasPain', (
        WidgetTester tester,
      ) async {
        // hasPain == false
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PainStepCard(isDetailsStep: false, hasPain: false),
            ),
          ),
        );

        var noCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'No Pain'),
        );
        var yesCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes (Log Pain)'),
        );
        expect(noCard.isSelected, isTrue);
        expect(yesCard.isSelected, isFalse);

        // hasPain == true
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PainStepCard(isDetailsStep: false, hasPain: true),
            ),
          ),
        );

        noCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'No Pain'),
        );
        yesCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes (Log Pain)'),
        );
        expect(noCard.isSelected, isFalse);
        expect(yesCard.isSelected, isTrue);

        // hasPain == null
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PainStepCard(isDetailsStep: false, hasPain: null),
            ),
          ),
        );

        noCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'No Pain'),
        );
        yesCard = tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes (Log Pain)'),
        );
        expect(noCard.isSelected, isFalse);
        expect(yesCard.isSelected, isFalse);
      });

      testWidgets('fires onSelectHasPain callback with boolean parameter', (
        WidgetTester tester,
      ) async {
        bool? selectedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PainStepCard(
                isDetailsStep: false,
                onSelectHasPain: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('No Pain'));
        expect(selectedValue, isFalse);

        await tester.tap(find.text('Yes (Log Pain)'));
        expect(selectedValue, isTrue);
      });
    });

    group('Details Mode (isDetailsStep == true)', () {
      testWidgets('renders title, subtitle, chips, and slider', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PainStepCard(
                isDetailsStep: true,
                painTypes: ['Cramps', 'Headache'],
                painLevel: 5.0,
              ),
            ),
          ),
        );

        expect(find.text('Pain Location & Severity'), findsOneWidget);
        expect(
          find.text('Select pain location and severity rating:'),
          findsOneWidget,
        );
        expect(find.text('Location / Type:'), findsOneWidget);

        // Verify chips
        expect(find.widgetWithText(FilterChip, 'Cramps'), findsOneWidget);
        expect(
          find.widgetWithText(FilterChip, 'Abdominal Pain'),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilterChip, 'Backache'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Headache'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Pelvic Pain'), findsOneWidget);

        final crampsChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Cramps'),
        );
        final headacheChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Headache'),
        );
        final backacheChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Backache'),
        );

        expect(crampsChip.selected, isTrue);
        expect(headacheChip.selected, isTrue);
        expect(backacheChip.selected, isFalse);

        // Abdominal side container is not visible without 'Abdominal Pain'
        expect(find.text('Abdominal Side (Optional):'), findsNothing);

        // Slider and rating indicator
        expect(find.byType(Slider), findsOneWidget);
        expect(find.text('5/10'), findsNWidgets(1));
      });

      testWidgets('fires onTogglePainType when chips are tapped', (
        WidgetTester tester,
      ) async {
        String? toggledType;
        bool? toggledState;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PainStepCard(
                isDetailsStep: true,
                painTypes: const ['Cramps'],
                onTogglePainType: (type, isSelected) {
                  toggledType = type;
                  toggledState = isSelected;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.widgetWithText(FilterChip, 'Cramps'));
        expect(toggledType, 'Cramps');
        expect(toggledState, isFalse);

        await tester.tap(find.widgetWithText(FilterChip, 'Backache'));
        expect(toggledType, 'Backache');
        expect(toggledState, isTrue);
      });

      testWidgets('conditionally renders and toggles Abdominal Side options', (
        WidgetTester tester,
      ) async {
        bool? toggledLeft;
        bool? toggledRight;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PainStepCard(
                isDetailsStep: true,
                painTypes: const ['Abdominal Pain'],
                abdominalLeft: true,
                abdominalRight: false,
                onToggleAbdominalLeft: (val) {
                  toggledLeft = val;
                },
                onToggleAbdominalRight: (val) {
                  toggledRight = val;
                },
              ),
            ),
          ),
        );

        expect(find.text('Abdominal Side (Optional):'), findsOneWidget);

        final leftChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Left'),
        );
        final rightChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Right'),
        );

        expect(leftChip.selected, isTrue);
        expect(rightChip.selected, isFalse);

        await tester.tap(find.widgetWithText(FilterChip, 'Left'));
        expect(toggledLeft, isFalse);

        await tester.tap(find.widgetWithText(FilterChip, 'Right'));
        expect(toggledRight, isTrue);
      });

      testWidgets('fires onPainLevelChanged when slider is dragged', (
        WidgetTester tester,
      ) async {
        double? newLevel;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PainStepCard(
                isDetailsStep: true,
                painLevel: 3.0,
                onPainLevelChanged: (val) {
                  newLevel = val;
                },
              ),
            ),
          ),
        );

        expect(find.text('3/10'), findsOneWidget);

        final sliderFinder = find.byType(Slider);
        // Drag slider to the right
        await tester.drag(sliderFinder, const Offset(100, 0));
        await tester.pumpAndSettle();

        expect(newLevel, isNotNull);
        expect(newLevel! > 3.0, isTrue);
      });
    });

    group('Null-Safety', () {
      testWidgets('does not throw when tapped with null callbacks', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PainStepCard(isDetailsStep: false, onSelectHasPain: null),
            ),
          ),
        );

        await tester.tap(find.text('No Pain'));
        await tester.tap(find.text('Yes (Log Pain)'));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PainStepCard(
                isDetailsStep: true,
                painTypes: ['Abdominal Pain'],
                onTogglePainType: null,
                onToggleAbdominalLeft: null,
                onToggleAbdominalRight: null,
                onPainLevelChanged: null,
              ),
            ),
          ),
        );

        await tester.tap(find.widgetWithText(FilterChip, 'Abdominal Pain'));
        await tester.tap(find.widgetWithText(FilterChip, 'Left'));
        await tester.tap(find.widgetWithText(FilterChip, 'Right'));
        await tester.drag(find.byType(Slider), const Offset(50, 0));
        await tester.pumpAndSettle();
      });
    });
  });
}
