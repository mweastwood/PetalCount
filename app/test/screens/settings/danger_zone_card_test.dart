import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/danger_zone_card.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    Services.notifications = InMemoryNotificationService();
  });

  group('DangerZoneCard Tests', () {
    testWidgets(
      'renders Delete Chart button and conditionally renders Leave Chart button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DangerZoneCard(
                  chartId: 'chart_1',
                  hasOtherCollaborators: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Danger Zone'), findsOneWidget);
        expect(find.text('Delete Chart'), findsOneWidget);
        expect(find.text('Leave Chart'), findsNothing);

        // Render with collaborators
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DangerZoneCard(
                  chartId: 'chart_1',
                  hasOtherCollaborators: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Delete Chart'), findsOneWidget);
        expect(find.text('Leave Chart'), findsOneWidget);
      },
    );

    testWidgets('delete chart modal opens and confirms deletion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DangerZoneCard(
                chartId: 'chart_1',
                hasOtherCollaborators: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Chart?'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Chart?'), findsNothing);
    });

    testWidgets('leave chart modal opens and confirms leaving', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DangerZoneCard(
                chartId: 'chart_1',
                hasOtherCollaborators: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leave Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Leave Chart?'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Leave Chart'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Leave Chart?'), findsNothing);
    });
  });
}
