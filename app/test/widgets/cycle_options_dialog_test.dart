import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/cycle_options_dialog.dart';

void main() {
  setUpAll(() async {
    await Services.init();
  });

  final cycle1 = Cycle(
    id: 'cycle-1',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 31),
  );

  final cycle2 = Cycle(id: 'cycle-2', startDate: DateTime(2026, 2, 1));

  final cycles = [cycle1, cycle2];

  Widget buildTestWidget({
    required Cycle cycle,
    required List<Cycle> cycles,
    DateTime? targetDate,
    bool openAsBottomSheet = false,
  }) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      home: Scaffold(
        body: openAsBottomSheet
            ? Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => CycleOptionsDialog.show(
                      context,
                      cycle: cycle,
                      cycles: cycles,
                      targetDate: targetDate,
                    ),
                    child: const Text('Open Options Dialog'),
                  ),
                ),
              )
            : Center(
                child: SingleChildScrollView(
                  child: CycleOptionsDialog(
                    cycle: cycle,
                    cycles: cycles,
                    targetDate: targetDate,
                  ),
                ),
              ),
      ),
    );
  }

  group('CycleOptionsDialog Render Tests', () {
    testWidgets(
      'renders Adjust Cycle Start Date, Start New Cycle on [Date], and Delete Cycle Boundary when appropriate',
      (WidgetTester tester) async {
        final targetDate = DateTime(2026, 2, 15);

        await tester.pumpWidget(
          buildTestWidget(
            cycle: cycle2,
            cycles: cycles,
            targetDate: targetDate,
          ),
        );
        await tester.pumpAndSettle();

        // Verify Dialog Title & Header Info
        expect(find.text('Cycle Boundary Options'), findsOneWidget);
        expect(
          find.text('Current cycle start: February 01, 2026'),
          findsOneWidget,
        );

        // Verify "Start New Cycle on Feb 15, 2026" option
        expect(find.text('Start New Cycle on Feb 15, 2026'), findsOneWidget);
        expect(
          find.text(
            'Splits cycle and starts a new cycle boundary on this date',
          ),
          findsOneWidget,
        );

        // Verify "Adjust Cycle Start Date" option
        expect(find.text('Adjust Cycle Start Date'), findsOneWidget);
        expect(
          find.text('Change the start date for this cycle'),
          findsOneWidget,
        );

        // Verify "Delete Cycle Boundary" option
        expect(find.text('Delete Cycle Boundary'), findsOneWidget);
        expect(
          find.text(
            'Merges observations from this cycle into the previous cycle',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides Start New Cycle on [Date] option when targetDate is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(cycle: cycle2, cycles: cycles, targetDate: null),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cycle Boundary Options'), findsOneWidget);
        expect(find.textContaining('Start New Cycle on'), findsNothing);
        expect(find.text('Adjust Cycle Start Date'), findsOneWidget);
        expect(find.text('Delete Cycle Boundary'), findsOneWidget);
      },
    );

    testWidgets(
      'hides Delete Cycle Boundary option when cycle is the first cycle',
      (WidgetTester tester) async {
        final targetDate = DateTime(2026, 1, 15);

        await tester.pumpWidget(
          buildTestWidget(
            cycle: cycle1,
            cycles: cycles,
            targetDate: targetDate,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cycle Boundary Options'), findsOneWidget);
        expect(find.text('Start New Cycle on Jan 15, 2026'), findsOneWidget);
        expect(find.text('Adjust Cycle Start Date'), findsOneWidget);
        expect(find.text('Delete Cycle Boundary'), findsNothing);
      },
    );
  });

  group('CycleOptionsDialog Golden Tests', () {
    testGoldens('CycleOptionsDialog UI with all options displayed', (
      tester,
    ) async {
      final targetDate = DateTime(2026, 2, 15);

      await tester.pumpWidgetBuilder(
        buildTestWidget(cycle: cycle2, cycles: cycles, targetDate: targetDate),
        surfaceSize: const Size(400, 600),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'cycle_options_dialog_all_options');
    });

    testGoldens('CycleOptionsDialog UI for first cycle without target date', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        buildTestWidget(cycle: cycle1, cycles: cycles, targetDate: null),
        surfaceSize: const Size(400, 500),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'cycle_options_dialog_first_cycle');
    });
  });

  group('CycleOptionsDialog Interactive Tests', () {
    testWidgets(
      'tapping Start New Cycle on [Date] calls startNewCycle and shows SnackBar',
      (WidgetTester tester) async {
        final targetDate = DateTime(2026, 2, 15);

        await tester.pumpWidget(
          buildTestWidget(
            cycle: cycle2,
            cycles: cycles,
            targetDate: targetDate,
            openAsBottomSheet: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open bottom sheet dialog
        await tester.tap(find.text('Open Options Dialog'));
        await tester.pumpAndSettle();

        // Verify bottom sheet is displayed
        expect(find.text('Cycle Boundary Options'), findsOneWidget);

        // Tap "Start New Cycle on Feb 15, 2026"
        await tester.tap(find.text('Start New Cycle on Feb 15, 2026'));
        await tester.pumpAndSettle();

        // Verify bottom sheet is closed and SnackBar is shown
        expect(find.text('Cycle Boundary Options'), findsNothing);
        expect(find.text('New cycle started on Feb 15, 2026'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Adjust Cycle Start Date opens DatePicker and updates date on confirmation',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            cycle: cycle2,
            cycles: cycles,
            targetDate: null,
            openAsBottomSheet: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open bottom sheet dialog
        await tester.tap(find.text('Open Options Dialog'));
        await tester.pumpAndSettle();

        // Tap "Adjust Cycle Start Date"
        await tester.tap(find.text('Adjust Cycle Start Date'));
        await tester.pumpAndSettle();

        // Verify DatePicker dialog is shown
        expect(find.byType(DatePickerDialog), findsOneWidget);

        // Tap "OK" button in DatePicker
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Verify bottom sheet & DatePicker closed, SnackBar shown
        expect(find.text('Cycle Boundary Options'), findsNothing);
        expect(
          find.textContaining('Cycle start date updated to'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Delete Cycle Boundary shows confirmation dialog and cancels when Cancel is pressed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            cycle: cycle2,
            cycles: cycles,
            targetDate: null,
            openAsBottomSheet: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open bottom sheet dialog
        await tester.tap(find.text('Open Options Dialog'));
        await tester.pumpAndSettle();

        // Tap "Delete Cycle Boundary"
        await tester.tap(find.text('Delete Cycle Boundary'));
        await tester.pumpAndSettle();

        // Verify AlertDialog for boundary deletion is displayed
        expect(find.text('Delete Cycle Boundary?'), findsOneWidget);
        expect(
          find.text(
            'This will merge the cycle starting on February 01, 2026 into the previous cycle. All observations will be preserved.',
          ),
          findsOneWidget,
        );

        // Tap "Cancel" button in AlertDialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify AlertDialog is dismissed and merge SnackBar is NOT shown
        expect(find.text('Delete Cycle Boundary?'), findsNothing);
        expect(find.text('Cycle merged into previous cycle'), findsNothing);
      },
    );

    testWidgets(
      'tapping Delete Cycle Boundary shows confirmation dialog and merges cycle when Delete Boundary is pressed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            cycle: cycle2,
            cycles: cycles,
            targetDate: null,
            openAsBottomSheet: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open bottom sheet dialog
        await tester.tap(find.text('Open Options Dialog'));
        await tester.pumpAndSettle();

        // Tap "Delete Cycle Boundary"
        await tester.tap(find.text('Delete Cycle Boundary'));
        await tester.pumpAndSettle();

        // Verify AlertDialog for boundary deletion is displayed
        expect(find.text('Delete Cycle Boundary?'), findsOneWidget);

        // Tap "Delete Boundary" button in AlertDialog
        await tester.tap(find.widgetWithText(FilledButton, 'Delete Boundary'));
        await tester.pumpAndSettle();

        // Verify AlertDialog dismissed and SnackBar shown
        expect(find.text('Delete Cycle Boundary?'), findsNothing);
        expect(find.text('Cycle merged into previous cycle'), findsOneWidget);
      },
    );
  });
}
