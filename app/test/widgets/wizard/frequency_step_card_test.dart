import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/observation.dart';
import 'package:petal_count/widgets/wizard/frequency_step_card.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';

void main() {
  group('FrequencyStepCard Unit & Widget Tests', () {
    testWidgets('renders static texts, headers, icons, and option cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FrequencyStepCard(
              frequency: Frequency.none,
              onSelectFrequency: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Observation Frequency'), findsOneWidget);
      expect(
        find.text('How often did you observe this symptom or mucus today?'),
        findsOneWidget,
      );

      expect(find.text('All Day (AD)'), findsOneWidget);
      expect(find.text('Continuous / throughout day'), findsOneWidget);
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);

      expect(find.text('Once (x1)'), findsOneWidget);
      expect(find.text('Observed 1 time'), findsOneWidget);
      expect(find.byIcon(Icons.looks_one_outlined), findsOneWidget);

      expect(find.text('Twice (x2)'), findsOneWidget);
      expect(find.text('Observed 2 times'), findsOneWidget);
      expect(find.byIcon(Icons.looks_two_outlined), findsOneWidget);

      expect(find.text('Three Times (x3)'), findsOneWidget);
      expect(find.text('Observed 3 times'), findsOneWidget);
      expect(find.byIcon(Icons.looks_3_outlined), findsOneWidget);

      expect(find.text('None / Unspecified'), findsOneWidget);
      expect(find.text('Single observation timestamp'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

      expect(find.byType(OptionCard), findsNWidgets(5));
    });

    testWidgets('reflects selection state for each Frequency enum', (
      WidgetTester tester,
    ) async {
      final frequencies = [
        (Frequency.allDay, 'All Day (AD)'),
        (Frequency.once, 'Once (x1)'),
        (Frequency.twice, 'Twice (x2)'),
        (Frequency.thrice, 'Three Times (x3)'),
        (Frequency.none, 'None / Unspecified'),
      ];

      for (final (freq, label) in frequencies) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FrequencyStepCard(
                frequency: freq,
                onSelectFrequency: (_) {},
              ),
            ),
          ),
        );

        for (final (_, otherLabel) in frequencies) {
          final finder = find.widgetWithText(OptionCard, otherLabel);
          await tester.ensureVisible(finder);
          final card = tester.widget<OptionCard>(finder);
          expect(
            card.isSelected,
            otherLabel == label,
            reason: 'Card $otherLabel selection check for frequency $freq',
          );
        }
      }
    });

    testWidgets('fires onSelectFrequency callback with selected frequency', (
      WidgetTester tester,
    ) async {
      Frequency? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FrequencyStepCard(
              frequency: Frequency.none,
              onSelectFrequency: (freq) {
                selected = freq;
              },
            ),
          ),
        ),
      );

      final allDayFinder = find.text('All Day (AD)');
      await tester.ensureVisible(allDayFinder);
      await tester.tap(allDayFinder);
      expect(selected, Frequency.allDay);

      final onceFinder = find.text('Once (x1)');
      await tester.ensureVisible(onceFinder);
      await tester.tap(onceFinder);
      expect(selected, Frequency.once);

      final twiceFinder = find.text('Twice (x2)');
      await tester.ensureVisible(twiceFinder);
      await tester.tap(twiceFinder);
      expect(selected, Frequency.twice);

      final thriceFinder = find.text('Three Times (x3)');
      await tester.ensureVisible(thriceFinder);
      await tester.tap(thriceFinder);
      expect(selected, Frequency.thrice);

      final noneFinder = find.text('None / Unspecified');
      await tester.ensureVisible(noneFinder);
      await tester.tap(noneFinder);
      expect(selected, Frequency.none);
    });
  });
}
