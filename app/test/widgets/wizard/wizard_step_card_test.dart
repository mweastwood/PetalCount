import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/widgets/wizard/wizard_step_card.dart';

void main() {
  group('WizardStepCard Unit & Widget Tests', () {
    testWidgets('renders title, stepIndicator, and child body correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WizardStepCard(
              title: 'Bleeding Flow',
              stepIndicator: 'Step 1 of 10',
              child: Text('Custom Step Content'),
            ),
          ),
        ),
      );

      expect(find.text('Step 1 of 10'), findsOneWidget);
      expect(find.text('Bleeding Flow'), findsOneWidget);
      expect(find.text('Custom Step Content'), findsOneWidget);

      final titleWidget = tester.widget<Text>(find.text('Bleeding Flow'));
      expect(titleWidget.textAlign, TextAlign.center);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);

      final indicatorWidget = tester.widget<Text>(find.text('Step 1 of 10'));
      expect(indicatorWidget.textAlign, TextAlign.center);
      expect(indicatorWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('omits stepIndicator when stepIndicator is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WizardStepCard(
              title: 'Summary Step',
              stepIndicator: null,
              child: Text('Summary Body'),
            ),
          ),
        ),
      );

      expect(find.text('Summary Step'), findsOneWidget);
      expect(find.text('Summary Body'), findsOneWidget);
      expect(find.text('Step 1 of 10'), findsNothing);
    });

    testWidgets(
      'renders back button when onBack is provided and handles taps',
      (WidgetTester tester) async {
        var backPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WizardStepCard(
                title: 'Step with Back',
                onBack: () {
                  backPressed = true;
                },
                child: const Text('Body'),
              ),
            ),
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        expect(backPressed, isTrue);
      },
    );

    testWidgets('omits back button when onBack is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WizardStepCard(
              title: 'First Step',
              onBack: null,
              child: Text('Body'),
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Back'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets(
      'renders next button with default label and handles tap when enabled',
      (WidgetTester tester) async {
        var nextPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WizardStepCard(
                title: 'Step with Next',
                isNextEnabled: true,
                onNext: () {
                  nextPressed = true;
                },
                child: const Text('Body'),
              ),
            ),
          ),
        );

        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(nextPressed, isTrue);
      },
    );

    testWidgets('renders custom nextButtonText (e.g. Save, Finish)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WizardStepCard(
              title: 'Final Step',
              nextButtonText: 'Finish',
              onNext: () {},
              child: const Text('Body'),
            ),
          ),
        ),
      );

      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets(
      'disables next button when isNextEnabled is false and does not trigger callback',
      (WidgetTester tester) async {
        var nextPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WizardStepCard(
                title: 'Step Disabled Next',
                isNextEnabled: false,
                onNext: () {
                  nextPressed = true;
                },
                child: const Text('Body'),
              ),
            ),
          ),
        );

        final nextButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(nextButton.onPressed, isNull);

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(nextPressed, isFalse);
      },
    );

    testWidgets('omits next button when onNext is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WizardStepCard(
              title: 'Step without Next',
              onNext: null,
              child: Text('Body'),
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Next'), findsNothing);
    });
  });
}
