part of '../in_memory_database_service.dart';

mixin _InMemorySeedData on _InMemoryDatabaseServiceBase {
  void _prepopulateMockData(String cycleId, DateTime start) {
    // Days 1-5: Menstruation
    for (int d = 0; d < 5; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.heavy,
        'R',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        'Period start',
      );
    }
    // Days 6-10: Dry days
    for (int d = 5; d < 10; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        '',
      );
    }
    // Days 11-13: BIP / Yellow stamp mucus (constant cloudy sticky mucus)
    for (int d = 10; d < 13; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.damp,
        Stretch.sticky,
        [MucusColor.cloudy],
        [],
        0,
        [],
        'Continuous BIP mucus',
      );
    }
    // Days 14-17: Build up (White baby stamps, stretching, lubricative)
    _addMockObs(
      cycleId,
      start.add(const Duration(days: 13)),
      Bleeding.none,
      '',
      Sensation.damp,
      Stretch.tacky,
      [MucusColor.cloudy],
      [],
      2,
      ['Ovulation pain'],
      'Crampy feeling',
    );
    _addMockObs(
      cycleId,
      start.add(const Duration(days: 14)),
      Bleeding.none,
      '',
      Sensation.shiny,
      Stretch.stretchy,
      [MucusColor.clear],
      [],
      0,
      [],
      'Stretching 1 inch',
    );
    _addMockObs(
      cycleId,
      start.add(const Duration(days: 15)),
      Bleeding.none,
      '',
      Sensation.wet,
      Stretch.stretchy,
      [MucusColor.clear],
      [Consistency.lubricative],
      0,
      [],
      'Very lubricative',
    ); // Peak Day
    // Days 18-20: Post-peak dry (Green baby stamps)
    for (int d = 16; d < 19; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        '',
      );
    }
    // Days 21-28: Dry post-ovulatory (Green stamps)
    for (int d = 19; d < 28; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        '',
      );
    }
  }

  void _addMockObs(
    String cycleId,
    DateTime date,
    Bleeding bleeding,
    String bleedingColor,
    Sensation sensation,
    Stretch stretch,
    List<MucusColor> colors,
    List<Consistency> consistencies,
    double painLevel,
    List<String> painTypes,
    String comment,
  ) {
    final cycleData = _cycles['mock_shared_chart']![cycleId]!;
    final cycle = Cycle.fromMap(cycleData);
    final dateKey = date.dateKey;

    final obs = Observation(
      id: dateKey + DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: date,
      sensation: sensation,
      stretch: stretch,
      colors: colors,
      consistencies: consistencies,
      bleeding: bleeding,
      bleedingColor: bleedingColor,
      painLevel: painLevel,
      painTypes: painTypes,
      comment: comment,
      userId: 'wife_uid',
      userRole: UserRole.wife.code,
    );

    final currentEntries = Map<String, DailyEntry>.from(cycle.dailyEntries);
    final existingEntry = currentEntries[dateKey];
    List<Observation> observations = existingEntry != null
        ? (List<Observation>.from(existingEntry.observations)..add(obs))
        : [obs];

    final resolved = CreightonLogic.resolveDailyEntry(
      date: date,
      observations: observations,
    );
    currentEntries[dateKey] = resolved;

    final updated = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: cycle.bipCodes,
    );

    _cycles['mock_shared_chart']![cycleId] = cycle
        .copyWith(dailyEntries: updated)
        .toMap();
  }
}
