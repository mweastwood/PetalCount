import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/supplements/formulary_tab.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    await Services.db.resetDefaultSupplements();
  });

  group('FormularyTab Tests', () {
    testWidgets('renders all supplement items with edit and delete callbacks', (
      tester,
    ) async {
      final supps = await Services.db.streamSupplements().first;
      SupplementItem? editedItem;
      SupplementItem? deletedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormularyTab(
              supplements: supps,
              onEdit: (item) => editedItem = item,
              onDelete: (item) => deletedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prenatal'), findsOneWidget);
      expect(find.text('CoQ10'), findsOneWidget);
      expect(find.text('Vitamin D'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit Supplement').first);
      expect(editedItem, isNotNull);

      await tester.tap(find.byTooltip('Delete Supplement').first);
      expect(deletedItem, isNotNull);
    });
  });
}
