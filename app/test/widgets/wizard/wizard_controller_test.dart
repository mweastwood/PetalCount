import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/widgets/wizard/wizard.dart';

void main() {
  late InMemoryDatabaseService db;
  final defaultDate = DateTime(2026, 7, 27, 10, 30);

  setUp(() {
    db = InMemoryDatabaseService();
  });

  group('WizardController Initialization & Defaults', () {
    test('default full category initializes with correct defaults', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      expect(controller.category, ObservationCategory.full);
      expect(controller.currentStepIndex, 0);
      expect(controller.isFirstStep, isTrue);
      expect(controller.isLastStep, isFalse);
      expect(controller.hasBleeding, isNull);
      expect(controller.bleedingFlow, isNull);
      expect(controller.bleedingColor, isNull);
      expect(controller.sensation, isNull);
      expect(controller.hasLubrication, isNull);
      expect(controller.hasMucus, isNull);
      expect(controller.hasPain, isNull);
      expect(controller.hasIntercourse, isNull);
      expect(controller.frequency, Frequency.none);
      expect(controller.isSaving, isFalse);
      expect(controller.selectedDate, DateTime(2026, 7, 27));
      expect(controller.selectedTime, const TimeOfDay(hour: 10, minute: 30));
      expect(controller.combinedDateTime, DateTime(2026, 7, 27, 10, 30));

      expect(controller.showBleeding, isTrue);
      expect(controller.showMucus, isTrue);
      expect(controller.showPain, isTrue);
      expect(controller.showIntercourse, isTrue);

      controller.dispose();
    });

    test('bleeding category pre-populates hasBleeding = true', () {
      final controller = WizardController(
        category: ObservationCategory.bleeding,
        defaultDate: defaultDate,
        dbService: db,
      );

      expect(controller.category, ObservationCategory.bleeding);
      expect(controller.hasBleeding, isTrue);
      expect(controller.showBleeding, isTrue);
      expect(controller.showMucus, isFalse);
      expect(controller.showPain, isFalse);
      expect(controller.showIntercourse, isFalse);
      expect(controller.activeSteps, [
        WizardStep.bleedingFlow,
        WizardStep.bleedingColor,
        WizardStep.comments,
      ]);

      controller.dispose();
    });

    test('mucus category initializes with correct steps and visibility', () {
      final controller = WizardController(
        category: ObservationCategory.mucus,
        defaultDate: defaultDate,
        dbService: db,
      );

      expect(controller.category, ObservationCategory.mucus);
      expect(controller.showBleeding, isFalse);
      expect(controller.showMucus, isTrue);
      expect(controller.showPain, isFalse);
      expect(controller.showIntercourse, isFalse);
      expect(controller.activeSteps, [
        WizardStep.sensation,
        WizardStep.mucus,
        WizardStep.comments,
      ]);

      controller.dispose();
    });

    test(
      'intercourse category pre-populates hasIntercourse = true and single step',
      () {
        final controller = WizardController(
          category: ObservationCategory.intercourse,
          defaultDate: defaultDate,
          dbService: db,
        );

        expect(controller.category, ObservationCategory.intercourse);
        expect(controller.hasIntercourse, isTrue);
        expect(controller.showIntercourse, isTrue);
        expect(controller.activeSteps, [WizardStep.comments]);
        expect(controller.isFirstStep, isTrue);
        expect(controller.isLastStep, isTrue);
        expect(controller.progress, 1.0);

        controller.dispose();
      },
    );

    test(
      'pain category pre-populates hasPain = true with painDetails step',
      () {
        final controller = WizardController(
          category: ObservationCategory.pain,
          defaultDate: defaultDate,
          dbService: db,
        );

        expect(controller.category, ObservationCategory.pain);
        expect(controller.hasPain, isTrue);
        expect(controller.showPain, isTrue);
        expect(controller.activeSteps, [
          WizardStep.painDetails,
          WizardStep.comments,
        ]);

        controller.dispose();
      },
    );
  });

  group('WizardController Step Routing & Branching', () {
    test('selecting No Bleeding omits bleedingColor step in full flow', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setNoBleeding();
      expect(controller.hasBleeding, isFalse);
      expect(controller.bleedingFlow, Bleeding.none);
      expect(controller.bleedingColor, isNull);
      expect(
        controller.activeSteps.contains(WizardStep.bleedingColor),
        isFalse,
      );
      expect(controller.activeSteps.contains(WizardStep.sensation), isTrue);

      controller.dispose();
    });

    test('heavy bleeding skips sensation, lubrication, and mucus steps', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setBleedingFlow(Bleeding.heavy);
      expect(controller.isHeavyOrModerateBleeding, isTrue);
      expect(controller.showMucus, isFalse);

      final steps = controller.activeSteps;
      expect(steps, [
        WizardStep.bleedingFlow,
        WizardStep.bleedingColor,
        WizardStep.pain,
        WizardStep.comments,
      ]);

      controller.dispose();
    });

    test(
      'moderate bleeding also skips sensation, lubrication, and mucus steps',
      () {
        final controller = WizardController(
          category: ObservationCategory.full,
          defaultDate: defaultDate,
          dbService: db,
        );

        controller.setBleedingFlow(Bleeding.moderate);
        expect(controller.isHeavyOrModerateBleeding, isTrue);
        expect(controller.activeSteps.contains(WizardStep.sensation), isFalse);
        expect(controller.activeSteps.contains(WizardStep.mucus), isFalse);

        controller.dispose();
      },
    );

    test('light bleeding retains sensation and mucus steps', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setBleedingFlow(Bleeding.light);
      expect(controller.isHeavyOrModerateBleeding, isFalse);
      expect(controller.activeSteps.contains(WizardStep.sensation), isTrue);
      expect(controller.activeSteps.contains(WizardStep.mucus), isTrue);

      controller.dispose();
    });

    test('dry sensation omits lubrication step', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setSensation(Sensation.dry);
      expect(controller.hasLubrication, isFalse);
      expect(controller.activeSteps.contains(WizardStep.lubrication), isFalse);

      controller.dispose();
    });

    test('wet or damp sensation includes lubrication step', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setSensation(Sensation.wet);
      expect(controller.activeSteps.contains(WizardStep.lubrication), isTrue);

      controller.setSensation(Sensation.damp);
      expect(controller.activeSteps.contains(WizardStep.lubrication), isTrue);

      controller.dispose();
    });

    test('mucus with sticky stretch includes consistency step', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setHasMucus(true);
      controller.setStretch(Stretch.sticky);

      final steps = controller.activeSteps;
      expect(steps.contains(WizardStep.mucusStretch), isTrue);
      expect(steps.contains(WizardStep.mucusColor), isTrue);
      expect(steps.contains(WizardStep.mucusConsistency), isTrue);
      expect(steps.contains(WizardStep.frequency), isTrue);

      controller.dispose();
    });

    test('mucus with non-sticky stretch excludes consistency step', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setHasMucus(true);
      controller.setStretch(Stretch.stretchy);

      final steps = controller.activeSteps;
      expect(steps.contains(WizardStep.mucusStretch), isTrue);
      expect(steps.contains(WizardStep.mucusColor), isTrue);
      expect(steps.contains(WizardStep.mucusConsistency), isFalse);
      expect(steps.contains(WizardStep.frequency), isTrue);

      controller.dispose();
    });

    test('hasMucus == false omits all mucus sub-steps', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setHasMucus(false);
      final steps = controller.activeSteps;
      expect(steps.contains(WizardStep.mucusStretch), isFalse);
      expect(steps.contains(WizardStep.mucusColor), isFalse);
      expect(steps.contains(WizardStep.mucusConsistency), isFalse);
      expect(steps.contains(WizardStep.frequency), isFalse);

      controller.dispose();
    });

    test('hasPain == true conditionally appends painDetails step', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      expect(controller.activeSteps.contains(WizardStep.painDetails), isFalse);
      controller.setHasPain(true);
      expect(controller.activeSteps.contains(WizardStep.painDetails), isTrue);
      controller.setHasPain(false);
      expect(controller.activeSteps.contains(WizardStep.painDetails), isFalse);

      controller.dispose();
    });
  });

  group('WizardController State Mutators & Resets', () {
    test('setHasMucus(false) resets stretch, colors, and consistencies', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setHasMucus(true);
      controller.setStretch(Stretch.sticky);
      controller.setSelectedColors([MucusColor.cloudy, MucusColor.clear]);
      controller.setConsistency(isGummy: true, isPasty: true);

      expect(controller.stretch, Stretch.sticky);
      expect(controller.selectedColors.length, 2);
      expect(controller.isGummy, isTrue);
      expect(controller.isPasty, isTrue);
      expect(controller.hasSelectedConsistency, isTrue);

      controller.setHasMucus(false);

      expect(controller.hasMucus, isFalse);
      expect(controller.stretch, Stretch.none);
      expect(controller.selectedColors, isEmpty);
      expect(controller.isGummy, isFalse);
      expect(controller.isPasty, isFalse);
      expect(controller.hasSelectedConsistency, isFalse);

      controller.dispose();
    });

    test('setHasBleeding(false) clears flow and color', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setBleedingFlow(Bleeding.light);
      controller.setBleedingColor('R');

      controller.setHasBleeding(false);
      expect(controller.hasBleeding, isFalse);
      expect(controller.bleedingFlow, Bleeding.none);
      expect(controller.bleedingColor, isNull);

      controller.dispose();
    });

    test('pain mutators and formattedPainTypes formatting', () {
      final controller = WizardController(
        category: ObservationCategory.pain,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.togglePainType('Cramps', true);
      controller.togglePainType('Headache', true);
      expect(controller.formattedPainTypes, ['Cramps', 'Headache']);

      // Untoggle
      controller.togglePainType('Headache', false);
      expect(controller.formattedPainTypes, ['Cramps']);

      // Toggle Abdominal Pain without left/right
      controller.togglePainType('Abdominal Pain', true);
      expect(controller.formattedPainTypes, ['Cramps', 'Abdominal Pain']);

      // Abdominal Pain with Left
      controller.setAbdominalLeft(true);
      expect(controller.formattedPainTypes, [
        'Cramps',
        'Abdominal Pain (Left)',
      ]);

      // Abdominal Pain with Right only
      controller.setAbdominalLeft(false);
      controller.setAbdominalRight(true);
      expect(controller.formattedPainTypes, [
        'Cramps',
        'Abdominal Pain (Right)',
      ]);

      // Abdominal Pain with Left & Right
      controller.setAbdominalLeft(true);
      expect(controller.formattedPainTypes, [
        'Cramps',
        'Abdominal Pain (Left & Right)',
      ]);

      // Pain level
      controller.setPainLevel(4.5);
      expect(controller.painLevel, 4.5);

      controller.dispose();
    });

    test('date and time setters update combinedDateTime and notify', () {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      var notified = 0;
      controller.addListener(() => notified++);

      controller.setSelectedDate(DateTime(2026, 8, 1));
      controller.setSelectedTime(const TimeOfDay(hour: 14, minute: 45));

      expect(notified, 2);
      expect(controller.selectedDate, DateTime(2026, 8, 1));
      expect(controller.selectedTime, const TimeOfDay(hour: 14, minute: 45));
      expect(controller.combinedDateTime, DateTime(2026, 8, 1, 14, 45));

      controller.dispose();
    });
  });

  group('WizardController Navigation & Boundaries', () {
    test('nextStep and previousStep navigate with bounds clamping', () {
      final controller = WizardController(
        category: ObservationCategory.intercourse,
        defaultDate: defaultDate,
        dbService: db,
      );

      // Only 1 step: comments
      expect(controller.activeSteps.length, 1);
      expect(controller.currentStepIndex, 0);
      expect(controller.currentStep, WizardStep.comments);

      controller.nextStep();
      expect(controller.currentStepIndex, 0); // Cannot advance past end

      controller.previousStep();
      expect(controller.currentStepIndex, 0); // Cannot go below 0

      controller.dispose();
    });

    test('navigation across multiple steps', () {
      final controller = WizardController(
        category: ObservationCategory.bleeding,
        defaultDate: defaultDate,
        dbService: db,
      );

      expect(controller.activeSteps.length, 3);
      expect(controller.currentStepIndex, 0);
      expect(controller.currentStep, WizardStep.bleedingFlow);
      expect(controller.isFirstStep, isTrue);

      controller.nextStep();
      expect(controller.currentStepIndex, 1);
      expect(controller.currentStep, WizardStep.bleedingColor);
      expect(controller.isFirstStep, isFalse);
      expect(controller.isLastStep, isFalse);

      controller.nextStep();
      expect(controller.currentStepIndex, 2);
      expect(controller.currentStep, WizardStep.comments);
      expect(controller.isLastStep, isTrue);

      // Past boundary
      controller.nextStep();
      expect(controller.currentStepIndex, 2);

      // Step back
      controller.previousStep();
      expect(controller.currentStepIndex, 1);
      expect(controller.currentStep, WizardStep.bleedingColor);

      // Go to step
      controller.goToStep(0);
      expect(controller.currentStepIndex, 0);
      expect(controller.currentStep, WizardStep.bleedingFlow);

      // Out of range goToStep
      controller.goToStep(99);
      expect(controller.currentStepIndex, 0);
      controller.goToStep(-1);
      expect(controller.currentStepIndex, 0);

      controller.dispose();
    });
  });

  group('WizardController saveObservation Persistence', () {
    test('saves comprehensive observation cleanly to database', () async {
      await db.startNewCycle(DateTime(2026, 7, 1), []);
      final cyclesBefore = await db.streamCycles().first;
      final cycle = cyclesBefore.first;

      final controller = WizardController(
        category: ObservationCategory.full,
        cycle: cycle,
        defaultDate: defaultDate,
        dbService: db,
      );

      controller.setBleedingFlow(Bleeding.light);
      controller.setBleedingColor('R');
      controller.setSensation(Sensation.damp);
      controller.setLubrication(true);
      controller.setHasMucus(true);
      controller.setStretch(Stretch.sticky);
      controller.setSelectedColors([MucusColor.clear, MucusColor.cloudy]);
      controller.setConsistency(isGummy: true, isPasty: false);
      controller.setFrequency(Frequency.twice);
      controller.setHasIntercourse(true);
      controller.setHasPain(true);
      controller.togglePainType('Cramps', true);
      controller.setPainLevel(4.0);
      controller.commentController.text = 'User note';

      var notifiedSaving = false;
      controller.addListener(() {
        if (controller.isSaving) notifiedSaving = true;
      });

      final result = await controller.saveObservation();
      expect(result, isTrue);
      expect(notifiedSaving, isTrue);
      expect(controller.isSaving, isFalse);

      final cycles = await db.streamCycles().first;
      final obsList = cycles.first.dailyEntries['2026-07-27']!.observations;
      expect(obsList.length, 1);
      final obs = obsList.first;
      expect(obs.bleeding, Bleeding.light);
      expect(obs.bleedingColor, 'R');
      expect(obs.sensation, Sensation.damp);
      expect(obs.consistencies.contains(Consistency.lubricative), isTrue);
      expect(obs.consistencies.contains(Consistency.gummy), isTrue);
      expect(obs.stretch, Stretch.sticky);
      expect(obs.colors, [MucusColor.clear, MucusColor.cloudy]);
      expect(obs.intercourse, isTrue);
      expect(obs.painLevel, 4.0);
      expect(obs.painTypes, ['Cramps']);
      expect(obs.comment, 'Intercourse • User note');
      expect(obs.isVdrsExplicit, isTrue);

      controller.dispose();
    });

    test(
      'intercourse comment formatted properly when comment is empty',
      () async {
        await db.startNewCycle(DateTime(2026, 7, 1), []);
        final cyclesBefore = await db.streamCycles().first;
        final cycle = cyclesBefore.first;

        final controller = WizardController(
          category: ObservationCategory.intercourse,
          cycle: cycle,
          defaultDate: defaultDate,
          dbService: db,
        );

        final result = await controller.saveObservation();
        expect(result, isTrue);

        final cycles = await db.streamCycles().first;
        final obsList = cycles.first.dailyEntries['2026-07-27']!.observations;
        expect(obsList.length, 1);
        expect(obsList.first.intercourse, isTrue);
        expect(obsList.first.comment, 'Intercourse');

        controller.dispose();
      },
    );

    test('heavy bleeding clears mucus data upon save', () async {
      await db.startNewCycle(DateTime(2026, 7, 1), []);
      final cyclesBefore = await db.streamCycles().first;
      final cycle = cyclesBefore.first;

      final controller = WizardController(
        category: ObservationCategory.full,
        cycle: cycle,
        defaultDate: defaultDate,
        dbService: db,
      );

      // Pre-set mucus fields before selecting heavy bleeding
      controller.setHasMucus(true);
      controller.setStretch(Stretch.stretchy);
      controller.setBleedingFlow(Bleeding.heavy);
      controller.setBleedingColor('R');

      await controller.saveObservation();

      final cycles = await db.streamCycles().first;
      final obsList = cycles.first.dailyEntries['2026-07-27']!.observations;
      final obs = obsList.first;
      expect(obs.bleeding, Bleeding.heavy);
      expect(obs.sensation, Sensation.dry);
      expect(obs.stretch, Stretch.none);
      expect(obs.colors, isEmpty);
      expect(obs.consistencies, isEmpty);

      controller.dispose();
    });
    test('saveObservation rethrows when database fails', () async {
      final controller = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: db,
      );

      // Unlink chart to cause saveObservation to fail or simulate DB failure
      // Or pass a failing DatabaseService
      final failingController = WizardController(
        category: ObservationCategory.full,
        defaultDate: defaultDate,
        dbService: _ThrowingDatabaseService(),
      );

      await expectLater(
        () => failingController.saveObservation(),
        throwsA(isA<Exception>()),
      );
      expect(failingController.isSaving, isFalse);
      failingController.dispose();
      controller.dispose();
    });
  });
}

class _ThrowingDatabaseService extends InMemoryDatabaseService {
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
    throw Exception('Database write failed');
  }
}
