import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/supplements/add_edit_supplement_dialog.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    await Services.db.resetDefaultSupplements();
  });

  group('AddEditSupplementDialog Tests', () {
    testWidgets('populates fields when editing existing supplement', (
      tester,
    ) async {
      final existing = SupplementItem(
        id: 'test_supp',
        name: 'Magnesium Glycinate',
        quantity: '400 mg',
        takeWithFood: true,
        morningDose: 0,
        afternoonDose: 0,
        eveningDose: 2,
        ruleType: SupplementScheduleRuleType.allDays,
        instructions: 'Take before bed',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    AddEditSupplementDialog.show(context, existing),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Supplement'), findsOneWidget);
      expect(find.text('Magnesium Glycinate'), findsOneWidget);
      expect(find.text('400 mg'), findsOneWidget);
      expect(find.text('Take before bed'), findsOneWidget);
    });

    testWidgets('validates required fields on create', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AddEditSupplementDialog.show(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Supplement'), findsWidgets);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Supplement name is required'), findsOneWidget);
      expect(find.text('Dosage / quantity is required'), findsOneWidget);
    });

    testWidgets('saves new supplement via custom onSave callback', (
      tester,
    ) async {
      SupplementItem? savedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    AddEditSupplementDialog.show(context, null, (item) async {
                      savedItem = item;
                    }),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Supplement Name *'),
        'Omega-3 Fish Oil',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
        '1000 mg',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedItem, isNotNull);
      expect(savedItem!.name, equals('Omega-3 Fish Oil'));
      expect(savedItem!.quantity, equals('1000 mg'));
    });
  });
}
