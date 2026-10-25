import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/supplement_screen.dart';
import 'package:petal_count/screens/supplements/supplements.dart';

void main() {
  setUp(() async {
    Services.db = InMemoryDatabaseService();
    await Services.db.resetDefaultSupplements();
  });

  const defaultCycleSentinel = Object();

  Widget createTestWidget({
    DateTime? initialDate,
    Object? cycle = defaultCycleSentinel,
  }) {
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
        activeCycle: identical(cycle, defaultCycleSentinel)
            ? Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20))
            : cycle as Cycle?,
      ),
    );
  }

  group('SupplementScreen Widget Tests', () {
    testWidgets(
      'Renders unified screen with Today supplements, Next 6 Days forecast, and Pencil FAB',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Supplements & Protocols'), findsNothing);
        expect(find.text("Today's Supplements"), findsOneWidget);
        expect(find.text('Next 6 Days'), findsOneWidget);
        expect(
          find.byKey(const Key('btn_edit_supplement_plan_fab')),
          findsOneWidget,
        );

        // Verify preset supplements are visible at the top
        expect(find.text('Prenatal'), findsOneWidget);
        expect(find.text('CoQ10'), findsOneWidget);
        expect(find.text('Berberine'), findsWidgets);

        // Verify all 6 upcoming day cards are rendered as we scroll through the 7-day forecast
        for (int i = 1; i <= 6; i++) {
          final cardFinder = find.byKey(Key('upcoming_day_card_$i'));
          await tester.scrollUntilVisible(cardFinder, 200);
          expect(cardFinder, findsOneWidget);
        }

        // Verify Conditional on Peak section appears on upcoming days when Peak is not yet recorded
        expect(find.text('Conditional on Peak'), findsWidgets);
      },
    );

    testWidgets(
      'Auto-uses Peak from active cycle when detected and removes Conditional on Peak sections',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final peakDate = DateTime(2026, 8, 24);
        final cycleWithPeak = Cycle(
          id: 'cycle_peak',
          startDate: DateTime(2026, 8, 12),
          dailyEntries: {
            peakDate.dateKey: DailyEntry.raw(date: peakDate, peakDayLabel: 'P'),
          },
        );

        await tester.pumpWidget(
          createTestWidget(
            initialDate: DateTime(2026, 8, 25),
            cycle: cycleWithPeak,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cycle Day 14 • Post-Peak (P+1)'), findsOneWidget);
        expect(find.text('Conditional on Peak'), findsNothing);
        await tester.scrollUntilVisible(find.text('Cycle Day 16 • P+3'), 200);
        expect(find.text('Cycle Day 16 • P+3'), findsOneWidget);
      },
    );

    testWidgets('Tapping checkbox logs supplement dose adherence for Today', (
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

    testWidgets(
      'Tapping Pencil FAB opens Edit Supplement Plan sheet with edit/delete/add actions',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
        await tester.pumpAndSettle();

        expect(find.text('Edit Supplement Plan'), findsOneWidget);
        expect(find.byType(FormularyTab), findsOneWidget);
        expect(find.byTooltip('Edit Supplement'), findsWidgets);
        expect(find.byTooltip('Delete Supplement'), findsWidgets);
      },
    );

    testWidgets(
      'Opening Add Supplement dialog from Edit Plan sheet allows creating new supplement',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
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

        await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_add_supplement_fab')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Supplement name is required'), findsOneWidget);
        expect(find.text('Dosage / quantity is required'), findsOneWidget);
        expect(find.text('Add Supplement'), findsWidgets);
      },
    );

    testWidgets(
      'Can toggle between wife and husband checklists and log doses',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Prenatal'), findsOneWidget);
        expect(find.text("Men's Multivitamin"), findsNothing);

        await tester.tap(find.text('👨 Husband'));
        await tester.pumpAndSettle();

        expect(find.text("Men's Multivitamin"), findsOneWidget);
        expect(find.text('Prenatal'), findsNothing);

        final husbandCheckbox = find.byType(Checkbox).first;
        expect(tester.widget<Checkbox>(husbandCheckbox).value, isFalse);

        await tester.tap(husbandCheckbox);
        await tester.pumpAndSettle();

        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).first).value,
          isTrue,
        );

        await tester.tap(find.text('👩 Wife'));
        await tester.pumpAndSettle();

        expect(find.text('Prenatal'), findsOneWidget);
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).first).value,
          isFalse,
        );
      },
    );

    testWidgets(
      'Can filter formulary in Edit Plan sheet by wife and husband and edit supplements',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('👩 Wife (14)'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(FormularyTab),
            matching: find.text('Prenatal'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('👨 Husband (6)'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(FormularyTab),
            matching: find.text("Men's Multivitamin"),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(FormularyTab),
            matching: find.text('Prenatal'),
          ),
          findsNothing,
        );

        await tester.tap(find.byTooltip('Edit Supplement').first);
        await tester.pumpAndSettle();

        expect(find.text('Edit Supplement'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, "Men's Multivitamin"),
          findsOneWidget,
        );

        final qtyField = find.widgetWithText(TextField, 'Dosage / Quantity *');
        await tester.enterText(qtyField, '2 gummies');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final allSupps = await Services.db.streamSupplements().first;
        final updatedMens = allSupps.firstWhere(
          (s) => s.name == "Men's Multivitamin",
        );
        expect(updatedMens.quantity, equals('2 gummies'));
      },
    );

    testWidgets(
      'Reset Default Presets confirmation flow restores presets and shows snackbar',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await Services.db.deleteSupplement('preset_prenatal');
        final suppsBefore = await Services.db.streamSupplements().first;
        expect(suppsBefore.any((s) => s.id == 'preset_prenatal'), isFalse);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Reset Default Presets'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
        await tester.pumpAndSettle();

        expect(
          find.text('Supplements reset to standard presets.'),
          findsOneWidget,
        );
        final restoredSupps = await Services.db.streamSupplements().first;
        expect(restoredSupps.any((s) => s.id == 'preset_prenatal'), isTrue);
      },
    );

    testWidgets(
      'Delete Supplement confirmation flow deletes supplement from database and UI',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(FormularyTab),
            matching: find.text('Prenatal'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Delete Supplement').first);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete Prenatal?'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();

        final suppsAfter = await Services.db.streamSupplements().first;
        expect(suppsAfter.any((s) => s.name == 'Prenatal'), isFalse);
        expect(find.text('Prenatal'), findsNothing);
      },
    );

    testWidgets(
      'Cancel Delete Supplement dismisses dialog without deleting supplement',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(FormularyTab),
            matching: find.text('Prenatal'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Delete Supplement').first);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete Prenatal?'), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        final suppsAfter = await Services.db.streamSupplements().first;
        expect(suppsAfter.any((s) => s.name == 'Prenatal'), isTrue);
        expect(
          find.descendant(
            of: find.byType(FormularyTab),
            matching: find.text('Prenatal'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Empty cycle state renders properly and handles date navigation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cycles = await Services.db.streamCycles().first;
        for (final c in cycles) {
          await Services.db.deleteCycle(c.id);
        }

        await tester.pumpWidget(
          createTestWidget(initialDate: DateTime(2026, 8, 25), cycle: null),
        );
        await tester.pumpAndSettle();

        expect(find.text('Supplements & Protocols'), findsNothing);
        expect(find.text('Cycle Day 1'), findsWidgets);
        expect(find.text('Cycle Day 4'), findsNothing);
        expect(find.textContaining('Clomid'), findsNothing);

        expect(find.text('Aug 25, 2026'), findsOneWidget);
        await tester.tap(find.byTooltip('Next Day'));
        await tester.pumpAndSettle();
        expect(find.text('Aug 26, 2026'), findsOneWidget);
        expect(find.text('Cycle Day 1'), findsWidgets);

        await tester.tap(find.byTooltip('Previous Day'));
        await tester.pumpAndSettle();
        expect(find.text('Aug 25, 2026'), findsOneWidget);
        expect(find.text('Cycle Day 1'), findsWidgets);
      },
    );

    testWidgets(
      'Stream instances are cached in State across UI interactions and rebuilds',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final cycleStreamBefore = tester
            .widget<StreamBuilder<List<Cycle>>>(
              find.byWidgetPredicate((w) => w is StreamBuilder<List<Cycle>>),
            )
            .stream;
        final suppStreamBefore = tester
            .widget<StreamBuilder<List<SupplementItem>>>(
              find.byWidgetPredicate(
                (w) => w is StreamBuilder<List<SupplementItem>>,
              ),
            )
            .stream;
        final logStreamBefore = tester
            .widget<StreamBuilder<Map<String, DailySupplementLog>>>(
              find.byWidgetPredicate(
                (w) => w is StreamBuilder<Map<String, DailySupplementLog>>,
              ),
            )
            .stream;

        await tester.tap(find.byTooltip('Next Day'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('👨 Husband'));
        await tester.pumpAndSettle();

        final cycleStreamAfter = tester
            .widget<StreamBuilder<List<Cycle>>>(
              find.byWidgetPredicate((w) => w is StreamBuilder<List<Cycle>>),
            )
            .stream;
        final suppStreamAfter = tester
            .widget<StreamBuilder<List<SupplementItem>>>(
              find.byWidgetPredicate(
                (w) => w is StreamBuilder<List<SupplementItem>>,
              ),
            )
            .stream;
        final logStreamAfter = tester
            .widget<StreamBuilder<Map<String, DailySupplementLog>>>(
              find.byWidgetPredicate(
                (w) => w is StreamBuilder<Map<String, DailySupplementLog>>,
              ),
            )
            .stream;

        expect(identical(cycleStreamAfter, cycleStreamBefore), isTrue);
        expect(identical(suppStreamAfter, suppStreamBefore), isTrue);
        expect(identical(logStreamAfter, logStreamBefore), isTrue);
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
          supplementId: 'preset_prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );
        await Services.db.logSupplementDose(
          date: date,
          supplementId: 'preset_coq10',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );
        await Services.db.logSupplementDose(
          date: date,
          supplementId: 'preset_vitamind',
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

        expect(find.text('3 / 16 taken'), findsOneWidget);

        await screenMatchesGolden(
          tester,
          'supplement_screen_daily_intake_adherence_logged',
        );
      },
    );

    testGoldens(
      'SupplementScreen Next 6 Days forecast (pre-Peak with Conditional on Peak) golden',
      (tester) async {
        await tester.pumpWidgetBuilder(
          createTestWidget(
            initialDate: DateTime(2026, 8, 25),
            cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
          ),
          surfaceSize: const Size(412, 915),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('upcoming_day_card_1')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Next 6 Days')),
          alignment: 0.02,
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'supplement_screen_forecast_pre_peak',
        );
      },
    );

    testGoldens(
      'SupplementScreen Next 6 Days forecast (post-Peak locked in) golden',
      (tester) async {
        final peakDate = DateTime(2026, 8, 24);
        final cycleWithPeak = Cycle(
          id: 'cycle_peak',
          startDate: DateTime(2026, 8, 12),
          dailyEntries: {
            peakDate.dateKey: DailyEntry.raw(date: peakDate, peakDayLabel: 'P'),
          },
        );

        await tester.pumpWidgetBuilder(
          createTestWidget(
            initialDate: DateTime(2026, 8, 25),
            cycle: cycleWithPeak,
          ),
          surfaceSize: const Size(412, 915),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('upcoming_day_card_1')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Next 6 Days')),
          alignment: 0.02,
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'supplement_screen_forecast_post_peak',
        );
      },
    );

    testGoldens('SupplementScreen Formulary tab golden', (tester) async {
      await tester.pumpWidgetBuilder(
        createTestWidget(
          initialDate: DateTime(2026, 8, 25),
          cycle: Cycle(id: 'cycle_test', startDate: DateTime(2026, 8, 20)),
        ),
        surfaceSize: const Size(412, 915),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
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

      await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
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

      await tester.tap(find.byKey(const Key('btn_edit_supplement_plan_fab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Reset Default Presets'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'supplement_screen_reset_presets_dialog',
      );
    });
  });
}
