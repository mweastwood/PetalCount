import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/widgets.dart';

void main() {
  setUpAll(() async {
    await Services.init();
  });

  Widget buildWizardWidget() {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      home: Scaffold(
        body: Center(
          child: AddObservationDialog(
            defaultDate: DateTime(2026, 7, 27, 10, 30),
          ),
        ),
      ),
    );
  }

  group('AddObservationDialog Golden Tests for Every Wizard Screen', () {
    testGoldens('Step 1: Bleeding Flow screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Are you experiencing bleeding at this point in time?'),
        findsOneWidget,
      );
      await screenMatchesGolden(tester, 'wizard_step_1_bleeding_flow');
    });

    testGoldens('Step 2: Blood Color screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      // Tap Light (L) to trigger blood color step
      await tester.tap(find.text('Light (L)'));
      await tester.pumpAndSettle();

      expect(find.text('Blood Color'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_2_bleeding_color');
    });

    testGoldens('Step 3: Sensation at Vulva screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      // Tap No Bleeding to go to Sensation
      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      expect(find.text('Sensation at Vulva'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_3_sensation');
    });

    testGoldens('Step 4: Lubricative Sensation screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      // Tap Wet to go to Lubrication screen
      await tester.tap(find.text('Wet'));
      await tester.pumpAndSettle();

      expect(find.text('Lubricative Sensation'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_4_lubrication');
    });

    testGoldens('Step 5: Mucus Observation screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes Lubrication'));
      await tester.pumpAndSettle();

      expect(find.text('Mucus Observation'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_5_mucus');
    });

    testGoldens('Step 6: Finger Test Stretch screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes Mucus'));
      await tester.pumpAndSettle();

      expect(find.text('Finger Test Stretch'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_6_mucus_stretch');
    });

    testGoldens('Step 7: Mucus Color screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes Mucus'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stretchy (10)'));
      await tester.pumpAndSettle();

      expect(find.text('Mucus Color'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_7_mucus_color');
    });

    testGoldens('Step 8: Mucus Consistency screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes Mucus'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stretchy (10)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear (K)'));
      await tester.pumpAndSettle();

      expect(find.text('Mucus Consistency'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_8_mucus_consistency');
    });

    testGoldens('Step 9: Pain or Symptoms screen golden', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Mucus'));
      await tester.pumpAndSettle();

      expect(find.text('Pain or Symptoms'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_9_pain');
    });

    testGoldens('Step 10: Pain Location & Severity screen golden', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Mucus'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes (Log Pain)'));
      await tester.pumpAndSettle();

      // Tap Abdominal Pain to reveal Left / Right side options
      await tester.tap(find.text('Abdominal Pain'));
      await tester.pumpAndSettle();

      // Select Left side
      await tester.tap(find.text('Left'));
      await tester.pumpAndSettle();

      expect(find.text('Pain Location & Severity'), findsOneWidget);
      expect(find.text('Abdominal Side (Optional):'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_10_pain_details');
    });

    testGoldens('Step 11: Summary & Additional Notes screen golden', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Mucus'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Pain'));
      await tester.pumpAndSettle();

      expect(find.text('Summary & Additional Notes'), findsOneWidget);
      expect(find.text('Save Observation'), findsOneWidget);
      await screenMatchesGolden(tester, 'wizard_step_11_comments_summary');
    });
  });

  group('AddObservationDialog Comprehensive Unit & Widget Logic Tests', () {
    testWidgets('Heavy bleeding skips sensation, lubrication, and mucus steps', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      // Select Heavy bleeding
      await tester.tap(find.text('Heavy (H)'));
      await tester.pumpAndSettle();

      // Should skip sensation/lubrication/mucus and land directly on blood color
      expect(find.text('Blood Color'), findsOneWidget);

      await tester.tap(find.text('Red (R)'));
      await tester.pumpAndSettle();

      // Should skip sensation/mucus and land on Pain
      expect(find.text('Pain or Symptoms'), findsOneWidget);
    });

    testWidgets('Dry sensation skips lubrication question', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      // Select Dry
      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      // Should skip Lubricative Sensation and go directly to Mucus Observation
      expect(find.text('Mucus Observation'), findsOneWidget);
    });

    testWidgets('No Mucus skips stretch, color, and consistency screens', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      // Select No Mucus
      await tester.tap(find.text('No Mucus'));
      await tester.pumpAndSettle();

      // Should go directly to Pain screen
      expect(find.text('Pain or Symptoms'), findsOneWidget);
    });

    testWidgets('Back button reverses steps correctly', (tester) async {
      await tester.pumpWidgetBuilder(
        buildWizardWidget(),
        surfaceSize: const Size(600, 700),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();
      expect(find.text('Sensation at Vulva'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Back on Step 1
      expect(
        find.text('Are you experiencing bleeding at this point in time?'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Full flow wizard navigation saves observation to database cleanly',
      (tester) async {
        await tester.pumpWidgetBuilder(
          buildWizardWidget(),
          surfaceSize: const Size(600, 700),
        );
        await tester.pumpAndSettle();

        // 1. No Bleeding
        await tester.tap(find.text('No Bleeding'));
        await tester.pumpAndSettle();

        // 2. Wet sensation
        await tester.tap(find.text('Wet'));
        await tester.pumpAndSettle();

        // 3. Yes Lubrication
        await tester.tap(find.text('Yes Lubrication'));
        await tester.pumpAndSettle();

        // 4. Yes Mucus
        await tester.tap(find.text('Yes Mucus'));
        await tester.pumpAndSettle();

        // 5. Stretchy
        await tester.tap(find.text('Stretchy (10)'));
        await tester.pumpAndSettle();

        // 6. Clear
        await tester.tap(find.text('Clear (K)'));
        await tester.pumpAndSettle();

        // 7. Neither consistency
        await tester.tap(find.text('Neither'));
        await tester.pumpAndSettle();

        // 8. Yes Pain
        await tester.tap(find.text('Yes (Log Pain)'));
        await tester.pumpAndSettle();

        // 9. Select Cramps & Abdominal Pain (Right)
        await tester.tap(find.text('Cramps'));
        await tester.tap(find.text('Abdominal Pain'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Right'));
        await tester.pumpAndSettle();

        // Tap Continue in footer
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // 10. Summary page
        expect(find.text('Summary & Additional Notes'), findsOneWidget);
        expect(find.textContaining('Wet (Lubricative)'), findsOneWidget);
        expect(find.textContaining('Stretchy'), findsOneWidget);
        expect(
          find.textContaining('Cramps, Abdominal Pain (Right)'),
          findsOneWidget,
        );

        // Tap Save Observation
        await tester.tap(find.text('Save Observation'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Category Mucus wizard flow only asks mucus questions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddObservationDialog(
              defaultDate: DateTime(2026, 7, 27, 10, 30),
              category: ObservationCategory.mucus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log Mucus Observation'), findsOneWidget);
      expect(find.text('Sensation at Vulva'), findsOneWidget);

      // Select Dry -> advances to Mucus Observation
      await tester.tap(find.text('Dry'));
      await tester.pumpAndSettle();

      expect(find.text('Mucus Observation'), findsOneWidget);

      // Select No Mucus -> advances to Comments & Save
      await tester.tap(find.text('No Mucus'));
      await tester.pumpAndSettle();

      expect(find.text('Summary & Additional Notes'), findsOneWidget);
    });

    testGoldens(
      'Category Bleeding wizard flow skips No Bleeding option golden',
      (tester) async {
        await tester.pumpWidgetBuilder(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AddObservationDialog(
                  defaultDate: DateTime(2026, 7, 27, 10, 30),
                  category: ObservationCategory.bleeding,
                ),
              ),
            ),
          ),
          surfaceSize: const Size(600, 700),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Bleeding'), findsOneWidget);
        expect(find.text('Select Bleeding Flow Level'), findsOneWidget);
        expect(find.text('No Bleeding'), findsNothing);
        await screenMatchesGolden(tester, 'wizard_category_bleeding_flow');

        // Select Moderate (M) -> advances to Blood Color
        await tester.tap(find.text('Moderate (M)'));
        await tester.pumpAndSettle();

        expect(find.text('Blood Color'), findsOneWidget);

        // Select Red (R) -> advances to Comments & Save
        await tester.tap(find.text('Red (R)'));
        await tester.pumpAndSettle();

        expect(find.text('Summary & Additional Notes'), findsOneWidget);
        expect(find.textContaining('Moderate, Red'), findsOneWidget);
      },
    );

    testGoldens(
      'Category Intercourse wizard flow skips initial question and opens summary directly golden',
      (tester) async {
        await tester.pumpWidgetBuilder(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AddObservationDialog(
                  defaultDate: DateTime(2026, 7, 27, 10, 30),
                  category: ObservationCategory.intercourse,
                ),
              ),
            ),
          ),
          surfaceSize: const Size(600, 700),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Intercourse'), findsOneWidget);
        expect(find.text('Summary & Additional Notes'), findsOneWidget);
        expect(find.textContaining('Intercourse: Yes'), findsOneWidget);
        await screenMatchesGolden(
          tester,
          'wizard_category_intercourse_summary',
        );

        // Save
        await tester.tap(find.text('Save Observation'));
        await tester.pumpAndSettle();
      },
    );

    testGoldens(
      'Category Pain wizard flow skips initial question and opens pain location directly golden',
      (tester) async {
        await tester.pumpWidgetBuilder(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AddObservationDialog(
                  defaultDate: DateTime(2026, 7, 27, 10, 30),
                  category: ObservationCategory.pain,
                ),
              ),
            ),
          ),
          surfaceSize: const Size(600, 700),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Pain'), findsOneWidget);
        expect(find.text('Pain Location & Severity'), findsOneWidget);
        await screenMatchesGolden(tester, 'wizard_category_pain_details');

        // Select Cramps and tap Continue
        await tester.tap(find.text('Cramps'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Summary & Additional Notes'), findsOneWidget);
        expect(find.textContaining('Cramps'), findsOneWidget);
      },
    );
  });
}
