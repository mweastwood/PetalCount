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

    test('Appends bleeding color suffix when bleeding is non-red', () {
      final brownPeriodObs = Observation(
        id: '1',
        timestamp: DateTime(2026, 6, 28, 8, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.light,
        bleedingColor: 'B',
        userId: 'test_user',
      );

      final daily = CreightonLogic.resolveDailyEntry(
        date: DateTime(2026, 6, 28),
        observations: [brownPeriodObs],
      );

      expect(daily.resolvedVdrsCode, 'L-B');
    });

    test(
      'Single observation: spotting with dry sensation resolves to "VL 0"',
      () {
        final spottingObs = Observation(
          id: '1',
          timestamp: DateTime(2026, 6, 28, 8, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.spotting,
          bleedingColor: 'R',
          userId: 'test_user',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: DateTime(2026, 6, 28),
          observations: [spottingObs],
        );

        expect(daily.resolvedVdrsCode, 'VL 0');
      },
    );

    test(
      'Single observation: spotting brown with dry sensation resolves to "VL-B 0"',
      () {
        final spottingBrownObs = Observation(
          id: '1',
          timestamp: DateTime(2026, 6, 28, 8, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.spotting,
          bleedingColor: 'B',
          userId: 'test_user',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: DateTime(2026, 6, 28),
          observations: [spottingBrownObs],
        );

        expect(daily.resolvedVdrsCode, 'VL-B 0');
      },
    );

    test(
      'Multi-observation combination: spotting + dry observation resolves to "VL 0"',
      () {
        final spottingObs = Observation(
          id: '1',
          timestamp: DateTime(2026, 6, 28, 8, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.spotting,
          bleedingColor: 'R',
          userId: 'test_user',
        );

        final dryObs = Observation(
          id: '2',
          timestamp: DateTime(2026, 6, 28, 12, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test_user',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: DateTime(2026, 6, 28),
          observations: [spottingObs, dryObs],
        );

        expect(daily.resolvedVdrsCode, 'VL 0');
      },
    );

    test(
      'Multi-observation combination: spotting + mucus observation resolves to "VL 10K"',
      () {
        final spottingObs = Observation(
          id: '1',
          timestamp: DateTime(2026, 6, 28, 8, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.spotting,
          bleedingColor: 'R',
          userId: 'test_user',
        );

        final mucusObs = Observation(
          id: '2',
          timestamp: DateTime(2026, 6, 28, 14, 0),
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test_user',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: DateTime(2026, 6, 28),
          observations: [spottingObs, mucusObs],
        );

        expect(daily.resolvedVdrsCode, 'VL 10K');
      },
    );

    test(
      'Multi-observation combination: heavy bleeding + spotting with dry sensation correctly prioritizes menstrual flow and resolves to "H"',
      () {
        final heavyObs = Observation(
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

        final spottingObs = Observation(
          id: '2',
          timestamp: DateTime(2026, 6, 28, 14, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.spotting,
          bleedingColor: 'R',
          userId: 'test_user',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: DateTime(2026, 6, 28),
          observations: [heavyObs, spottingObs],
        );

        expect(daily.resolvedVdrsCode, 'H');
      },
    );

    test('Resolves daily entry with frequency and intercourse markers', () {
      final obs1 = Observation(
        id: '1',
        timestamp: DateTime(2026, 6, 28, 8, 0),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.none,
        frequency: Frequency.allDay,
        intercourse: true,
        userId: 'test_user',
      );

      final daily = CreightonLogic.resolveDailyEntry(
        date: DateTime(2026, 6, 28),
        observations: [obs1],
      );

      expect(daily.resolvedVdrsCode, '0 AD I');
      expect(daily.hasIntercourse, isTrue);
    });

    test(
      'Resolves multiple observations combining most fertile mucus, frequency, and intercourse',
      () {
        final dryObs = Observation(
          id: '1',
          timestamp: DateTime(2026, 6, 28, 8, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          frequency: Frequency.none,
          userId: 'test_user',
        );

        final mucusObs = Observation(
          id: '2',
          timestamp: DateTime(2026, 6, 28, 14, 0),
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          frequency: Frequency.twice,
          userId: 'test_user',
        );

        final intercourseObs = Observation(
          id: '3',
          timestamp: DateTime(2026, 6, 28, 22, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          intercourse: true,
          userId: 'test_user',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: DateTime(2026, 6, 28),
          observations: [dryObs, mucusObs, intercourseObs],
        );

        expect(daily.resolvedVdrsCode, '10K x2 I');
        expect(daily.hasIntercourse, isTrue);
      },
    );

    test(
      'Resolves lubricative sensation without stretch to 10WL and WhiteBaby stamp',
      () {
        final dryObs = Observation(
          id: '1',
          timestamp: DateTime(2026, 6, 28, 8, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test_user',
        );

        final lubricativeObs = Observation(
          id: '2',
          timestamp: DateTime(2026, 6, 28, 14, 0),
          sensation: Sensation.wet,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [Consistency.lubricative],
          bleeding: Bleeding.none,
          userId: 'test_user',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: DateTime(2026, 6, 28),
          observations: [dryObs, lubricativeObs],
        );

        expect(daily.resolvedVdrsCode, '10WL');
        expect(daily.stampType, StampType.whiteBaby);
        expect(daily.isPeakType, isTrue);
        expect(daily.hasMucus, isTrue);
      },
    );
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

        final day10Key = start.add(const Duration(days: 9)).dateKey;
        final day11Key = start.add(const Duration(days: 10)).dateKey;
        final day12Key = start.add(const Duration(days: 11)).dateKey;
        final day13Key = start.add(const Duration(days: 12)).dateKey;
        final day14Key = start.add(const Duration(days: 13)).dateKey;

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
      'Calculates Peak day when peak-type mucus is based on lubricative sensation without stretch',
      () {
        final start = DateTime(2026, 6, 1);
        final entries = <DailyEntry>[];

        // Day 1-8: Dry (Green)
        for (int i = 0; i < 8; i++) {
          final d = start.add(Duration(days: i));
          final obs = Observation(
            id: 'd_$i',
            timestamp: d,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: const [],
            consistencies: const [],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          entries.add(
            CreightonLogic.resolveDailyEntry(date: d, observations: [obs]),
          );
        }

        // Day 9: Sticky cloudy mucus (6C)
        final d9 = start.add(const Duration(days: 8));
        final obs9 = Observation(
          id: 'm_9',
          timestamp: d9,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: const [MucusColor.cloudy],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );
        entries.add(
          CreightonLogic.resolveDailyEntry(date: d9, observations: [obs9]),
        );

        // Day 10: Pure Lubricative sensation without stretch (10WL)
        final d10 = start.add(const Duration(days: 9));
        final obs10 = Observation(
          id: 'm_10',
          timestamp: d10,
          sensation: Sensation.wet,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [Consistency.lubricative],
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
            colors: const [],
            consistencies: const [],
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

        final day10Key = start.add(const Duration(days: 9)).dateKey;
        final day11Key = start.add(const Duration(days: 10)).dateKey;
        final day12Key = start.add(const Duration(days: 11)).dateKey;
        final day13Key = start.add(const Duration(days: 12)).dateKey;
        final day14Key = start.add(const Duration(days: 13)).dateKey;

        // Verify Day 10 is Peak (P) with WhiteBaby stamp
        expect(recalculated[day10Key]?.peakDayLabel, 'P');
        expect(recalculated[day10Key]?.stampType, StampType.whiteBaby);
        expect(recalculated[day10Key]?.resolvedVdrsCode, '10WL');

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

        final dateKey = start.dateKey;
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

      final keyMay31 = endOfMonth.dateKey;
      final keyJun1 = jun1.dateKey;
      final keyJun2 = jun2.dateKey;
      final keyJun3 = jun3.dateKey;

      expect(recalculated[keyMay31]?.isPeakDay, isTrue);
      expect(recalculated[keyJun1]?.peakDayLabel, '1');
      expect(recalculated[keyJun2]?.peakDayLabel, '2');
      expect(recalculated[keyJun3]?.peakDayLabel, '3');
    });

    test(
      'recalculateCycle assigns Peak labels using calendar days since Peak when days are unlogged/skipped',
      () {
        final jun15 = DateTime(2026, 6, 15);
        // jun16 is unlogged / missing
        final jun17 = DateTime(2026, 6, 17);
        final jun18 = DateTime(2026, 6, 18);
        final jun19 = DateTime(2026, 6, 19);

        final peakObs = Observation(
          id: 'peak_15',
          timestamp: jun15,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final dryObs17 = Observation(
          id: 'dry_17',
          timestamp: jun17,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final dryObs18 = Observation(
          id: 'dry_18',
          timestamp: jun18,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final dryObs19 = Observation(
          id: 'dry_19',
          timestamp: jun19,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = <DailyEntry>[
          CreightonLogic.resolveDailyEntry(
            date: jun15,
            observations: [peakObs],
          ),
          CreightonLogic.resolveDailyEntry(
            date: jun17,
            observations: [dryObs17],
          ),
          CreightonLogic.resolveDailyEntry(
            date: jun18,
            observations: [dryObs18],
          ),
          CreightonLogic.resolveDailyEntry(
            date: jun19,
            observations: [dryObs19],
          ),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: [],
        );

        final keyJun15 = jun15.dateKey;
        final keyJun17 = jun17.dateKey;
        final keyJun18 = jun18.dateKey;
        final keyJun19 = jun19.dateKey;

        // Day P (June 15)
        expect(recalculated[keyJun15]?.peakDayLabel, 'P');
        expect(recalculated[keyJun15]?.stampType, StampType.whiteBaby);

        // Day P+2 (June 17, missing June 16) -> labeled '2', greenBaby
        expect(recalculated[keyJun17]?.peakDayLabel, '2');
        expect(recalculated[keyJun17]?.stampType, StampType.greenBaby);

        // Day P+3 (June 18) -> labeled '3', greenBaby
        expect(recalculated[keyJun18]?.peakDayLabel, '3');
        expect(recalculated[keyJun18]?.stampType, StampType.greenBaby);

        // Day P+4 (June 19) -> labeled null (post-fertile window), green
        expect(recalculated[keyJun19]?.peakDayLabel, isNull);
        expect(recalculated[keyJun19]?.stampType, StampType.green);
      },
    );

    test(
      'recalculateCycle handles post-peak BIP mucus accurately based on calendar days since Peak',
      () {
        final jun15 = DateTime(2026, 6, 15);
        // jun16 is unlogged / missing
        final jun17 = DateTime(2026, 6, 17);
        final jun18 = DateTime(2026, 6, 18);
        final jun19 = DateTime(2026, 6, 19);

        final peakObs = Observation(
          id: 'peak_15',
          timestamp: jun15,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final bipObs17 = Observation(
          id: 'bip_17',
          timestamp: jun17,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final bipObs18 = Observation(
          id: 'bip_18',
          timestamp: jun18,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final bipObs19 = Observation(
          id: 'bip_19',
          timestamp: jun19,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = <DailyEntry>[
          CreightonLogic.resolveDailyEntry(
            date: jun15,
            observations: [peakObs],
          ),
          CreightonLogic.resolveDailyEntry(
            date: jun17,
            observations: [bipObs17],
          ),
          CreightonLogic.resolveDailyEntry(
            date: jun18,
            observations: [bipObs18],
          ),
          CreightonLogic.resolveDailyEntry(
            date: jun19,
            observations: [bipObs19],
          ),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: ['6C'],
        );

        final keyJun15 = jun15.dateKey;
        final keyJun17 = jun17.dateKey;
        final keyJun18 = jun18.dateKey;
        final keyJun19 = jun19.dateKey;

        // Day P (June 15)
        expect(recalculated[keyJun15]?.peakDayLabel, 'P');
        expect(recalculated[keyJun15]?.stampType, StampType.whiteBaby);

        // Day P+2 (June 17, missing June 16) -> labeled '2', whiteBaby (fertile window override of BIP)
        expect(recalculated[keyJun17]?.peakDayLabel, '2');
        expect(recalculated[keyJun17]?.stampType, StampType.whiteBaby);

        // Day P+3 (June 18) -> labeled '3', whiteBaby (fertile window override of BIP)
        expect(recalculated[keyJun18]?.peakDayLabel, '3');
        expect(recalculated[keyJun18]?.stampType, StampType.whiteBaby);

        // Day P+4 (June 19) -> labeled null, yellow (BIP protocol applies outside post-peak window)
        expect(recalculated[keyJun19]?.peakDayLabel, isNull);
        expect(recalculated[keyJun19]?.stampType, StampType.yellow);
      },
    );
  });

  group(
    'Issue 51 Fixes: Peak-Type Matching, Stamp Defaults, ISO Date Parsing',
    () {
      test('Observation.isPeakType and DailyEntry.isPeakType correctly identify'
          ' peak-type mucus using underlying data structures', () {
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
      });

      test('resolveDailyEntry sets appropriate initial StampType prior to cycle'
          ' recalculation', () {
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
      });

      test('DailyEntry.fromMap and Cycle.fromMap parse ISO timestamps without'
          ' FormatException', () {
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
      });

      test(
        'DailyEntry getters evaluate properties strictly from structured observations',
        () {
          final date = DateTime(2026, 8, 5);

          final bleedingObs = Observation(
            id: '1',
            timestamp: date,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: const [],
            consistencies: const [],
            bleeding: Bleeding.heavy,
            userId: 'test',
          );
          final entryBleeding = DailyEntry(
            date: date,
            resolvedVdrsCode: 'H',
            stampType: StampType.red,
            observations: [bleedingObs],
            painLevel: 0,
            painTypes: const [],
            comments: '',
          );
          expect(entryBleeding.hasBleeding, isTrue);
          expect(entryBleeding.hasMucus, isFalse);
          expect(entryBleeding.isPeakType, isFalse);

          final nonPeakMucusObs = Observation(
            id: '2',
            timestamp: date,
            sensation: Sensation.damp,
            stretch: Stretch.sticky,
            colors: const [MucusColor.cloudy],
            consistencies: const [],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          final entryNonPeakMucus = DailyEntry(
            date: date,
            resolvedVdrsCode: '6C',
            stampType: StampType.whiteBaby,
            observations: [nonPeakMucusObs],
            painLevel: 0,
            painTypes: const [],
            comments: '',
          );
          expect(entryNonPeakMucus.hasBleeding, isFalse);
          expect(entryNonPeakMucus.hasMucus, isTrue);
          expect(entryNonPeakMucus.isPeakType, isFalse);

          final peakMucusObs = Observation(
            id: '3',
            timestamp: date,
            sensation: Sensation.wet,
            stretch: Stretch.stretchy,
            colors: const [MucusColor.clear],
            consistencies: const [Consistency.lubricative],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          final entryPeakMucus = DailyEntry(
            date: date,
            resolvedVdrsCode: '10WLK',
            stampType: StampType.whiteBaby,
            observations: [peakMucusObs],
            painLevel: 0,
            painTypes: const [],
            comments: '',
          );
          expect(entryPeakMucus.hasBleeding, isFalse);
          expect(entryPeakMucus.hasMucus, isTrue);
          expect(entryPeakMucus.isPeakType, isTrue);

          final pureLubricativeObs = Observation(
            id: '3b',
            timestamp: date,
            sensation: Sensation.wet,
            stretch: Stretch.none,
            colors: const [],
            consistencies: const [Consistency.lubricative],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          final entryPureLubricative = DailyEntry(
            date: date,
            resolvedVdrsCode: '10WL',
            stampType: StampType.whiteBaby,
            observations: [pureLubricativeObs],
            painLevel: 0,
            painTypes: const [],
            comments: '',
          );
          expect(entryPureLubricative.hasBleeding, isFalse);
          expect(entryPureLubricative.hasMucus, isTrue);
          expect(entryPureLubricative.isPeakType, isTrue);

          final compositeObs1 = Observation(
            id: '4a',
            timestamp: date,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: const [],
            consistencies: const [],
            bleeding: Bleeding.light,
            userId: 'test',
          );
          final compositeObs2 = Observation(
            id: '4b',
            timestamp: date,
            sensation: Sensation.wet,
            stretch: Stretch.stretchy,
            colors: const [MucusColor.clear],
            consistencies: const [Consistency.lubricative],
            bleeding: Bleeding.none,
            userId: 'test',
          );
          final entryComposite = DailyEntry(
            date: date,
            resolvedVdrsCode: 'L 10WLK',
            stampType: StampType.red,
            observations: [compositeObs1, compositeObs2],
            painLevel: 0,
            painTypes: const [],
            comments: '',
          );
          expect(entryComposite.hasBleeding, isTrue);
          expect(entryComposite.hasMucus, isTrue);
          expect(entryComposite.isPeakType, isTrue);

          final entryEmpty = DailyEntry(
            date: date,
            resolvedVdrsCode: '',
            stampType: StampType.green,
            observations: const [],
            painLevel: 0,
            painTypes: const [],
            comments: '',
          );
          expect(entryEmpty.hasBleeding, isFalse);
          expect(entryEmpty.hasMucus, isFalse);
          expect(entryEmpty.isPeakType, isFalse);
        },
      );

      test('parseIsoDate correctly handles various ISO date formats', () {
        final dateOnly = parseIsoDate('2026-08-05');
        expect(dateOnly.year, 2026);
        expect(dateOnly.month, 8);
        expect(dateOnly.day, 5);

        final isoWithTime = parseIsoDate('2026-08-05T14:30:00.000Z');
        expect(isoWithTime.year, 2026);
        expect(isoWithTime.month, 8);
        expect(isoWithTime.day, 5);

        final invalidDate = parseIsoDate('completely-invalid-date');
        expect(invalidDate, DateTime(1970, 1, 1));
      });
    },
  );

  group('Daylight Saving Time (DST) & Calendar Day Transition Tests', () {
    test(
      'evaluateAutoCycleStart triggers correctly on exactly the 16-day threshold across DST spring-forward',
      () {
        // Cycle starts March 1, 2026. March 8 is DST spring forward (23h).
        // Day 17 is March 17 (16 calendar days difference from March 1).
        final cycleStart = DateTime(2026, 3, 1);
        final cycle = Cycle(
          id: '2026-03-01',
          startDate: cycleStart,
          dailyEntries: const {},
        );

        // Day 16 (March 16, 15 days diff) -> null
        expect(
          CreightonLogic.evaluateAutoCycleStart(cycle, DateTime(2026, 3, 16)),
          isNull,
        );

        // Day 17 (March 17, 16 days diff) -> returns March 17 as new cycle start
        final autoStart = CreightonLogic.evaluateAutoCycleStart(
          cycle,
          DateTime(2026, 3, 17),
        );
        expect(autoStart, DateTime(2026, 3, 17));
      },
    );

    test(
      'evaluateAutoCycleStart rolls back across DST transition boundary accurately',
      () {
        // If cycle started Feb 20, 2026, Day 17 is March 9 (across DST on March 8).
        // Bleeding on March 8 (Day 17 - 16 days diff from Feb 20) and March 9 (Day 18 - 17 days diff).
        final febCycle = Cycle(
          id: '2026-02-20',
          startDate: DateTime(2026, 2, 20),
          dailyEntries: {
            '2026-03-08': DailyEntry(
              date: DateTime(2026, 3, 8),
              resolvedVdrsCode: 'L',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_mar8',
                  timestamp: DateTime(2026, 3, 8),
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
        final febAutoStart = CreightonLogic.evaluateAutoCycleStart(
          febCycle,
          DateTime(2026, 3, 9),
        );
        expect(febAutoStart, DateTime(2026, 3, 8));
      },
    );
  });

  group('Creighton Bleeding Intensity Resolution & Menstrual Flow Auto-Start', () {
    test(
      'resolveDailyEntry selects heaviest bleeding flow when Light appears before Moderate (M 2W scenario)',
      () {
        final date = DateTime(2026, 8, 26);
        final obs1 = Observation(
          id: 'obs1',
          timestamp: DateTime(2026, 8, 26, 9, 15),
          sensation: Sensation.wet,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.light,
          bleedingColor: 'R',
          userId: 'test',
        );

        final obs2 = Observation(
          id: 'obs2',
          timestamp: DateTime(2026, 8, 26, 22, 13),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.moderate,
          bleedingColor: 'R',
          userId: 'test',
        );

        final daily = CreightonLogic.resolveDailyEntry(
          date: date,
          observations: [obs1, obs2],
        );

        // Takes Moderate bleeding (heavier than Light) + Wet sensation (more fertile than dry)
        expect(daily.resolvedVdrsCode, 'M 2W');
        expect(daily.stampType, StampType.red);
      },
    );

    test(
      'resolveDailyEntry selects heaviest bleeding regardless of observation insertion order',
      () {
        final date = DateTime(2026, 8, 26);
        final heavyObs = Observation(
          id: 'h',
          timestamp: DateTime(2026, 8, 26, 8, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.heavy,
          bleedingColor: 'R',
          userId: 'test',
        );

        final veryLightObs = Observation(
          id: 'vl',
          timestamp: DateTime(2026, 8, 26, 12, 0),
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.veryLight,
          bleedingColor: 'B',
          userId: 'test',
        );

        final daily1 = CreightonLogic.resolveDailyEntry(
          date: date,
          observations: [veryLightObs, heavyObs],
        );
        expect(daily1.resolvedVdrsCode, 'H');

        final daily2 = CreightonLogic.resolveDailyEntry(
          date: date,
          observations: [heavyObs, veryLightObs],
        );
        expect(daily2.resolvedVdrsCode, 'H');
      },
    );

    test(
      'evaluateAutoCycleStart does NOT roll back over pre-menstrual spotting (VL) days',
      () {
        final cycleStart = DateTime(2026, 7, 23);
        final cycle = Cycle(
          id: '2026-07-23',
          startDate: cycleStart,
          dailyEntries: {
            '2026-08-23': DailyEntry(
              date: DateTime(2026, 8, 23),
              resolvedVdrsCode: 'VL-B 6CP',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_23',
                  timestamp: DateTime(2026, 8, 23),
                  sensation: Sensation.damp,
                  stretch: Stretch.sticky,
                  colors: const [MucusColor.cloudy],
                  consistencies: const [Consistency.pasty],
                  bleeding: Bleeding.veryLight,
                  bleedingColor: 'B',
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
            '2026-08-24': DailyEntry(
              date: DateTime(2026, 8, 24),
              resolvedVdrsCode: 'VL-B 0',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_24',
                  timestamp: DateTime(2026, 8, 24),
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.veryLight,
                  bleedingColor: 'B',
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
            '2026-08-25': DailyEntry(
              date: DateTime(2026, 8, 25),
              resolvedVdrsCode: 'VL-B 10B',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_25',
                  timestamp: DateTime(2026, 8, 25),
                  sensation: Sensation.damp,
                  stretch: Stretch.stretchy,
                  colors: const [MucusColor.brown],
                  consistencies: const [],
                  bleeding: Bleeding.veryLight,
                  bleedingColor: 'B',
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );

        // When moderate menses arrives on Aug 26 (Day 35 of cycle):
        final autoStart = CreightonLogic.evaluateAutoCycleStart(
          cycle,
          DateTime(2026, 8, 26),
        );

        // Should start on Aug 26 (NOT roll back to Aug 23 VL-B)
        expect(autoStart, DateTime(2026, 8, 26));
      },
    );

    test(
      'evaluateAutoCycleStart rolls back over true flow (L) but stops before pre-menstrual spotting (VL)',
      () {
        final cycleStart = DateTime(2026, 7, 23);
        final cycle = Cycle(
          id: '2026-07-23',
          startDate: cycleStart,
          dailyEntries: {
            '2026-08-24': DailyEntry(
              date: DateTime(2026, 8, 24),
              resolvedVdrsCode: 'VL-B 0',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_24',
                  timestamp: DateTime(2026, 8, 24),
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.veryLight,
                  bleedingColor: 'B',
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
            '2026-08-25': DailyEntry(
              date: DateTime(2026, 8, 25),
              resolvedVdrsCode: 'L',
              stampType: StampType.red,
              observations: [
                Observation(
                  id: 'obs_25',
                  timestamp: DateTime(2026, 8, 25),
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.light,
                  bleedingColor: 'R',
                  userId: 'test',
                ),
              ],
              painLevel: 0,
              painTypes: const [],
              comments: '',
            ),
          },
        );

        // When moderate/heavy menses arrives on Aug 26:
        final autoStart = CreightonLogic.evaluateAutoCycleStart(
          cycle,
          DateTime(2026, 8, 26),
        );

        // Should roll back to Aug 25 (first Light flow day), but stop before Aug 24 (VL spotting)
        expect(autoStart, DateTime(2026, 8, 25));
      },
    );
  });

  group('Provisional Peak Detection and Post-Peak Count (Count >= 1)', () {
    test(
      'infers candidate Peak day on first day of dry shift (Peak + 1) with greenBaby stamp',
      () {
        final day10 = DateTime(2026, 9, 10);
        final day11 = DateTime(2026, 9, 11);

        final peakObs = Observation(
          id: 'peak_10',
          timestamp: day10,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final dryObs = Observation(
          id: 'dry_11',
          timestamp: day11,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = [
          CreightonLogic.resolveDailyEntry(
            date: day10,
            observations: [peakObs],
          ),
          CreightonLogic.resolveDailyEntry(date: day11, observations: [dryObs]),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: const [],
        );

        // Day 10 is inferred as Peak (P)
        expect(recalculated[day10.dateKey]?.peakDayLabel, 'P');
        expect(recalculated[day10.dateKey]?.isPeakDay, isTrue);
        expect(recalculated[day10.dateKey]?.stampType, StampType.whiteBaby);

        // Day 11 is labeled '1' with greenBaby stamp (fertile dry day in post-peak window)
        expect(recalculated[day11.dateKey]?.peakDayLabel, '1');
        expect(recalculated[day11.dateKey]?.stampType, StampType.greenBaby);
      },
    );

    test('infers candidate Peak day on day 2 of dry shift (Peak + 2)', () {
      final day10 = DateTime(2026, 9, 10);
      final day11 = DateTime(2026, 9, 11);
      final day12 = DateTime(2026, 9, 12);

      final peakObs = Observation(
        id: 'peak_10',
        timestamp: day10,
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: const [MucusColor.clear],
        consistencies: const [],
        bleeding: Bleeding.none,
        userId: 'test',
      );

      final dryObs1 = Observation(
        id: 'dry_11',
        timestamp: day11,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.none,
        userId: 'test',
      );

      final dryObs2 = Observation(
        id: 'dry_12',
        timestamp: day12,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.none,
        userId: 'test',
      );

      final entries = [
        CreightonLogic.resolveDailyEntry(date: day10, observations: [peakObs]),
        CreightonLogic.resolveDailyEntry(date: day11, observations: [dryObs1]),
        CreightonLogic.resolveDailyEntry(date: day12, observations: [dryObs2]),
      ];

      final recalculated = CreightonLogic.recalculateCycle(
        entries: entries,
        bipCodes: const [],
      );

      expect(recalculated[day10.dateKey]?.peakDayLabel, 'P');
      expect(recalculated[day11.dateKey]?.peakDayLabel, '1');
      expect(recalculated[day11.dateKey]?.stampType, StampType.greenBaby);
      expect(recalculated[day12.dateKey]?.peakDayLabel, '2');
      expect(recalculated[day12.dateKey]?.stampType, StampType.greenBaby);
    });

    test(
      'infers candidate Peak day when shift is non-peak mucus (e.g. 6C) on Day 1 with whiteBaby stamp',
      () {
        final day10 = DateTime(2026, 9, 10);
        final day11 = DateTime(2026, 9, 11);

        final peakObs = Observation(
          id: 'peak_10',
          timestamp: day10,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final nonPeakMucusObs = Observation(
          id: 'sticky_11',
          timestamp: day11,
          sensation: Sensation.damp,
          stretch: Stretch.sticky,
          colors: const [MucusColor.cloudy],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = [
          CreightonLogic.resolveDailyEntry(
            date: day10,
            observations: [peakObs],
          ),
          CreightonLogic.resolveDailyEntry(
            date: day11,
            observations: [nonPeakMucusObs],
          ),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: const ['6C'],
        );

        expect(recalculated[day10.dateKey]?.peakDayLabel, 'P');
        expect(recalculated[day11.dateKey]?.peakDayLabel, '1');
        // In post-peak fertile window, even BIP mucus receives whiteBaby stamp
        expect(recalculated[day11.dateKey]?.stampType, StampType.whiteBaby);
      },
    );

    test(
      'does not infer Peak day prematurely on the day of peak mucus itself (count == 0)',
      () {
        final day10 = DateTime(2026, 9, 10);

        final peakObs = Observation(
          id: 'peak_10',
          timestamp: day10,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = [
          CreightonLogic.resolveDailyEntry(
            date: day10,
            observations: [peakObs],
          ),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: const [],
        );

        // Peak cannot be inferred on the peak mucus day itself without an abrupt shift
        expect(recalculated[day10.dateKey]?.peakDayLabel, isNull);
        expect(recalculated[day10.dateKey]?.isPeakDay, isFalse);
        expect(recalculated[day10.dateKey]?.stampType, StampType.whiteBaby);
      },
    );

    test(
      'disrupts and resets provisional peak count if peak-type mucus returns during count',
      () {
        final day10 = DateTime(2026, 9, 10);
        final day11 = DateTime(2026, 9, 11);
        final day12 = DateTime(2026, 9, 12);

        final peakObs1 = Observation(
          id: 'peak_10',
          timestamp: day10,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final dryObs = Observation(
          id: 'dry_11',
          timestamp: day11,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        // Mucus returns on day 12 (disrupted count)
        final peakObs2 = Observation(
          id: 'peak_12',
          timestamp: day12,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = [
          CreightonLogic.resolveDailyEntry(
            date: day10,
            observations: [peakObs1],
          ),
          CreightonLogic.resolveDailyEntry(date: day11, observations: [dryObs]),
          CreightonLogic.resolveDailyEntry(
            date: day12,
            observations: [peakObs2],
          ),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: const [],
        );

        // Day 10 is no longer Peak because day 12 is peak-type mucus
        expect(recalculated[day10.dateKey]?.peakDayLabel, isNull);
        expect(recalculated[day10.dateKey]?.isPeakDay, isFalse);

        // Day 11 is no longer '1'
        expect(recalculated[day11.dateKey]?.peakDayLabel, isNull);
        expect(recalculated[day11.dateKey]?.stampType, StampType.green);

        // Day 12 has not yet had a shift, so it is not yet labeled Peak
        expect(recalculated[day12.dateKey]?.peakDayLabel, isNull);
        expect(recalculated[day12.dateKey]?.stampType, StampType.whiteBaby);
      },
    );

    test(
      'establishes new candidate Peak day after disrupted peak when subsequent dry shift occurs',
      () {
        final day10 = DateTime(2026, 9, 10);
        final day11 = DateTime(2026, 9, 11);
        final day12 = DateTime(2026, 9, 12);
        final day13 = DateTime(2026, 9, 13);

        final peakObs1 = Observation(
          id: 'peak_10',
          timestamp: day10,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final dryObs1 = Observation(
          id: 'dry_11',
          timestamp: day11,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final peakObs2 = Observation(
          id: 'peak_12',
          timestamp: day12,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final dryObs2 = Observation(
          id: 'dry_13',
          timestamp: day13,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = [
          CreightonLogic.resolveDailyEntry(
            date: day10,
            observations: [peakObs1],
          ),
          CreightonLogic.resolveDailyEntry(
            date: day11,
            observations: [dryObs1],
          ),
          CreightonLogic.resolveDailyEntry(
            date: day12,
            observations: [peakObs2],
          ),
          CreightonLogic.resolveDailyEntry(
            date: day13,
            observations: [dryObs2],
          ),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: const [],
        );

        // Day 10 is not Peak
        expect(recalculated[day10.dateKey]?.peakDayLabel, isNull);
        // Day 12 is the new candidate Peak
        expect(recalculated[day12.dateKey]?.peakDayLabel, 'P');
        expect(recalculated[day12.dateKey]?.isPeakDay, isTrue);
        // Day 13 is Peak + 1
        expect(recalculated[day13.dateKey]?.peakDayLabel, '1');
        expect(recalculated[day13.dateKey]?.stampType, StampType.greenBaby);
      },
    );

    test(
      'identifies the latest peak day when multiple peak mucus patches occur in a cycle',
      () {
        final start = DateTime(2026, 6, 1);
        final entries = <DailyEntry>[];

        // Patch 1: Day 5 peak, Days 6-8 dry
        final d5 = start.add(const Duration(days: 4));
        entries.add(
          CreightonLogic.resolveDailyEntry(
            date: d5,
            observations: [
              Observation(
                id: 'p_5',
                timestamp: d5,
                sensation: Sensation.damp,
                stretch: Stretch.stretchy,
                colors: const [MucusColor.clear],
                consistencies: const [],
                bleeding: Bleeding.none,
                userId: 'test',
              ),
            ],
          ),
        );
        for (int i = 5; i < 8; i++) {
          final d = start.add(Duration(days: i));
          entries.add(
            CreightonLogic.resolveDailyEntry(
              date: d,
              observations: [
                Observation(
                  id: 'd_$i',
                  timestamp: d,
                  sensation: Sensation.dry,
                  stretch: Stretch.none,
                  colors: const [],
                  consistencies: const [],
                  bleeding: Bleeding.none,
                  userId: 'test',
                ),
              ],
            ),
          );
        }

        // Patch 2: Day 15 peak (10WL), Day 16 dry
        final d15 = start.add(const Duration(days: 14));
        entries.add(
          CreightonLogic.resolveDailyEntry(
            date: d15,
            observations: [
              Observation(
                id: 'p_15',
                timestamp: d15,
                sensation: Sensation.wet,
                stretch: Stretch.none,
                colors: const [],
                consistencies: const [Consistency.lubricative],
                bleeding: Bleeding.none,
                userId: 'test',
              ),
            ],
          ),
        );
        final d16 = start.add(const Duration(days: 15));
        entries.add(
          CreightonLogic.resolveDailyEntry(
            date: d16,
            observations: [
              Observation(
                id: 'd_16',
                timestamp: d16,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: const [],
                consistencies: const [],
                bleeding: Bleeding.none,
                userId: 'test',
              ),
            ],
          ),
        );

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: const [],
        );

        // Day 15 is identified as Peak (P), not Day 5
        expect(recalculated[d5.dateKey]?.peakDayLabel, isNull);
        expect(recalculated[d15.dateKey]?.peakDayLabel, 'P');
        expect(recalculated[d16.dateKey]?.peakDayLabel, '1');
      },
    );

    test(
      'accurately identifies Peak Day and labels for debug app state cycle (Sept 15 10SL followed by Sept 16 and Sept 17)',
      () {
        final d14 = DateTime(2026, 9, 14);
        final d15 = DateTime(2026, 9, 15);
        final d16 = DateTime(2026, 9, 16);
        final d17 = DateTime(2026, 9, 17);

        // Sept 14: 10SLK (stretchy, clear, lubricative)
        final obs14 = Observation(
          id: 'obs_14',
          timestamp: d14,
          sensation: Sensation.damp,
          stretch: Stretch.stretchy,
          colors: const [MucusColor.clear],
          consistencies: const [Consistency.lubricative],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        // Sept 15: 10SL (lubricative, cloudy) - Candidate Peak Day
        final obs15 = Observation(
          id: 'obs_15',
          timestamp: d15,
          sensation: Sensation.damp,
          stretch: Stretch.none,
          colors: const [MucusColor.cloudy],
          consistencies: const [Consistency.lubricative],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        // Sept 16: 2 (damp, no mucus) - Day 1 of shift
        final obs16 = Observation(
          id: 'obs_16',
          timestamp: d16,
          sensation: Sensation.damp,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        // Sept 17: 0 (dry, no mucus) - Day 2 of shift
        final obs17 = Observation(
          id: 'obs_17',
          timestamp: d17,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'test',
        );

        final entries = [
          CreightonLogic.resolveDailyEntry(date: d14, observations: [obs14]),
          CreightonLogic.resolveDailyEntry(date: d15, observations: [obs15]),
          CreightonLogic.resolveDailyEntry(date: d16, observations: [obs16]),
          CreightonLogic.resolveDailyEntry(date: d17, observations: [obs17]),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: const [],
        );

        // Sept 15 should be identified as Peak (P)
        expect(recalculated[d15.dateKey]?.peakDayLabel, 'P');
        expect(recalculated[d15.dateKey]?.isPeakDay, isTrue);

        // Sept 16 should be labeled '1' with greenBaby stamp
        expect(recalculated[d16.dateKey]?.peakDayLabel, '1');
        expect(recalculated[d16.dateKey]?.stampType, StampType.greenBaby);

        // Sept 17 should be labeled '2' with greenBaby stamp
        expect(recalculated[d17.dateKey]?.peakDayLabel, '2');
        expect(recalculated[d17.dateKey]?.stampType, StampType.greenBaby);
      },
    );
  });
}
