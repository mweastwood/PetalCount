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

  Finder findDoseRow(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Row && w.mainAxisAlignment == MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Finder findDoseDecrementButton(String label) {
    return find.descendant(
      of: findDoseRow(label),
      matching: find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Icon &&
            (w.icon as Icon).icon == Icons.remove,
      ),
    );
  }

  Finder findDoseIncrementButton(String label) {
    return find.descendant(
      of: findDoseRow(label),
      matching: find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Icon &&
            (w.icon as Icon).icon == Icons.add,
      ),
    );
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    SupplementItem? supplement,
    Future<void> Function(SupplementItem item)? onSave,
    UserRole? defaultRole,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddEditSupplementDialog.show(
                context,
                supplement,
                onSave,
                defaultRole,
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
  }

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

      await pumpDialog(tester, supplement: existing);

      expect(find.text('Edit Supplement'), findsOneWidget);
      expect(find.text('Magnesium Glycinate'), findsOneWidget);
      expect(find.text('400 mg'), findsOneWidget);
      expect(find.text('Take before bed'), findsOneWidget);
    });

    testWidgets('validates required fields on create', (tester) async {
      await pumpDialog(tester);

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

      await pumpDialog(
        tester,
        onSave: (item) async {
          savedItem = item;
        },
      );

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

    testWidgets(
      'initializes with defaultRole and allows toggling partner role',
      (tester) async {
        SupplementItem? savedItem;

        await pumpDialog(
          tester,
          onSave: (item) async {
            savedItem = item;
          },
          defaultRole: UserRole.husband,
        );

        // Verify UserRole.husband is initially selected
        final segmentedButton = tester.widget<SegmentedButton<UserRole>>(
          find.byKey(const Key('supplement_role_segmented_button')),
        );
        expect(segmentedButton.selected, equals({UserRole.husband}));

        // Switch to UserRole.wife
        await tester.tap(find.text('👩 Wife'));
        await tester.pumpAndSettle();

        final updatedSegmentedButton = tester.widget<SegmentedButton<UserRole>>(
          find.byKey(const Key('supplement_role_segmented_button')),
        );
        expect(updatedSegmentedButton.selected, equals({UserRole.wife}));

        await tester.enterText(
          find.widgetWithText(TextField, 'Supplement Name *'),
          'Folate',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Dosage / Quantity *'),
          '400 mcg',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedItem, isNotNull);
        expect(savedItem!.targetRole, equals(UserRole.wife));
      },
    );

    testWidgets(
      'handles dose counter increments, decrements, and zero-lower-bound',
      (tester) async {
        SupplementItem? savedItem;

        await pumpDialog(
          tester,
          onSave: (item) async {
            savedItem = item;
          },
        );

        // Verify initial dose counts: morning is 1, afternoon is 0, evening is 0
        expect(
          find.descendant(
            of: findDoseRow('🌅 Morning Dose'),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: findDoseRow('☀️ Afternoon Dose'),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: findDoseRow('🌙 Evening Dose'),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );

        // Verify decrement button disabled for afternoon and evening at 0
        final afternoonDecBtn = tester.widget<IconButton>(
          findDoseDecrementButton('☀️ Afternoon Dose'),
        );
        expect(afternoonDecBtn.onPressed, isNull);

        // Decrement morning dose from 1 to 0
        await tester.tap(findDoseDecrementButton('🌅 Morning Dose'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: findDoseRow('🌅 Morning Dose'),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );

        // Morning decrement button is now disabled
        final morningDecBtn = tester.widget<IconButton>(
          findDoseDecrementButton('🌅 Morning Dose'),
        );
        expect(morningDecBtn.onPressed, isNull);

        // Tapping disabled decrement does not decrease below 0
        await tester.tap(
          findDoseDecrementButton('🌅 Morning Dose'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: findDoseRow('🌅 Morning Dose'),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );

        // Increment morning dose to 2
        final morningAddBtn = findDoseIncrementButton('🌅 Morning Dose');
        await tester.tap(morningAddBtn);
        await tester.pumpAndSettle();
        await tester.tap(morningAddBtn);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: findDoseRow('🌅 Morning Dose'),
            matching: find.text('2'),
          ),
          findsOneWidget,
        );

        // Increment afternoon dose to 1
        final afternoonAddBtn = findDoseIncrementButton('☀️ Afternoon Dose');
        await tester.tap(afternoonAddBtn);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: findDoseRow('☀️ Afternoon Dose'),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );

        // Increment evening dose to 3
        final eveningAddBtn = findDoseIncrementButton('🌙 Evening Dose');
        await tester.tap(eveningAddBtn);
        await tester.pumpAndSettle();
        await tester.tap(eveningAddBtn);
        await tester.pumpAndSettle();
        await tester.tap(eveningAddBtn);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: findDoseRow('🌙 Evening Dose'),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Supplement Name *'),
          'CoQ10',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Dosage / Quantity *'),
          '200 mg',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedItem, isNotNull);
        expect(savedItem!.morningDose, equals(2));
        expect(savedItem!.afternoonDose, equals(1));
        expect(savedItem!.eveningDose, equals(3));
      },
    );

    testWidgets('configures cycleDays schedule rule and parses cycle days', (
      tester,
    ) async {
      SupplementItem? savedItem;

      await pumpDialog(
        tester,
        onSave: (item) async {
          savedItem = item;
        },
      );

      // Select cycleDays rule from dropdown
      final dropdownFinder = find.byType(
        DropdownButtonFormField<SupplementScheduleRuleType>,
      );
      await tester.ensureVisible(dropdownFinder);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(SupplementScheduleRuleType.cycleDays.label).last,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Start Cycle Day'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Start Cycle Day'),
        '4',
      );

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'End Cycle Day'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'End Cycle Day'),
        '8',
      );

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Supplement Name *'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Supplement Name *'),
        'Letrozole',
      );

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
        '2.5 mg',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedItem, isNotNull);
      expect(savedItem!.ruleType, equals(SupplementScheduleRuleType.cycleDays));
      expect(savedItem!.startCycleDay, equals(4));
      expect(savedItem!.endCycleDay, equals(8));
    });

    testWidgets(
      'configures peakOffset schedule rule and parses peak offset inputs',
      (tester) async {
        SupplementItem? savedItem;

        await pumpDialog(
          tester,
          onSave: (item) async {
            savedItem = item;
          },
        );

        // Select peakOffset rule from dropdown
        final dropdownFinder = find.byType(
          DropdownButtonFormField<SupplementScheduleRuleType>,
        );
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(SupplementScheduleRuleType.peakOffset.label).last,
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.widgetWithText(TextField, 'Peak Offset (e.g. 3 for P+3)'),
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Peak Offset (e.g. 3 for P+3)'),
          '3',
        );

        await tester.ensureVisible(
          find.widgetWithText(TextField, 'Duration (Days)'),
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Duration (Days)'),
          '10',
        );

        await tester.ensureVisible(
          find.widgetWithText(
            TextField,
            'Fallback Start Cycle Day (if no peak)',
          ),
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Fallback Start Cycle Day (if no peak)',
          ),
          '21',
        );

        await tester.ensureVisible(
          find.widgetWithText(TextField, 'Supplement Name *'),
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Supplement Name *'),
          'Progesterone',
        );

        await tester.ensureVisible(
          find.widgetWithText(TextField, 'Dosage / Quantity *'),
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Dosage / Quantity *'),
          '200 mg',
        );

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedItem, isNotNull);
        expect(
          savedItem!.ruleType,
          equals(SupplementScheduleRuleType.peakOffset),
        );
        expect(savedItem!.startPeakOffset, equals(3));
        expect(savedItem!.durationDays, equals(10));
        expect(savedItem!.startCycleDay, equals(21));
      },
    );

    testWidgets('toggles meal requirement (takeWithFood) switch', (
      tester,
    ) async {
      SupplementItem? savedItem;

      await pumpDialog(
        tester,
        onSave: (item) async {
          savedItem = item;
        },
      );

      final switchFinder = find.widgetWithText(
        SwitchListTile,
        'Take with food?',
      );
      expect(switchFinder, findsOneWidget);
      final initialSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(initialSwitch.value, isFalse);

      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(updatedSwitch.value, isTrue);

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Supplement Name *'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Supplement Name *'),
        'Vitamin D3',
      );

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
        '2000 IU',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedItem, isNotNull);
      expect(savedItem!.takeWithFood, isTrue);
    });

    testWidgets(
      'falls back to persisting via Services.db when onSave is null',
      (tester) async {
        await pumpDialog(tester);

        await tester.enterText(
          find.widgetWithText(TextField, 'Supplement Name *'),
          'Zinc',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Dosage / Quantity *'),
          '50 mg',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final supplements = await Services.db.streamSupplements().first;
        final savedItem = supplements.firstWhere(
          (item) => item.name == 'Zinc' && item.quantity == '50 mg',
        );
        expect(savedItem, isNotNull);
        expect(savedItem.targetRole, equals(UserRole.wife));
      },
    );

    testWidgets('dynamically clears validation errors when user types input', (
      tester,
    ) async {
      await pumpDialog(tester);

      // Trigger validation errors with empty fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Supplement name is required'), findsOneWidget);
      expect(find.text('Dosage / quantity is required'), findsOneWidget);

      // Type in Supplement Name
      await tester.enterText(
        find.widgetWithText(TextField, 'Supplement Name *'),
        'Iron',
      );
      await tester.pumpAndSettle();

      // Name error should be cleared immediately, dosage error remains
      expect(find.text('Supplement name is required'), findsNothing);
      expect(find.text('Dosage / quantity is required'), findsOneWidget);

      // Type in Dosage / Quantity
      await tester.enterText(
        find.widgetWithText(TextField, 'Dosage / Quantity *'),
        '65 mg',
      );
      await tester.pumpAndSettle();

      // Dosage error should now be cleared as well
      expect(find.text('Dosage / quantity is required'), findsNothing);
    });
  });
}
