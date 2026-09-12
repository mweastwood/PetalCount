import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/danger_zone_card.dart';

class MockDangerZoneDatabaseService extends InMemoryDatabaseService {
  String? deletedChartId;
  String? leftChartId;
  Object? errorToThrow;

  @override
  Future<void> deleteChart(String chartId) async {
    deletedChartId = chartId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return super.deleteChart(chartId);
  }

  @override
  Future<void> leaveChart(String chartId) async {
    leftChartId = chartId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return super.leaveChart(chartId);
  }
}

void main() {
  late MockDangerZoneDatabaseService mockDb;

  setUp(() async {
    mockDb = MockDangerZoneDatabaseService();
    Services.db = mockDb;
    Services.notifications = InMemoryNotificationService();
  });

  Future<void> pumpDangerZoneInRoute(
    WidgetTester tester, {
    required String chartId,
    bool hasOtherCollaborators = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: SingleChildScrollView(
                          child: DangerZoneCard(
                            chartId: chartId,
                            hasOtherCollaborators: hasOtherCollaborators,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
  }

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

    testWidgets(
      'delete chart modal opens and cancels deletion without action',
      (WidgetTester tester) async {
        await pumpDangerZoneInRoute(
          tester,
          chartId: 'chart_1',
          hasOtherCollaborators: false,
        );

        await tester.tap(find.text('Delete Chart'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Chart?'), findsOneWidget);
        expect(find.text('Delete Permanently'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Chart?'), findsNothing);
        expect(mockDb.deletedChartId, isNull);
      },
    );

    testWidgets('delete chart modal opens and confirms deletion permanently', (
      WidgetTester tester,
    ) async {
      await pumpDangerZoneInRoute(
        tester,
        chartId: 'chart_1',
        hasOtherCollaborators: false,
      );

      await tester.tap(find.text('Delete Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Chart?'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(mockDb.deletedChartId, 'chart_1');
      expect(find.text('Delete Chart?'), findsNothing);
      expect(find.byType(DangerZoneCard), findsNothing);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when deleteChart throws an exception', (
      WidgetTester tester,
    ) async {
      mockDb.errorToThrow = Exception('Database failure');

      await pumpDangerZoneInRoute(
        tester,
        chartId: 'chart_1',
        hasOtherCollaborators: false,
      );

      await tester.tap(find.text('Delete Chart'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Error deleting chart: Database failure'),
        findsOneWidget,
      );

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
    });

    testWidgets('leave chart modal opens and cancels leaving without action', (
      WidgetTester tester,
    ) async {
      await pumpDangerZoneInRoute(
        tester,
        chartId: 'chart_1',
        hasOtherCollaborators: true,
      );

      await tester.tap(find.text('Leave Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Leave Chart?'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Leave Chart'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Leave Chart?'), findsNothing);
      expect(mockDb.leftChartId, isNull);
    });

    testWidgets('leave chart modal opens and confirms leaving chart', (
      WidgetTester tester,
    ) async {
      await pumpDangerZoneInRoute(
        tester,
        chartId: 'chart_1',
        hasOtherCollaborators: true,
      );

      await tester.tap(find.text('Leave Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Leave Chart?'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Leave Chart'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Leave Chart'));
      await tester.pumpAndSettle();

      expect(mockDb.leftChartId, 'chart_1');
      expect(find.text('Leave Chart?'), findsNothing);
      expect(find.byType(DangerZoneCard), findsNothing);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when leaveChart throws an exception', (
      WidgetTester tester,
    ) async {
      mockDb.errorToThrow = Exception('Network error');

      await pumpDangerZoneInRoute(
        tester,
        chartId: 'chart_1',
        hasOtherCollaborators: true,
      );

      await tester.tap(find.text('Leave Chart'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Leave Chart'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Error leaving chart: Network error'),
        findsOneWidget,
      );

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
    });
  });
}
