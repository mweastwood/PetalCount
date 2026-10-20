import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('CycleCoordinator Domain Tests', () {
    test('generateObservationIdentifier generates unique monotonic IDs', () {
      final firstId = CycleCoordinator.generateObservationIdentifier();
      final secondId = CycleCoordinator.generateObservationIdentifier();
      expect(firstId, isNot(equals(secondId)));
    });

    test(
      'applyObservationToCycle and removeObservationFromCycle update and recalculate entries',
      () {
        final start = DateTime(2026, 6, 1);
        final initialCycle = Cycle(
          id: '2026-06-01',
          startDate: start,
          bipCodes: const ['6C'],
        );

        final obs1 = Observation(
          id: 'obs_1',
          timestamp: DateTime(2026, 6, 10, 9, 0),
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'user_1',
        );

        final saveResult1 = CycleCoordinator.applyObservationToCycle(
          targetCycle: initialCycle,
          observation: obs1,
        );
        expect(saveResult1.resolvedDailyEntry.resolvedVdrsCode, '10K x1');
        expect(
          saveResult1.updatedCycle.dailyEntries.containsKey('2026-06-10'),
          isTrue,
        );

        // Remove observation -> entry removed when no observations remain on that date
        final afterRemoval = CycleCoordinator.removeObservationFromCycle(
          targetCycle: saveResult1.updatedCycle,
          date: DateTime(2026, 6, 10),
          observationIdentifier: 'obs_1',
        );
        expect(afterRemoval, isNotNull);
        expect(afterRemoval!.dailyEntries.containsKey('2026-06-10'), isFalse);
      },
    );

    test(
      'planStartNewCycle, planUpdateCycleStartDate, planMergeCycleWithPrevious, and planDeleteCycle',
      () {
        final start1 = DateTime(2026, 6, 1);
        final cycle1 = Cycle(id: '2026-06-01', startDate: start1);
        final obsJune1 = Observation(
          id: 'o1',
          timestamp: start1,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.heavy,
          userId: 'u1',
        );
        final obsJune20 = Observation(
          id: 'o2',
          timestamp: DateTime(2026, 6, 20),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'u1',
        );

        var currentCycle = CycleCoordinator.applyObservationToCycle(
          targetCycle: cycle1,
          observation: obsJune1,
        ).updatedCycle;
        currentCycle = CycleCoordinator.applyObservationToCycle(
          targetCycle: currentCycle,
          observation: obsJune20,
        ).updatedCycle;

        // 1. Start new cycle on June 15
        final startPlan = CycleCoordinator.planStartNewCycle(
          existingCycles: [currentCycle],
          startDate: DateTime(2026, 6, 15),
          basicInfertilePatternCodes: const ['6C'],
        );
        expect(startPlan.cyclesToUpsert.length, 2);
        expect(
          startPlan.cyclesToUpsert[0].dailyEntries.containsKey('2026-06-01'),
          isTrue,
        );
        expect(
          startPlan.cyclesToUpsert[1].dailyEntries.containsKey('2026-06-20'),
          isTrue,
        );

        // 2. Update second cycle start date from June 15 to June 18
        final updatePlan = CycleCoordinator.planUpdateCycleStartDate(
          existingCycles: startPlan.cyclesToUpsert,
          cycleIdentifier: '2026-06-15',
          newStartDate: DateTime(2026, 6, 18),
        );
        expect(updatePlan.cycleIdentifiersToDelete, ['2026-06-15']);
        expect(updatePlan.cyclesToUpsert.last.id, '2026-06-18');

        // 3. Merge second cycle back into previous
        final mergePlan = CycleCoordinator.planMergeCycleWithPrevious(
          existingCycles: updatePlan.cyclesToUpsert,
          cycleIdentifier: '2026-06-18',
        );
        expect(mergePlan.cycleIdentifiersToDelete, ['2026-06-18']);
        expect(mergePlan.cyclesToUpsert.length, 1);
        expect(
          mergePlan.cyclesToUpsert.first.dailyEntries.containsKey('2026-06-20'),
          isTrue,
        );

        // 4. Delete cycle
        final deletePlan = CycleCoordinator.planDeleteCycle(
          existingCycles: mergePlan.cyclesToUpsert,
          cycleIdentifier: '2026-06-01',
        );
        expect(deletePlan.cycleIdentifiersToDelete, ['2026-06-01']);
        expect(deletePlan.cyclesToUpsert, isEmpty);
      },
    );
  });
}
