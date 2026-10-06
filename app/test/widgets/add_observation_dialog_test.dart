import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/add_observation_dialog.dart';
import 'package:petal_count/widgets/wizard/option_card.dart';

/// Base [InMemoryDatabaseService] that runs [beforeSave] ahead of every
/// observation save, so subclasses need not repeat the long
/// [saveObservation] signature.
abstract class HookedSaveDatabaseService extends InMemoryDatabaseService {
  Future<void> beforeSave();

  @override
  Future<void> saveObservation({
    String? cycleId,
    required DateTime date,
    required Sensation sensation,
    required Stretch stretch,
    required List<MucusColor> colors,
    required List<Consistency> consistencies,
    required Bleeding bleeding,
    required String bleedingColor,
    Frequency frequency = Frequency.none,
    bool intercourse = false,
    required double painLevel,
    required List<String> painTypes,
    required String comment,
    bool? isVdrsExplicit,
  }) async {
    await beforeSave();
    await super.saveObservation(
      cycleId: cycleId,
      date: date,
      sensation: sensation,
      stretch: stretch,
      colors: colors,
      consistencies: consistencies,
      bleeding: bleeding,
      bleedingColor: bleedingColor,
      frequency: frequency,
      intercourse: intercourse,
      painLevel: painLevel,
      painTypes: painTypes,
      comment: comment,
      isVdrsExplicit: isVdrsExplicit,
    );
  }
}

class FailingDatabaseService extends HookedSaveDatabaseService {
  final String errorMessage;
  FailingDatabaseService({this.errorMessage = 'Database disk failure'});

  @override
  Future<void> beforeSave() async => throw Exception(errorMessage);
}

class DelayedDatabaseService extends HookedSaveDatabaseService {
  final Completer<void> saveCompleter = Completer<void>();

  @override
  Future<void> beforeSave() => saveCompleter.future;
}

/// Returns the [WizardController] currently driving the dialog's UI.
WizardController findDialogController(WidgetTester tester) {
  final builder = tester.widget<ListenableBuilder>(
    find
        .descendant(
          of: find.byType(AddObservationDialog),
          matching: find.byWidgetPredicate(
            (w) => w is ListenableBuilder && w.listenable is WizardController,
          ),
        )
        .first,
  );
  return builder.listenable as WizardController;
}

void expectControllerDisposed(WizardController controller) {
  // ChangeNotifier asserts when listened to after being disposed.
  expect(() => controller.addListener(() {}), throwsFlutterError);
}

void expectControllerNotDisposed(WizardController controller) {
  void listener() {}
  expect(() => controller.addListener(listener), returnsNormally);
  controller.removeListener(listener);
}

/// A [WizardController] whose save is rejected without throwing (returns false).
class _RejectingWizardController extends WizardController {
  int saveCalls = 0;

  _RejectingWizardController({
    super.category,
    required super.defaultDate,
    super.dbService,
  });

  @override
  Future<bool> saveObservation() async {
    saveCalls++;
    return false;
  }
}

void main() {
  late InMemoryDatabaseService testDb;
  final defaultDate = DateTime(2026, 7, 27, 10, 30);

  setUp(() async {
    testDb = InMemoryDatabaseService();
    await Services.init(dbService: testDb);
  });

  Widget buildDirectDialogWidget({
    Cycle? cycle,
    DateTime? date,
    ObservationCategory category = ObservationCategory.full,
    DatabaseService? dbService,
    WizardController? controller,
  }) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      home: Scaffold(
        body: Center(
          child: AddObservationDialog(
            cycle: cycle,
            defaultDate: date ?? defaultDate,
            category: category,
            dbService: dbService ?? testDb,
            controller: controller,
          ),
        ),
      ),
    );
  }

  Future<void> pumpDialogInNavigator(
    WidgetTester tester, {
    Cycle? cycle,
    DateTime? date,
    ObservationCategory category = ObservationCategory.full,
    DatabaseService? dbService,
    WizardController? controller,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddObservationDialog(
                    cycle: cycle,
                    defaultDate: date ?? defaultDate,
                    category: category,
                    dbService: dbService ?? testDb,
                    controller: controller,
                  ),
                );
              },
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

  group('Suite 1: Initialization & Controller Ownership', () {
    testWidgets(
      'default controller creation renders full category title and step count',
      (tester) async {
        await tester.pumpWidget(buildDirectDialogWidget());
        await tester.pumpAndSettle();

        expect(find.text('Log Single Observation'), findsOneWidget);
        expect(find.textContaining('Step 1 of 5: Bleeding'), findsOneWidget);
        expect(find.byType(AddObservationDialog), findsOneWidget);
      },
    );

    testWidgets(
      'category parameter propagates to owned controller when external controller is omitted',
      (tester) async {
        await tester.pumpWidget(
          buildDirectDialogWidget(category: ObservationCategory.bleeding),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Bleeding'), findsOneWidget);
        expect(find.textContaining('Step 1 of 3: Bleeding'), findsOneWidget);
        expect(find.byType(AddObservationDialog), findsOneWidget);
      },
    );

    testWidgets(
      'pre-configured external controller renders specific category title and state',
      (tester) async {
        final bleedingController = WizardController(
          category: ObservationCategory.bleeding,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(bleedingController.dispose);

        await tester.pumpWidget(
          buildDirectDialogWidget(controller: bleedingController),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Bleeding'), findsOneWidget);
        expect(find.textContaining('Step 1 of 3: Bleeding'), findsOneWidget);

        final painController = WizardController(
          category: ObservationCategory.pain,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(painController.dispose);

        await tester.pumpWidget(
          buildDirectDialogWidget(controller: painController),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Pain'), findsOneWidget);
        expect(
          find.textContaining('Step 1 of 2: Pain Details'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'pre-configured edit mode controller pre-populates observation values',
      (tester) async {
        final editController = WizardController(
          category: ObservationCategory.full,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        editController.setBleedingFlow(Bleeding.light);
        editController.setSensation(Sensation.wet);
        editController.setLubrication(true);
        addTearDown(editController.dispose);

        await tester.pumpWidget(
          buildDirectDialogWidget(controller: editController),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Single Observation'), findsOneWidget);
        bool isSelected(String label) => tester
            .widget<OptionCard>(find.widgetWithText(OptionCard, label))
            .isSelected;

        // Bleeding step reflects the pre-configured flow.
        expect(isSelected('Light (L)'), isTrue);
        expect(isSelected('No Bleeding'), isFalse);

        // Sensation step reflects the pre-configured sensation/lubrication.
        editController.nextStep();
        await tester.pumpAndSettle();
        expect(find.textContaining('Step 2 of 5: Sensation'), findsOneWidget);
        expect(isSelected('Wet'), isTrue);
        expect(isSelected('Dry'), isFalse);
        expect(isSelected('Yes Lubrication'), isTrue);
        expect(isSelected('Not Lubricative'), isFalse);
      },
    );

    testWidgets(
      'pumping out an internally-owned dialog disposes its controller without errors',
      (tester) async {
        await tester.pumpWidget(buildDirectDialogWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AddObservationDialog), findsOneWidget);
        final ownedController = findDialogController(tester);
        expectControllerNotDisposed(ownedController);

        // Replace dialog with empty container to trigger dispose
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddObservationDialog), findsNothing);
        expectControllerDisposed(ownedController);
      },
    );

    testWidgets(
      'pumping out an externally-passed controller does not dispose external controller',
      (tester) async {
        final externalController = WizardController(
          category: ObservationCategory.full,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(externalController.dispose);

        await tester.pumpWidget(
          buildDirectDialogWidget(controller: externalController),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddObservationDialog), findsOneWidget);

        // Replace dialog to trigger AddObservationDialog.dispose()
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddObservationDialog), findsNothing);

        // Verify external controller is still alive and can be notified/mutated
        expect(
          () => externalController.setSelectedDate(DateTime(2026, 7, 28)),
          returnsNormally,
        );
        expect(externalController.selectedDate, DateTime(2026, 7, 28));
      },
    );
  });

  group('Suite 2: didUpdateWidget Dynamic Reconfiguration', () {
    testWidgets(
      'swapping widget.controller cleanly switches active step, title, and listeners',
      (tester) async {
        final controllerA = WizardController(
          category: ObservationCategory.bleeding,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        final controllerB = WizardController(
          category: ObservationCategory.pain,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(controllerA.dispose);
        addTearDown(controllerB.dispose);

        await tester.pumpWidget(
          buildDirectDialogWidget(controller: controllerA),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Bleeding'), findsOneWidget);
        expect(find.textContaining('Step 1 of 3: Bleeding'), findsOneWidget);

        // Rebuild with controllerB
        await tester.pumpWidget(
          buildDirectDialogWidget(controller: controllerB),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Pain'), findsOneWidget);
        expect(
          find.textContaining('Step 1 of 2: Pain Details'),
          findsOneWidget,
        );

        // Mutate controllerB and verify UI reacts
        OptionCard yesCard() => tester.widget<OptionCard>(
          find.widgetWithText(OptionCard, 'Yes (Log Pain)'),
        );
        expect(yesCard().isSelected, isFalse);

        controllerB.setHasPain(true);
        await tester.pumpAndSettle();

        expect(controllerB.hasPain, isTrue);
        expect(yesCard().isSelected, isTrue);
      },
    );

    testWidgets(
      'rebuilding with identical controller reference preserves existing state',
      (tester) async {
        final controller = WizardController(
          category: ObservationCategory.full,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildDirectDialogWidget(controller: controller),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Step 1 of 5: Bleeding'), findsOneWidget);

        // Advance controller to next step
        controller.setNoBleeding();
        controller.nextStep();
        await tester.pumpAndSettle();

        expect(find.textContaining('Step 2 of 5: Sensation'), findsOneWidget);

        // Rebuild with same controller instance
        await tester.pumpWidget(
          buildDirectDialogWidget(controller: controller),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Step 2 of 5: Sensation'), findsOneWidget);
      },
    );

    testWidgets(
      'updating from owned controller to external controller disposes internal controller',
      (tester) async {
        final externalController = WizardController(
          category: ObservationCategory.intercourse,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(externalController.dispose);

        // First mount without controller (owned)
        await tester.pumpWidget(buildDirectDialogWidget());
        await tester.pumpAndSettle();

        expect(find.text('Log Single Observation'), findsOneWidget);
        final ownedController = findDialogController(tester);
        expect(ownedController, isNot(same(externalController)));
        expectControllerNotDisposed(ownedController);

        // Update with external controller
        await tester.pumpWidget(
          buildDirectDialogWidget(controller: externalController),
        );
        await tester.pumpAndSettle();

        expectControllerDisposed(ownedController);
        expectControllerNotDisposed(externalController);
        expect(find.text('Log Intercourse'), findsOneWidget);
        expect(
          find.textContaining('Step 1 of 1: Comments & Save'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'updating from external controller to null creates owned internal controller without disposing external',
      (tester) async {
        final externalController = WizardController(
          category: ObservationCategory.intercourse,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(externalController.dispose);

        // First mount with external controller (not owned)
        await tester.pumpWidget(
          buildDirectDialogWidget(controller: externalController),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Intercourse'), findsOneWidget);

        // Update to no controller -> dialog builds its own default controller
        await tester.pumpWidget(buildDirectDialogWidget());
        await tester.pumpAndSettle();

        expect(find.text('Log Intercourse'), findsNothing);
        expect(find.text('Log Single Observation'), findsOneWidget);
        expect(find.textContaining('Step 1 of 5: Bleeding'), findsOneWidget);

        // External controller must remain alive and usable
        expect(
          () => externalController.setSelectedDate(DateTime(2026, 7, 28)),
          returnsNormally,
        );

        // The new internal controller is owned: removing the dialog disposes
        // it without errors, and the external controller is still untouched.
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddObservationDialog), findsNothing);
        expect(
          () => externalController.setSelectedDate(DateTime(2026, 7, 29)),
          returnsNormally,
        );
        expect(externalController.selectedDate, DateTime(2026, 7, 29));
      },
    );
  });

  group('Suite 3: Date & Time Picker Interactions (_pickDate / _pickTime)', () {
    testWidgets(
      'date picker flow: selecting date updates UI and controller; cancelling preserves date',
      (tester) async {
        final controller = WizardController(
          category: ObservationCategory.full,
          defaultDate: DateTime(2026, 7, 27, 10, 30),
          dbService: testDb,
        );
        addTearDown(controller.dispose);

        await pumpDialogInNavigator(tester, controller: controller);

        expect(
          find.text(AppDateFormats.fullDate.format(DateTime(2026, 7, 27))),
          findsOneWidget,
        );

        // Tap calendar icon to open date picker
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Verify date picker is visible
        expect(find.text('Select date'), findsWidgets);

        // Tap day 15 on the calendar
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Tap OK
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(controller.selectedDate.day, 15);
        expect(
          find.text(AppDateFormats.fullDate.format(DateTime(2026, 7, 15))),
          findsOneWidget,
        );

        // Tap calendar again and Cancel
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Date remains July 15
        expect(controller.selectedDate.day, 15);
        expect(
          find.text(AppDateFormats.fullDate.format(DateTime(2026, 7, 15))),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'time picker flow: selecting time updates UI and controller; cancelling preserves time',
      (tester) async {
        final controller = WizardController(
          category: ObservationCategory.full,
          defaultDate: DateTime(2026, 7, 27, 10, 30),
          dbService: testDb,
        );
        addTearDown(controller.dispose);

        await pumpDialogInNavigator(tester, controller: controller);

        final initialTimeText = const TimeOfDay(
          hour: 10,
          minute: 30,
        ).format(tester.element(find.byType(AddObservationDialog)));
        expect(find.text(initialTimeText), findsOneWidget);

        // Tap access_time icon to open time picker
        await tester.tap(find.byIcon(Icons.access_time));
        await tester.pumpAndSettle();

        // Confirm time picker dialog opened
        expect(find.text('Select time'), findsWidgets);

        // Switch to keyboard entry mode and enter a different time (9:45 AM)
        await tester.tap(find.byIcon(Icons.keyboard_outlined));
        await tester.pumpAndSettle();

        final timeFields = find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        );
        expect(timeFields, findsNWidgets(2));
        await tester.enterText(timeFields.at(0), '9');
        await tester.enterText(timeFields.at(1), '45');
        await tester.pumpAndSettle();

        // Tap OK to confirm
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        const newTime = TimeOfDay(hour: 9, minute: 45);
        expect(controller.selectedTime, newTime);
        final newTimeText = newTime.format(
          tester.element(find.byType(AddObservationDialog)),
        );
        expect(find.text(newTimeText), findsOneWidget);
        expect(find.text(initialTimeText), findsNothing);

        // Tap access_time icon again and tap Cancel
        await tester.tap(find.byIcon(Icons.access_time));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Cancelling preserves the newly updated time
        expect(controller.selectedTime, newTime);
        expect(find.text(newTimeText), findsOneWidget);
      },
    );
  });

  group('Suite 4: Step Navigation & Dialog Dismissal', () {
    testWidgets(
      'step navigation advances and returns via back button, updating progress',
      (tester) async {
        final controller = WizardController(
          category: ObservationCategory.full,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(controller.dispose);

        await pumpDialogInNavigator(tester, controller: controller);

        double progressValue() => tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value!;

        // Step 1: Bleeding
        expect(find.textContaining('Step 1 of 5: Bleeding'), findsOneWidget);
        expect(find.text('Back'), findsNothing);
        expect(progressValue(), closeTo(1 / 5, 1e-9));

        // Select No Bleeding -> advances to Step 2
        await tester.tap(find.text('No Bleeding'));
        await tester.pumpAndSettle();

        // Step 2: Sensation
        expect(find.textContaining('Step 2 of 5: Sensation'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(progressValue(), closeTo(2 / 5, 1e-9));

        // Tap Back button -> returns to Step 1
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Step 1 of 5: Bleeding'), findsOneWidget);
        expect(progressValue(), closeTo(1 / 5, 1e-9));
      },
    );

    testWidgets(
      'step navigation renders each wizard step card throughout flow',
      (tester) async {
        final controller = WizardController(
          category: ObservationCategory.full,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(controller.dispose);

        await pumpDialogInNavigator(tester, controller: controller);

        // Step 1: Bleeding Flow
        expect(find.textContaining('Step 1 of 5: Bleeding'), findsOneWidget);
        await tester.tap(find.text('Light (L)'));
        await tester.pumpAndSettle();

        // Step 2: Bleeding Color
        expect(find.textContaining('Step 2 of 6: Blood Color'), findsOneWidget);
        await tester.tap(find.text('Red (R)'));
        await tester.pumpAndSettle();

        // Step 3: Sensation
        expect(find.textContaining('Step 3 of 6: Sensation'), findsOneWidget);
        await tester.tap(find.text('Wet'));
        await tester.pumpAndSettle();

        // Step 4: Lubrication
        expect(find.textContaining('Step 4 of 7: Lubrication'), findsOneWidget);
        await tester.tap(find.text('Yes Lubrication'));
        await tester.pumpAndSettle();

        // Step 5: Mucus Presence
        expect(find.textContaining('Step 5 of 7: Mucus'), findsOneWidget);
        await tester.tap(find.text('Yes Mucus'));
        await tester.pumpAndSettle();

        // Step 6: Mucus Stretch
        expect(find.textContaining('Step 6 of 10: Stretch'), findsOneWidget);
        await tester.tap(find.text('Sticky'));
        await tester.pumpAndSettle();

        // Step 7: Mucus Color
        expect(
          find.textContaining('Step 7 of 11: Mucus Color'),
          findsOneWidget,
        );
        await tester.tap(find.text('Clear (K)'));
        await tester.pumpAndSettle();

        // Step 8: Mucus Consistency
        expect(
          find.textContaining('Step 8 of 11: Consistency'),
          findsOneWidget,
        );
        await tester.tap(find.text('Gummy (Gluey)'));
        await tester.pumpAndSettle();

        // Step 9: Frequency
        expect(find.textContaining('Step 9 of 11: Frequency'), findsOneWidget);
        await tester.tap(find.text('Once (x1)'));
        await tester.pumpAndSettle();

        // Step 10: Pain
        expect(find.textContaining('Step 10 of 11: Pain'), findsOneWidget);
        await tester.tap(find.text('Yes (Log Pain)'));
        await tester.pumpAndSettle();

        // Step 11: Pain Details
        expect(
          find.textContaining('Step 11 of 12: Pain Details'),
          findsOneWidget,
        );
        expect(find.text('Continue'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 12: Comments & Save
        expect(
          find.textContaining('Step 12 of 12: Comments & Save'),
          findsOneWidget,
        );
        expect(find.text('Save Observation'), findsOneWidget);
      },
    );

    testWidgets('tapping close icon button pops and dismisses the dialog', (
      tester,
    ) async {
      await pumpDialogInNavigator(tester);

      expect(find.byType(AddObservationDialog), findsOneWidget);

      // Tap close icon button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(AddObservationDialog), findsNothing);
    });
  });

  group('Suite 5: Save Workflow & Error Handling (_saveLog)', () {
    testWidgets('save button is not rendered on incomplete steps', (
      tester,
    ) async {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: testDb,
      );
      addTearDown(controller.dispose);

      await pumpDialogInNavigator(tester, controller: controller);

      // Step 1
      expect(find.text('Save Observation'), findsNothing);

      // Advance to Step 2
      await tester.tap(find.text('No Bleeding'));
      await tester.pumpAndSettle();

      // Step 2
      expect(find.text('Save Observation'), findsNothing);
    });

    testWidgets('successful save saves observation and pops dialog', (
      tester,
    ) async {
      final controller = WizardController(
        category: ObservationCategory.bleeding,
        defaultDate: defaultDate,
        dbService: testDb,
      );
      addTearDown(controller.dispose);

      await pumpDialogInNavigator(tester, controller: controller);

      // In bleeding category:
      // Step 1: Bleeding flow -> choose Light (L)
      await tester.tap(find.text('Light (L)'));
      await tester.pumpAndSettle();

      // Step 2: Blood Color -> choose Red (R)
      await tester.tap(find.text('Red (R)'));
      await tester.pumpAndSettle();

      // Step 3: Comments & Save
      expect(
        find.textContaining('Step 3 of 3: Comments & Save'),
        findsOneWidget,
      );
      expect(find.text('Save Observation'), findsOneWidget);

      // Tap Save Observation
      await tester.tap(find.text('Save Observation'));
      await tester.pumpAndSettle();

      // Dialog should be popped
      expect(find.byType(AddObservationDialog), findsNothing);

      // Verify observation was saved in db
      final cycles = await testDb.streamCycles().first;
      final dailyEntry = cycles.first.dailyEntries[defaultDate.dateKey];
      expect(dailyEntry, isNotNull);
      final entries = dailyEntry!.observations;
      expect(entries, isNotEmpty);
      expect(entries.first.bleeding, Bleeding.light);
      expect(entries.first.bleedingColor, 'R');
    });

    testWidgets('circular progress indicator is shown while isSaving is true', (
      tester,
    ) async {
      final delayedDb = DelayedDatabaseService();
      final controller = WizardController(
        category: ObservationCategory.bleeding,
        defaultDate: defaultDate,
        dbService: delayedDb,
      );
      addTearDown(controller.dispose);

      await pumpDialogInNavigator(
        tester,
        controller: controller,
        dbService: delayedDb,
      );

      // Advance to comments step
      await tester.tap(find.text('Light (L)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Red (R)'));
      await tester.pumpAndSettle();

      expect(find.text('Save Observation'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save Observation'));
      // Pump without settling to catch saving state
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Observation'), findsNothing);

      // Complete save
      delayedDb.saveCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.byType(AddObservationDialog), findsNothing);
    });

    testWidgets(
      'save failure displays error snackbar and keeps dialog mounted',
      (tester) async {
        final failingDb = FailingDatabaseService(
          errorMessage: 'Network timeout',
        );
        final controller = WizardController(
          category: ObservationCategory.bleeding,
          defaultDate: defaultDate,
          dbService: failingDb,
        );
        addTearDown(controller.dispose);

        await pumpDialogInNavigator(
          tester,
          controller: controller,
          dbService: failingDb,
        );

        // Advance to comments step
        await tester.tap(find.text('Light (L)'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Red (R)'));
        await tester.pumpAndSettle();

        // Tap Save Observation
        await tester.tap(find.text('Save Observation'));
        await tester.pumpAndSettle();

        // Verify SnackBar with error is displayed
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining(
            'Error saving observation: Exception: Network timeout',
          ),
          findsOneWidget,
        );

        // Verify dialog remains mounted
        expect(find.byType(AddObservationDialog), findsOneWidget);
      },
    );

    testWidgets(
      'saveObservation returning false keeps dialog mounted without popping or showing error',
      (tester) async {
        final rejectingController = _RejectingWizardController(
          category: ObservationCategory.bleeding,
          defaultDate: defaultDate,
          dbService: testDb,
        );
        addTearDown(rejectingController.dispose);

        await pumpDialogInNavigator(tester, controller: rejectingController);

        // Advance to comments step
        await tester.tap(find.text('Light (L)'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Red (R)'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save Observation'));
        await tester.pumpAndSettle();

        expect(rejectingController.saveCalls, 1);

        // Dialog is not popped and no error snackbar is shown
        expect(find.byType(AddObservationDialog), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text('Save Observation'), findsOneWidget);

        // Nothing was persisted
        final cycles = await testDb.streamCycles().first;
        final hasEntry = cycles.any(
          (c) => c.dailyEntries.containsKey(defaultDate.dateKey),
        );
        expect(hasEntry, isFalse);
      },
    );
  });
}
