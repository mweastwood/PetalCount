import 'dart:async';
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

    testWidgets('dialog stays open and shows error SnackBar on save failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    AddEditSupplementDialog.show(context, null, (item) async {
                      throw Exception('Firestore write denied');
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
        'Vitamin D3',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
        '5000 IU',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Dialog should remain open (not popped)
      expect(find.text('Add Supplement'), findsWidgets);
      expect(find.text('Vitamin D3'), findsOneWidget);
      expect(find.text('5000 IU'), findsOneWidget);

      // Error SnackBar should be visible
      expect(
        find.text(
          'Failed to save supplement: Exception: Firestore write denied',
        ),
        findsOneWidget,
      );
    });

    testWidgets('dialog closes only after successful save', (tester) async {
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
        'Zinc',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
        '30 mg',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed after successful save
      expect(find.text('Add Supplement'), findsNothing);
      expect(savedItem, isNotNull);
      expect(savedItem!.name, equals('Zinc'));
    });

    testWidgets('save button is disabled while saving is in progress', (
      tester,
    ) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    AddEditSupplementDialog.show(context, null, (item) async {
                      await completer.future;
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
        'Folate',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
        '800 mcg',
      );

      await tester.tap(find.text('Save'));
      // Pump a single frame to process the setState for _isSaving = true
      await tester.pump();

      // Save button should show a CircularProgressIndicator instead of text
      expect(find.text('Save'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // The FilledButton should be disabled (onPressed == null)
      final filledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(filledButton.onPressed, isNull);

      // Complete save and finish transition
      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
