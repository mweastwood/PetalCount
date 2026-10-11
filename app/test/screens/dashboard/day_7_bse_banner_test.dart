import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/screens/dashboard/day_7_bse_banner.dart';

void main() {
  group('Day7BseBanner Tests', () {
    testWidgets('renders key, icon, title, description, and styling correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Day7BseBanner())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_day_7_bse')), findsOneWidget);
      expect(find.byIcon(Icons.health_and_safety), findsOneWidget);
      expect(
        find.text('Cycle Day 7: Routine Breast Self-Exam'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Day 7 is the standard Creighton Model routine day for a monthly Breast Self-Exam (BSE).',
        ),
        findsOneWidget,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('banner_day_7_bse')),
      );
      expect(container.margin, const EdgeInsets.fromLTRB(16, 12, 16, 4));
      expect(
        container.padding,
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );

      final titleText = tester.widget<Text>(
        find.text('Cycle Day 7: Routine Breast Self-Exam'),
      );
      final descriptionText = tester.widget<Text>(
        find.text(
          'Day 7 is the standard Creighton Model routine day for a monthly Breast Self-Exam (BSE).',
        ),
      );
      final theme = Theme.of(tester.element(find.byType(Day7BseBanner)));
      expect(titleText.style?.fontWeight, equals(FontWeight.bold));
      expect(
        titleText.style?.fontSize,
        equals(theme.textTheme.labelLarge?.fontSize),
      );
      expect(
        descriptionText.style?.fontSize,
        equals(theme.textTheme.labelSmall?.fontSize),
      );
    });
  });
}
