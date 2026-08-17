import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  group('Cycle Calculations and Helper Unit Tests', () {
    test(
      'Cycle.maxDayNumber calculates correct span from entries and endDate',
      () {
        final start = DateTime(2026, 1, 1);
        final emptyCycle = Cycle(
          id: '2026-01-01',
          startDate: start,
          dailyEntries: {},
        );
        expect(emptyCycle.maxDayNumber, 0);

        final cycleWithEntries = Cycle(
          id: '2026-01-01',
          startDate: start,
          dailyEntries: {
            '2026-01-01': DailyEntry(
              date: DateTime(2026, 1, 1),
              resolvedVdrsCode: 'H',
              stampType: StampType.red,
              observations: const [],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
            '2026-01-28': DailyEntry(
              date: DateTime(2026, 1, 28),
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: const [],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );
        expect(cycleWithEntries.maxDayNumber, 28);

        final cycleWithEndDate = cycleWithEntries.copyWith(
          endDate: DateTime(2026, 2, 5), // 36 days from Jan 1
        );
        expect(cycleWithEndDate.maxDayNumber, 36);
      },
    );

    test('Cycle.dayNumberFor returns accurate 1-based day indices', () {
      final cycle = Cycle(
        id: '2026-03-01',
        startDate: DateTime(2026, 3, 1),
        dailyEntries: {},
      );

      expect(cycle.dayNumberFor(DateTime(2026, 3, 1)), 1);
      expect(cycle.dayNumberFor(DateTime(2026, 3, 15)), 15);
      expect(cycle.dayNumberFor(DateTime(2026, 3, 31)), 31);
    });

    test(
      'Cycle day calculations across DST spring-forward and fall-back boundaries',
      () {
        final cycle = Cycle(
          id: '2026-03-01',
          startDate: DateTime(2026, 3, 1),
          dailyEntries: {
            '2026-03-08': DailyEntry(
              date: DateTime(2026, 3, 8),
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: const [],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
            '2026-03-09': DailyEntry(
              date: DateTime(2026, 3, 9),
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: const [],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );

        expect(cycle.dayNumberFor(DateTime(2026, 3, 8)), 8);
        expect(cycle.dayNumberFor(DateTime(2026, 3, 9)), 9);
        expect(cycle.maxDayNumber, 9);
      },
    );

    test(
      'Cycle.calculateMaxDisplayDays calculates max across cycles with minDays',
      () {
        final cycle1 = Cycle(
          id: '2026-01-01',
          startDate: DateTime(2026, 1, 1),
          dailyEntries: {
            '2026-01-20': DailyEntry(
              date: DateTime(2026, 1, 20),
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: const [],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );

        final cycle2 = Cycle(
          id: '2026-02-01',
          startDate: DateTime(2026, 2, 1),
          dailyEntries: {
            '2026-03-15': DailyEntry(
              date: DateTime(2026, 3, 15), // 43 days
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: const [],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );

        // Default minDays is 35
        expect(Cycle.calculateMaxDisplayDays([cycle1]), 35);
        expect(Cycle.calculateMaxDisplayDays([cycle1, cycle2]), 43);
        expect(Cycle.calculateMaxDisplayDays([cycle1], minDays: 25), 25);
      },
    );

    test(
      'CreightonLogic.evaluateAutoCycleStart checks 16+ day threshold and bleeding rollback',
      () {
        final cycleStart = DateTime(2026, 5, 1);
        final cycle = Cycle(
          id: '2026-05-01',
          startDate: cycleStart,
          dailyEntries: {
            '2026-05-20': DailyEntry(
              date: DateTime(2026, 5, 20),
              resolvedVdrsCode: 'VL',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_20',
                  timestamp: DateTime(2026, 5, 20),
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.veryLight,
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
            '2026-05-21': DailyEntry(
              date: DateTime(2026, 5, 21),
              resolvedVdrsCode: 'L',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_21',
                  timestamp: DateTime(2026, 5, 21),
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.light,
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );

        // Less than 16 days -> null
        expect(
          CreightonLogic.evaluateAutoCycleStart(cycle, DateTime(2026, 5, 10)),
          isNull,
        );

        // Day 22 (May 22) has H/M bleeding preceded by May 21 (L) and May 20 (VL)
        // Auto cycle start should roll back to May 20
        final autoStart = CreightonLogic.evaluateAutoCycleStart(
          cycle,
          DateTime(2026, 5, 22),
        );
        expect(autoStart, DateTime(2026, 5, 20));
      },
    );

    test(
      'CreightonLogic.reallocateAndRecalculateCycles partitions and recalculates cycles',
      () {
        final cycle1 = Cycle(
          id: '2026-01-01',
          startDate: DateTime(2026, 1, 1),
          bipCodes: const ['6C'],
          dailyEntries: {
            // Entry belonging to cycle1
            '2026-01-05': DailyEntry(
              date: DateTime(2026, 1, 5),
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: [
                Observation(
                  id: 'obs_1',
                  timestamp: DateTime(2026, 1, 5),
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.none,
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
            // Misallocated entry belonging to cycle2
            '2026-02-05': DailyEntry(
              date: DateTime(2026, 2, 5),
              resolvedVdrsCode: 'H',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_2',
                  timestamp: DateTime(2026, 2, 5),
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.heavy,
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );

        final cycle2 = Cycle(
          id: '2026-02-01',
          startDate: DateTime(2026, 2, 1),
          bipCodes: const ['6C'],
          dailyEntries: {},
        );

        final reallocated = CreightonLogic.reallocateAndRecalculateCycles([
          cycle1,
          cycle2,
        ]);

        expect(reallocated.length, 2);
        expect(reallocated[0].dailyEntries.containsKey('2026-01-05'), isTrue);
        expect(reallocated[0].dailyEntries.containsKey('2026-02-05'), isFalse);
        expect(reallocated[1].dailyEntries.containsKey('2026-02-05'), isTrue);
      },
    );

    test(
      'CreightonLogic.reallocateAndRecalculateCycles handles empty list',
      () {
        final reallocated = CreightonLogic.reallocateAndRecalculateCycles([]);
        expect(reallocated, isEmpty);
      },
    );

    test(
      'CreightonLogic.reallocateAndRecalculateCycles allocates pre-start entries to first cycle and handles boundary dates',
      () {
        DailyEntry makeEntry(DateTime date) {
          return DailyEntry(
            date: date,
            resolvedVdrsCode: '0',
            stampType: StampType.green,
            observations: [
              Observation(
                id: 'obs_${date.toIso8601String()}',
                timestamp: date,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: const [],
                consistencies: const [],
                bleeding: Bleeding.none,
                userId: 'test',
              ),
            ],
            painLevel: 0,
            painTypes: const [],
            comments: '',
          );
        }

        final cycle1 = Cycle(
          id: '2026-02-01',
          startDate: DateTime(2026, 2, 1),
          bipCodes: const ['6C'],
          dailyEntries: {
            '2026-01-15': makeEntry(DateTime(2026, 1, 15)),
            '2026-02-01': makeEntry(DateTime(2026, 2, 1)),
            '2026-03-10': makeEntry(DateTime(2026, 3, 10)),
          },
        );

        final cycle2 = Cycle(
          id: '2026-03-01',
          startDate: DateTime(2026, 3, 1),
          bipCodes: const ['6C'],
          dailyEntries: {
            '2026-03-01': makeEntry(DateTime(2026, 3, 1)),
            '2026-04-05': makeEntry(DateTime(2026, 4, 5)),
          },
        );

        final cycle3 = Cycle(
          id: '2026-04-01',
          startDate: DateTime(2026, 4, 1),
          bipCodes: const ['6C'],
          dailyEntries: {'2026-04-01': makeEntry(DateTime(2026, 4, 1))},
        );

        final reallocated = CreightonLogic.reallocateAndRecalculateCycles([
          cycle3,
          cycle1,
          cycle2,
        ]);

        expect(reallocated.length, 3);
        expect(reallocated[0].startDate, DateTime(2026, 2, 1));
        expect(reallocated[1].startDate, DateTime(2026, 3, 1));
        expect(reallocated[2].startDate, DateTime(2026, 4, 1));

        expect(reallocated[0].dailyEntries.keys.toList()..sort(), [
          '2026-01-15',
          '2026-02-01',
        ]);

        expect(reallocated[1].dailyEntries.keys.toList()..sort(), [
          '2026-03-01',
          '2026-03-10',
        ]);

        expect(reallocated[2].dailyEntries.keys.toList()..sort(), [
          '2026-04-01',
          '2026-04-05',
        ]);
      },
    );
  });
}
