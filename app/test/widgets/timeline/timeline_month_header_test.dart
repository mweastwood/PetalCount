import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/widgets/timeline/timeline_month_header.dart';

void main() {
  group('TimelineMonthHeader Unit & Widget Tests', () {
    testWidgets('renders uppercase month/year and calendar icon', (
      WidgetTester tester,
    ) async {
      final date = DateTime(2026, 8, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TimelineMonthHeader(date: date)),
        ),
      );

      expect(find.text('AUGUST 2026'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);

      // Verify 56px track column exists
      final trackSizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(TimelineMonthHeader),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(trackSizedBox.width, equals(56));
    });

    testWidgets('formats different months and years accurately', (
      WidgetTester tester,
    ) async {
      final date = DateTime(2025, 12, 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TimelineMonthHeader(date: date)),
        ),
      );

      expect(find.text('DECEMBER 2025'), findsOneWidget);
    });
  });
}
