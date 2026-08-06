import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  group('Creighton VDRS Code Generation', () {
    test('Dry observation generates code 0', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 6, 28),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test_user',
        isVdrsExplicit: true,
      );
      expect(obs.vdrsCode, '0');
    });

    test('Stretchy clear mucus generates 10K', () {
      final obs = Observation(
        id: '2',
        timestamp: DateTime(2026, 6, 28),
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test_user',
      );
      expect(obs.vdrsCode, '10K');
    });

    test(
      'Stretchy clear lubricative mucus generates 10WLK (with wet sensation)',
      () {
        final obs = Observation(
          id: '3',
          timestamp: DateTime(2026, 6, 28),
          sensation: Sensation.wet,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.none,
          userId: 'test_user',
        );
        expect(obs.vdrsCode, '10WLK');
      },
    );

    test('Bleeding only generates code like H', () {
      final obs = Observation(
        id: '4',
        timestamp: DateTime(2026, 6, 28),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        userId: 'test_user',
      );
      expect(obs.vdrsCode, 'H');
    });
  });

  group('Creighton Daily Observation Resolution', () {
    test('Resolves multiple observations to the most fertile one', () {
      final dryObs = Observation(
        id: '1',
        timestamp: DateTime(2026, 6, 28, 8, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test_user',
      );

      final stickyCloudyObs = Observation(
        id: '2',
        timestamp: DateTime(2026, 6, 28, 12, 0),
        sensation: Sensation.damp,
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.gummy],
        bleeding: Bleeding.none,
        userId: 'test_user',
      );

      final daily = CreightonLogic.resolveDailyEntry(
        date: DateTime(2026, 6, 28),
        observations: [dryObs, stickyCloudyObs],
      );

      expect(daily.resolvedVdrsCode, '6CG');
    });

    test('Combines bleeding with the most fertile mucus', () {
      final periodObs = Observation(
        id: '1',
        timestamp: DateTime(2026, 6, 28, 8, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        userId: 'test_user',
      );

      final stretchyMucusObs = Observation(
        id: '2',
        timestamp: DateTime(2026, 6, 28, 18, 0),
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test_user',
      );

      final daily = CreightonLogic.resolveDailyEntry(
        date: DateTime(2026, 6, 28),
        observations: [periodObs, stretchyMucusObs],
      );

      expect(daily.resolvedVdrsCode, 'H 10K');
    });
  });

  group('Creighton Peak Detection and Stamp Assignment', () {
    test(
      'Calculates Peak day and applies post-peak Green Baby stamps correctly',
      () {
        final start = DateTime(2026, 6, 1);
        final entries = <DailyEntry>[];

        // Day 1-3: Bleeding (Red)
        for (int i = 0; i < 3; i++) {
          final d = start.add(Duration(days: i));
          final obs = Observation(
            id: 'b_$i',
            timestamp: d,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            userId: 'test',
          );
          entries.add(
            CreightonLogic.resolveDailyEntry(date: d, observations: [obs]),
          );
        }

        // Day 4-8: Dry (Green)
        for (int i = 3; i < 8; i++) {
          final d = start.add(Duration(days: i));
          final obs = Observation(
            id: 'd_$i',
            timestamp: d,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          entries.add(
            CreightonLogic.resolveDailyEntry(date: d, observations: [obs]),
          );
        }

        // Day 9: Mucus Build-up (White Baby - 6C)
        final d9 = start.add(const Duration(days: 8));
        final obs9 = Observation(
          id: 'm_9',
          timestamp: d9,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        entries.add(
          CreightonLogic.resolveDailyEntry(date: d9, observations: [obs9]),
        );

        // Day 10: Peak mucus (10K)
        final d10 = start.add(const Duration(days: 9));
        final obs10 = Observation(
          id: 'm_10',
          timestamp: d10,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        entries.add(
          CreightonLogic.resolveDailyEntry(date: d10, observations: [obs10]),
        );

        // Day 11-14: Dry
        for (int i = 10; i < 15; i++) {
          final d = start.add(Duration(days: i));
          final obs = Observation(
            id: 'd_$i',
            timestamp: d,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          entries.add(
            CreightonLogic.resolveDailyEntry(date: d, observations: [obs]),
          );
        }

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: [],
        );

        final day10Key = start
            .add(const Duration(days: 9))
            .toIso8601String()
            .substring(0, 10);
        final day11Key = start
            .add(const Duration(days: 10))
            .toIso8601String()
            .substring(0, 10);
        final day12Key = start
            .add(const Duration(days: 11))
            .toIso8601String()
            .substring(0, 10);
        final day13Key = start
            .add(const Duration(days: 12))
            .toIso8601String()
            .substring(0, 10);
        final day14Key = start
            .add(const Duration(days: 13))
            .toIso8601String()
            .substring(0, 10);

        // Verify Day 10 is Peak (P)
        expect(recalculated[day10Key]?.peakDayLabel, 'P');
        expect(recalculated[day10Key]?.stampType, StampType.whiteBaby);

        // Verify Day 11 is Peak + 1
        expect(recalculated[day11Key]?.peakDayLabel, '1');
        expect(recalculated[day11Key]?.stampType, StampType.greenBaby);

        // Verify Day 12 is Peak + 2
        expect(recalculated[day12Key]?.peakDayLabel, '2');
        expect(recalculated[day12Key]?.stampType, StampType.greenBaby);

        // Verify Day 13 is Peak + 3
        expect(recalculated[day13Key]?.peakDayLabel, '3');
        expect(recalculated[day13Key]?.stampType, StampType.greenBaby);

        // Verify Day 14 is Dry and Infertile (Plain Green)
        expect(recalculated[day14Key]?.peakDayLabel, isNull);
        expect(recalculated[day14Key]?.stampType, StampType.green);
      },
    );

    test(
      'Applies Yellow stamps for BIP mucus codes outside post-peak window',
      () {
        final start = DateTime(2026, 6, 1);
        final bipObs = Observation(
          id: 'bip_1',
          timestamp: start,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        final entries = <DailyEntry>[
          CreightonLogic.resolveDailyEntry(date: start, observations: [bipObs]),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: ['6C'],
        );

        final dateKey = start.toIso8601String().substring(0, 10);
        expect(recalculated[dateKey]?.stampType, StampType.yellow);
      },
    );

    test('recalculateCycle handles month boundaries cleanly', () {
      final endOfMonth = DateTime(2026, 5, 31);
      final jun1 = DateTime(2026, 6, 1);
      final jun2 = DateTime(2026, 6, 2);
      final jun3 = DateTime(2026, 6, 3);

      final peakObs = Observation(
        id: 'peak',
        timestamp: endOfMonth,
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final dryObs1 = Observation(
        id: 'd1',
        timestamp: jun1,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final dryObs2 = Observation(
        id: 'd2',
        timestamp: jun2,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test',
      );
      final dryObs3 = Observation(
        id: 'd3',
        timestamp: jun3,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        userId: 'test',
      );

      final entries = <DailyEntry>[
        CreightonLogic.resolveDailyEntry(
          date: endOfMonth,
          observations: [peakObs],
        ),
        CreightonLogic.resolveDailyEntry(date: jun1, observations: [dryObs1]),
        CreightonLogic.resolveDailyEntry(date: jun2, observations: [dryObs2]),
        CreightonLogic.resolveDailyEntry(date: jun3, observations: [dryObs3]),
      ];

      final recalculated = CreightonLogic.recalculateCycle(
        entries: entries,
        bipCodes: ['6C'],
      );

      final keyMay31 = endOfMonth.toIso8601String().substring(0, 10);
      final keyJun1 = jun1.toIso8601String().substring(0, 10);
      final keyJun2 = jun2.toIso8601String().substring(0, 10);
      final keyJun3 = jun3.toIso8601String().substring(0, 10);

      expect(recalculated[keyMay31]?.isPeakDay, isTrue);
      expect(recalculated[keyJun1]?.peakDayLabel, '1');
      expect(recalculated[keyJun2]?.peakDayLabel, '2');
      expect(recalculated[keyJun3]?.peakDayLabel, '3');
    });
  });

  group('Issue 51 Fixes: Peak-Type Matching, Stamp Defaults, ISO Date Parsing', () {
    test(
      'Observation.isPeakType and DailyEntry.isPeakType correctly identify peak-type mucus using underlying data structures',
      () {
        final date = DateTime(2026, 8, 5);

        // Light bleeding only (Bleeding.light), no mucus -> not peak-type
        final lightBleedingObs = Observation(
          id: '1',
          timestamp: date,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.light,
          bleedingColor: 'K', // black bleeding color
          comment: 'feeling sluggish with K',
          userId: 'test',
        );
        expect(lightBleedingObs.isPeakType, isFalse);

        final dailyLightBleeding = DailyEntry(
          date: date,
          resolvedVdrsCode: 'L-K',
          stampType: StampType.red,
          observations: [lightBleedingObs],
          painLevel: 0,
          painTypes: [],
          comments: 'feeling sluggish with K',
        );
        expect(dailyLightBleeding.isPeakType, isFalse);
        expect(dailyLightBleeding.hasBleeding, isTrue);

        // Stretchy clear mucus -> peak-type
        final stretchyObs = Observation(
          id: '2',
          timestamp: date,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        expect(stretchyObs.isPeakType, isTrue);

        final dailyStretchy = DailyEntry(
          date: date,
          resolvedVdrsCode: '10K',
          stampType: StampType.whiteBaby,
          observations: [stretchyObs],
          painLevel: 0,
          painTypes: [],
          comments: '',
        );
        expect(dailyStretchy.isPeakType, isTrue);
        expect(dailyStretchy.hasBleeding, isFalse);

        // Lubricative mucus -> peak-type
        final lubricativeObs = Observation(
          id: '3',
          timestamp: date,
          sensation: Sensation.wet,
          stretch: Stretch.tacky,
          colors: [MucusColor.cloudy],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        expect(lubricativeObs.isPeakType, isTrue);
      },
    );

    test(
      'resolveDailyEntry sets appropriate initial StampType prior to cycle recalculation',
      () {
        final date = DateTime(2026, 8, 5);

        final bleedingObs = Observation(
          id: '1',
          timestamp: date,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.heavy,
          userId: 'test',
        );
        final dailyBleeding = CreightonLogic.resolveDailyEntry(
          date: date,
          observations: [bleedingObs],
        );
        expect(dailyBleeding.stampType, StampType.red);

        final mucusObs = Observation(
          id: '2',
          timestamp: date,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        final dailyMucus = CreightonLogic.resolveDailyEntry(
          date: date,
          observations: [mucusObs],
        );
        expect(dailyMucus.stampType, StampType.whiteBaby);

        final dryObs = Observation(
          id: '3',
          timestamp: date,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        final dailyDry = CreightonLogic.resolveDailyEntry(
          date: date,
          observations: [dryObs],
        );
        expect(dailyDry.stampType, StampType.green);
      },
    );

    test(
      'DailyEntry.fromMap and Cycle.fromMap parse ISO timestamps without FormatException',
      () {
        final dailyMap = {
          'date': '2026-08-05T14:30:00.000Z',
          'resolvedVdrsCode': '10K',
          'stampType': 'WhiteBaby',
          'observations': [],
          'painLevel': 0.0,
          'painTypes': [],
          'comments': '',
        };
        final entry = DailyEntry.fromMap(dailyMap);
        expect(entry.date, DateTime(2026, 8, 5));
        expect(entry.resolvedVdrsCode, '10K');

        final cycleMap = {
          'id': 'cycle_1',
          'startDate': '2026-08-01T00:00:00.000Z',
          'endDate': '2026-08-28T23:59:59Z',
          'bipCodes': [],
          'dailyEntries': {'2026-08-05': dailyMap},
        };
        final cycle = Cycle.fromMap(cycleMap);
        expect(cycle.startDate.year, 2026);
        expect(cycle.startDate.month, 8);
        expect(cycle.startDate.day, 1);
        expect(cycle.endDate?.day, 28);
      },
    );
  });
}
