import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/supplements/cycle_plan_tab.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    await Services.db.resetDefaultSupplements();
  });

  group('CyclePlanTab Tests', () {
    testWidgets('renders matrix title, info note, and data tables', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final supps = await Services.db.streamSupplements().first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CyclePlanTab(supplements: supps)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cycle Protocol Matrix'), findsOneWidget);
      expect(
        find.textContaining(
          'Schedule of prescribed supplements across cycle days',
        ),
        findsOneWidget,
      );
      expect(find.text('Morning Schedule'), findsOneWidget);
      expect(find.text('Afternoon Schedule'), findsOneWidget);
      expect(find.text('Evening Schedule'), findsOneWidget);
      expect(find.byType(DataTable), findsWidgets);
    });
  });
}
