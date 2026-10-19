import '../models/cycle.dart';
import '../models/daily_entry.dart';
import '../models/observation.dart';
import '../utils/date_utils.dart';
import 'creighton_logic.dart';

/// Represents an atomic set of cycle upserts and deletions resulting from
/// a cycle mutation operation.
class CycleMutationPlan {
  final List<Cycle> cyclesToUpsert;
  final List<String> cycleIdentifiersToDelete;

  const CycleMutationPlan({
    required this.cyclesToUpsert,
    this.cycleIdentifiersToDelete = const [],
  });
}

/// Represents the result of adding a new observation to a cycle, including
/// the recalculated cycle and the resolved daily entry for notification checks.
class ObservationSaveResult {
  final Cycle updatedCycle;
  final DailyEntry resolvedDailyEntry;
  final Observation createdObservation;

  const ObservationSaveResult({
    required this.updatedCycle,
    required this.resolvedDailyEntry,
    required this.createdObservation,
  });
}

/// Shared domain coordinator for cycle lifecycle operations and observation
/// persistence across both cloud and in-memory database services.
class CycleCoordinator {
  static int _observationSequenceCounter = 0;

  /// Generates a collision-safe observation identifier combining microsecond
  /// timestamp precision with a monotonically increasing sequence counter.
  static String generateObservationIdentifier() {
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    final sequenceNumber = _observationSequenceCounter++;
    return '${microseconds}_$sequenceNumber';
  }

  /// Plans starting a new cycle on [startDate] and reallocating all existing
  /// daily entries across the updated cycle boundaries.
  static CycleMutationPlan planStartNewCycle({
    required List<Cycle> existingCycles,
    required DateTime startDate,
    required List<String> basicInfertilePatternCodes,
  }) {
    final normalizedStartDate = startDate.toNormalizedDate();
    final newCycleIdentifier = normalizedStartDate.dateKey;

    final newCycle = Cycle(
      id: newCycleIdentifier,
      startDate: normalizedStartDate,
      bipCodes: basicInfertilePatternCodes,
      dailyEntries: const {},
    );

    final combinedCycles = [
      ...existingCycles.where((cycle) => cycle.id != newCycleIdentifier),
      newCycle,
    ];

    final recalculatedCycles = CreightonLogic.reallocateAndRecalculateCycles(
      combinedCycles,
    );

    return CycleMutationPlan(cyclesToUpsert: recalculatedCycles);
  }

  /// Plans updating a cycle's start date, removing the old cycle document if
  /// its identifier changed, and reallocating all daily entries across cycles.
  static CycleMutationPlan planUpdateCycleStartDate({
    required List<Cycle> existingCycles,
    required String cycleIdentifier,
    required DateTime newStartDate,
  }) {
    final targetIndex = existingCycles.indexWhere(
      (cycle) => cycle.id == cycleIdentifier,
    );
    if (targetIndex == -1) {
      return const CycleMutationPlan(cyclesToUpsert: []);
    }

    final existingCycle = existingCycles[targetIndex];
    final normalizedNewStartDate = newStartDate.toNormalizedDate();
    final newCycleIdentifier = normalizedNewStartDate.dateKey;

    final updatedCycle = Cycle(
      id: newCycleIdentifier,
      startDate: normalizedNewStartDate,
      endDate: existingCycle.endDate,
      bipCodes: existingCycle.bipCodes,
      dailyEntries: existingCycle.dailyEntries,
    );

    final updatedCycleList = <Cycle>[];
    for (var index = 0; index < existingCycles.length; index++) {
      if (index == targetIndex) {
        updatedCycleList.add(updatedCycle);
      } else if (existingCycles[index].id != newCycleIdentifier) {
        updatedCycleList.add(existingCycles[index]);
      }
    }

    final recalculatedCycles = CreightonLogic.reallocateAndRecalculateCycles(
      updatedCycleList,
    );

    final identifiersToDelete = cycleIdentifier != newCycleIdentifier
        ? <String>[cycleIdentifier]
        : const <String>[];

    return CycleMutationPlan(
      cyclesToUpsert: recalculatedCycles,
      cycleIdentifiersToDelete: identifiersToDelete,
    );
  }

  /// Plans merging [cycleIdentifier] into its chronologically preceding cycle
  /// and recalculating all remaining cycles.
  static CycleMutationPlan planMergeCycleWithPrevious({
    required List<Cycle> existingCycles,
    required String cycleIdentifier,
  }) {
    final sortedCycles = List<Cycle>.from(existingCycles)
      ..sort((first, second) => first.startDate.compareTo(second.startDate));

    final targetIndex = sortedCycles.indexWhere(
      (cycle) => cycle.id == cycleIdentifier,
    );
    if (targetIndex <= 0) {
      return const CycleMutationPlan(cyclesToUpsert: []);
    }

    final targetCycle = sortedCycles[targetIndex];
    final previousCycle = sortedCycles[targetIndex - 1];

    final mergedDailyEntries = Map<String, DailyEntry>.from(
      previousCycle.dailyEntries,
    )..addAll(targetCycle.dailyEntries);

    final updatedPreviousCycle = previousCycle.copyWith(
      dailyEntries: mergedDailyEntries,
    );

    final remainingCycles = <Cycle>[];
    for (var index = 0; index < sortedCycles.length; index++) {
      if (index == targetIndex - 1) {
        remainingCycles.add(updatedPreviousCycle);
      } else if (index != targetIndex) {
        remainingCycles.add(sortedCycles[index]);
      }
    }

    final recalculatedCycles = CreightonLogic.reallocateAndRecalculateCycles(
      remainingCycles,
    );

    return CycleMutationPlan(
      cyclesToUpsert: recalculatedCycles,
      cycleIdentifiersToDelete: [cycleIdentifier],
    );
  }

  /// Plans deleting [cycleIdentifier] and recalculating the remaining cycles
  /// so cycle end dates stay synchronized.
  static CycleMutationPlan planDeleteCycle({
    required List<Cycle> existingCycles,
    required String cycleIdentifier,
  }) {
    final remainingCycles = existingCycles
        .where((cycle) => cycle.id != cycleIdentifier)
        .toList();

    final recalculatedCycles = remainingCycles.isEmpty
        ? const <Cycle>[]
        : CreightonLogic.reallocateAndRecalculateCycles(remainingCycles);

    return CycleMutationPlan(
      cyclesToUpsert: recalculatedCycles,
      cycleIdentifiersToDelete: [cycleIdentifier],
    );
  }

  /// Recalculates [targetCycle] with updated [basicInfertilePatternCodes].
  static Cycle recalculateCycleWithBasicInfertilePattern({
    required Cycle targetCycle,
    required List<String> basicInfertilePatternCodes,
  }) {
    final recalculatedEntries = CreightonLogic.recalculateCycle(
      entries: targetCycle.dailyEntries.values.toList(),
      bipCodes: basicInfertilePatternCodes,
    );

    return targetCycle.copyWith(
      bipCodes: basicInfertilePatternCodes,
      dailyEntries: recalculatedEntries,
    );
  }

  /// Adds an observation to [targetCycle] and recalculates all daily entries
  /// in that cycle.
  static ObservationSaveResult applyObservationToCycle({
    required Cycle targetCycle,
    required Observation observation,
  }) {
    final dateKey = observation.timestamp.dateKey;
    final currentEntries = Map<String, DailyEntry>.from(
      targetCycle.dailyEntries,
    );
    final existingEntry = currentEntries[dateKey];

    final updatedObservations = existingEntry != null
        ? (List<Observation>.from(existingEntry.observations)..add(observation))
        : <Observation>[observation];
    updatedObservations.sort(
      (first, second) => first.timestamp.compareTo(second.timestamp),
    );

    final resolvedEntry = CreightonLogic.resolveDailyEntry(
      date: observation.timestamp,
      observations: updatedObservations,
    );
    currentEntries[dateKey] = resolvedEntry;

    final recalculatedEntries = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: targetCycle.bipCodes,
    );

    final finalDailyEntry = recalculatedEntries[dateKey] ?? resolvedEntry;
    final updatedCycle = targetCycle.copyWith(
      dailyEntries: recalculatedEntries,
    );

    return ObservationSaveResult(
      updatedCycle: updatedCycle,
      resolvedDailyEntry: finalDailyEntry,
      createdObservation: observation,
    );
  }

  /// Removes [observationIdentifier] from [targetCycle] on [date] and
  /// recalculates the cycle's daily entries. Returns `null` if no change was
  /// needed because the date entry did not exist.
  static Cycle? removeObservationFromCycle({
    required Cycle targetCycle,
    required DateTime date,
    required String observationIdentifier,
  }) {
    final dateKey = date.dateKey;
    final currentEntries = Map<String, DailyEntry>.from(
      targetCycle.dailyEntries,
    );
    final existingEntry = currentEntries[dateKey];
    if (existingEntry == null) {
      return null;
    }

    final remainingObservations = existingEntry.observations
        .where((observation) => observation.id != observationIdentifier)
        .toList();

    if (remainingObservations.isEmpty) {
      currentEntries.remove(dateKey);
    } else {
      final resolvedDailyEntry = CreightonLogic.resolveDailyEntry(
        date: date,
        observations: remainingObservations,
      );
      currentEntries[dateKey] = resolvedDailyEntry;
    }

    final recalculatedEntries = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: targetCycle.bipCodes,
    );

    return targetCycle.copyWith(dailyEntries: recalculatedEntries);
  }
}
