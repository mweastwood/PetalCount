import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/supplement_screen.dart';

void main() {
  setUp(() async {
    await Services.db.resetDefaultSupplements();
  });

  Widget createTestWidget({DateTime? initialDate, Cycle? cycle}) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: const Color(0xFFD81B60),
          secondary: const Color(0xFF8E24AA),
          brightness: Brightness.light,
        ),
      ),
      home: SupplementScreen(
        initialDate: initialDate ?? DateTime(2026, 8, 25),
        activeCycle:
            cycle ?? Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
      ),
    );
  }

  group('SupplementScreen Widget Tests', () {
    testWidgets('Renders all 3 tabs and shows daily intake checklist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Supplements & Protocols'), findsOneWidget);
      expect(find.text('Daily Intake'), findsOneWidget);
      expect(find.text('Cycle Plan'), findsOneWidget);
      expect(find.text('Formulary'), findsOneWidget);

      expect(find.text('Daily Adherence'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);

      // Verify some preset supplements are visible
      expect(find.text('Prenatal'), findsOneWidget);
      expect(find.text('CoQ10'), findsOneWidget);
      expect(find.text('Berberine'), findsWidgets);
    });

    testWidgets('Tapping checkbox logs supplement dose adherence', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(Checkbox).first;
      expect(tester.widget<Checkbox>(firstCheckbox).value, isFalse);

      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).value,
        isTrue,
      );
    });

    testWidgets('Date navigation shifts days properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(initialDate: DateTime(2026, 8, 25)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aug 25, 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Next Day'));
      await tester.pumpAndSettle();

      expect(find.text('Aug 26, 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Day'));
      await tester.pumpAndSettle();

      expect(find.text('Aug 25, 2026'), findsOneWidget);
    });

    testWidgets('Cycle Plan matrix tab displays schedule data table', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cycle Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Cycle Protocol Matrix'), findsOneWidget);
      expect(find.text('Morning Schedule'), findsOneWidget);
      expect(find.byType(DataTable), findsWidgets);
    });

    testWidgets(
      'Formulary tab displays all supplements with edit/delete buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Formulary'));
        await tester.pumpAndSettle();

        expect(find.text('Prenatal'), findsOneWidget);
        expect(find.text('CoQ10'), findsOneWidget);
        expect(find.text('Vitamin D'), findsOneWidget);

        expect(find.byTooltip('Edit Supplement'), findsWidgets);
        expect(find.byTooltip('Delete Supplement'), findsWidgets);
      },
    );

    testWidgets(
      'Opening Add Supplement dialog allows creating new supplement',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Formulary'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_add_supplement_fab')));
        await tester.pumpAndSettle();

        expect(find.text('Add Supplement'), findsWidgets);
        expect(find.text('Supplement Name *'), findsOneWidget);
        expect(find.text('Dosage / Quantity *'), findsOneWidget);
        expect(find.text('Take with food?'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Supplement Name *'),
          'Zinc Glycinate',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Dosage / Quantity *'),
          '30 mg',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final allSupps = await Services.db.streamSupplements().first;
        expect(allSupps.any((s) => s.name == 'Zinc Glycinate'), isTrue);
      },
    );

    testWidgets(
      'Add Supplement dialog validates required fields and displays error feedback',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Formulary'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_add_supplement_fab')));
        await tester.pumpAndSettle();

        // Tap Save immediately with empty fields
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Expect error text on both fields and dialog remains open
        expect(find.text('Supplement name is required'), findsOneWidget);
        expect(find.text('Dosage / quantity is required'), findsOneWidget);
        expect(find.text('Add Supplement'), findsWidgets);
      },
    );
  });

  group('SupplementScreen Golden Tests', () {
    testGoldens('SupplementScreen Daily Intake tab golden', (tester) async {
      await tester.pumpWidgetBuilder(
        createTestWidget(
          initialDate: DateTime(2026, 8, 25),
          cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
        ),
        surfaceSize: const Size(412, 915),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'supplement_screen_daily_intake');
    });

    testGoldens(
      'SupplementScreen Daily Intake tab with adherence logged golden',
      (tester) async {
        final date = DateTime(2026, 8, 25);
        await Services.db.logSupplementDose(
          date: date,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );
        await Services.db.logSupplementDose(
          date: date,
          supplementId: 'coq10',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );
        await Services.db.logSupplementDose(
          date: date,
          supplementId: 'vitamind',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        await tester.pumpWidgetBuilder(
          createTestWidget(
            initialDate: date,
            cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
          ),
          surfaceSize: const Size(412, 915),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'supplement_screen_daily_intake_adherence_logged',
        );
      },
    );

    testGoldens('SupplementScreen Cycle Plan matrix tab golden', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        createTestWidget(
          initialDate: DateTime(2026, 8, 25),
          cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
        ),
        surfaceSize: const Size(900, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cycle Plan'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'supplement_screen_cycle_plan_matrix');
    });

    testGoldens('SupplementScreen Formulary tab golden', (tester) async {
      await tester.pumpWidgetBuilder(
        createTestWidget(
          initialDate: DateTime(2026, 8, 25),
          cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
        ),
        surfaceSize: const Size(412, 915),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Formulary'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'supplement_screen_formulary');
    });

    testGoldens('SupplementScreen Add Supplement Dialog golden', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        createTestWidget(
          initialDate: DateTime(2026, 8, 25),
          cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
        ),
        surfaceSize: const Size(412, 915),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Formulary'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_add_supplement_fab')));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'supplement_screen_add_dialog');
    });

    testGoldens('SupplementScreen Reset Presets Dialog golden', (tester) async {
      await tester.pumpWidgetBuilder(
        createTestWidget(
          initialDate: DateTime(2026, 8, 25),
          cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
        ),
        surfaceSize: const Size(412, 915),
      );
      await tester.pumpAndSettle();

      // Open overflow popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Reset Default Presets to open confirmation dialog
      await tester.tap(find.text('Reset Default Presets'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'supplement_screen_reset_presets_dialog',
      );
    });
  });
}
