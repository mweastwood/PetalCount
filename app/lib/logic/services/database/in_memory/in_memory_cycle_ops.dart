part of '../in_memory_database_service.dart';

mixin _InMemoryCycleOps on _InMemoryDatabaseServiceBase {
  @override
  Stream<List<Cycle>> streamCycles() {
    return _buildCyclesStream().asBroadcastStream();
  }

  Stream<List<Cycle>> _buildCyclesStream() async* {
    final chartId = _chartId;
    if (chartId != null) {
      final chartCyclesData = _cycles[chartId] ?? {};
      final list = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      yield list;
    } else {
      yield [];
    }
    yield* _cyclesController.stream;
  }

  void _applyCycleMutationPlan(String chartId, CycleMutationPlan mutationPlan) {
    _cycles[chartId] ??= {};
    for (final cycleIdentifier in mutationPlan.cycleIdentifiersToDelete) {
      _cycles[chartId]!.remove(cycleIdentifier);
    }
    for (final cycle in mutationPlan.cyclesToUpsert) {
      _cycles[chartId]![cycle.id] = cycle.toMap();
    }
    _emitCycles();
  }

  @override
  Future<void> startNewCycle(DateTime startDate, List<String> bipCodes) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final existingCycles = (_cycles[chartId] ?? {}).values
        .map((data) => Cycle.fromMap(data))
        .toList();

    final mutationPlan = CycleCoordinator.planStartNewCycle(
      existingCycles: existingCycles,
      startDate: startDate,
      basicInfertilePatternCodes: bipCodes,
    );
    _applyCycleMutationPlan(chartId, mutationPlan);
  }

  @override
  Future<void> updateCycleStartDate(
    String cycleId,
    DateTime newStartDate,
  ) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final existingCycles = (_cycles[chartId] ?? {}).values
        .map((data) => Cycle.fromMap(data))
        .toList();

    final mutationPlan = CycleCoordinator.planUpdateCycleStartDate(
      existingCycles: existingCycles,
      cycleIdentifier: cycleId,
      newStartDate: newStartDate,
    );
    if (mutationPlan.cyclesToUpsert.isEmpty &&
        mutationPlan.cycleIdentifiersToDelete.isEmpty) {
      return;
    }

    _applyCycleMutationPlan(chartId, mutationPlan);
  }

  @override
  Future<void> mergeCycleWithPrevious(String cycleId) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final existingCycles = (_cycles[chartId] ?? {}).values
        .map((data) => Cycle.fromMap(data))
        .toList();

    final mutationPlan = CycleCoordinator.planMergeCycleWithPrevious(
      existingCycles: existingCycles,
      cycleIdentifier: cycleId,
    );
    if (mutationPlan.cyclesToUpsert.isEmpty &&
        mutationPlan.cycleIdentifiersToDelete.isEmpty) {
      return;
    }

    _applyCycleMutationPlan(chartId, mutationPlan);
  }

  @override
  Future<void> deleteCycle(String cycleId) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final existingCycles = (_cycles[chartId] ?? {}).values
        .map((data) => Cycle.fromMap(data))
        .toList();

    final mutationPlan = CycleCoordinator.planDeleteCycle(
      existingCycles: existingCycles,
      cycleIdentifier: cycleId,
    );
    _applyCycleMutationPlan(chartId, mutationPlan);
  }

  @override
  Future<void> updateBipCodes(String cycleId, List<String> bipCodes) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final cycleData = _cycles[chartId]?[cycleId];
    if (cycleData == null) return;

    final cycle = Cycle.fromMap(cycleData);
    final updatedCycle =
        CycleCoordinator.recalculateCycleWithBasicInfertilePattern(
          targetCycle: cycle,
          basicInfertilePatternCodes: bipCodes,
        );

    _cycles[chartId]![cycleId] = updatedCycle.toMap();
    _emitCycles();
  }

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
    final chartId = _chartId;
    final user = _currentUser;
    if (chartId == null || user == null) return;

    _cycles[chartId] ??= {};
    final chartCyclesData = _cycles[chartId]!;
    final cycles = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
    cycles.sort((a, b) => a.startDate.compareTo(b.startDate));

    final isHeavyOrModerate =
        bleeding == Bleeding.heavy || bleeding == Bleeding.moderate;

    if (cycles.isEmpty) {
      final dateStr = date.dateKey;
      final newCycle = Cycle(
        id: dateStr,
        startDate: date,
        bipCodes: const ['6C'],
        dailyEntries: const {},
      );
      _cycles[chartId]![dateStr] = newCycle.toMap();
      cycles.add(newCycle);
    } else {
      final eligible = cycles
          .where((c) => c.startDate.compareTo(date) <= 0)
          .toList();
      if (eligible.isEmpty) {
        // Observation date is before all existing cycles — create a new cycle
        // starting on this date so the observation is not attached to a future
        // cycle (which would produce a negative day index).
        final earliestBips = cycles.first.bipCodes;
        await startNewCycle(
          date,
          earliestBips.isNotEmpty
              ? List<String>.from(earliestBips)
              : const <String>['6C'],
        );
      } else if (isHeavyOrModerate) {
        final latest = eligible.last;
        final autoStart = CreightonLogic.evaluateAutoCycleStart(latest, date);
        if (autoStart != null) {
          final dateStr = autoStart.dateKey;
          if (!_cycles[chartId]!.containsKey(dateStr)) {
            await startNewCycle(autoStart, latest.bipCodes);
          }
        }
      }
    }

    final updatedCycles = _cycles[chartId]!.values
        .map((d) => Cycle.fromMap(d))
        .toList();
    updatedCycles.sort((a, b) => a.startDate.compareTo(b.startDate));

    final eligible = updatedCycles
        .where((c) => c.startDate.compareTo(date) <= 0)
        .toList();
    final targetCycle = eligible.isNotEmpty
        ? eligible.last
        : updatedCycles.first;

    final userRoleStr = _users[user.uid]?['role'] as String?;
    final userRole = UserRole.fromString(
      userRoleStr ?? (user.uid == 'husband_uid' ? 'husband' : 'wife'),
    );

    final createdObservation = Observation(
      id: CycleCoordinator.generateObservationIdentifier(),
      timestamp: date,
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
      userId: user.uid,
      userRole: userRole.code,
      isVdrsExplicit: isVdrsExplicit,
    );

    final saveResult = CycleCoordinator.applyObservationToCycle(
      targetCycle: targetCycle,
      observation: createdObservation,
    );

    _cycles[chartId]![targetCycle.id] = saveResult.updatedCycle.toMap();
    _emitCycles();

    final preferences = DatabaseHelpers.parseChartNotificationPreferences(
      _charts[chartId],
    );

    await DatabaseHelpers.dispatchLocalObservationNotifications(
      resolvedDaily: saveResult.resolvedDailyEntry,
      bipCodes: saveResult.updatedCycle.bipCodes,
      userRole: userRole,
      preferences: preferences,
    );
  }

  @override
  Future<void> deleteObservation({
    required String cycleId,
    required DateTime date,
    required String observationId,
  }) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final cycleData = _cycles[chartId]?[cycleId];
    if (cycleData == null) return;

    final cycle = Cycle.fromMap(cycleData);
    final updatedCycle = CycleCoordinator.removeObservationFromCycle(
      targetCycle: cycle,
      date: date,
      observationIdentifier: observationId,
    );
    if (updatedCycle == null) return;

    _cycles[chartId]![cycleId] = updatedCycle.toMap();
    _emitCycles();
  }
}
