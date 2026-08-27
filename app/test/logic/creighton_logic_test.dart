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
              resolvedVdrsCode: 'VL-B',
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
              resolvedVdrsCode: 'VL-B',
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
}
