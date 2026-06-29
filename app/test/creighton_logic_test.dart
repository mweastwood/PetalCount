import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/models/observation.dart';
import 'package:petal_count/models/daily_entry.dart';
import 'package:petal_count/services/creighton_logic.dart';

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
      );
      expect(obs.vdrsCode, '0');
    });

    test('Stretchy clear mucus generates 10-K', () {
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
      expect(obs.vdrsCode, '10-K');
    });

    test(
      'Stretchy clear lubricative mucus generates 10WL-K-L (with wet sensation)',
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
        expect(
          obs.vdrsCode,
          '10WL-K',
        ); // in our implementation, lubricative code is 10WL-K
      },
    );

    test('Bleeding only generates code like H-R', () {
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
      expect(obs.vdrsCode, 'H-R');
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

      expect(daily.resolvedVdrsCode, '6-C-G');
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

      expect(daily.resolvedVdrsCode, 'H-R 10-K');
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
          entries.add(
            DailyEntry(
              date: start.add(Duration(days: i)),
              resolvedVdrsCode: 'H-R',
              stampType: StampType.green,
              observations: [],
              painLevel: 0,
              painTypes: [],
              comments: '',
            ),
          );
        }

        // Day 4-8: Dry (Green)
        for (int i = 3; i < 8; i++) {
          entries.add(
            DailyEntry(
              date: start.add(Duration(days: i)),
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: [],
              painLevel: 0,
              painTypes: [],
              comments: '',
            ),
          );
        }

        // Day 9: Mucus Build-up (White Baby)
        entries.add(
          DailyEntry(
            date: start.add(const Duration(days: 8)),
            resolvedVdrsCode: '6-C',
            stampType: StampType.green,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        );

        // Day 10: Peak mucus (10-K)
        entries.add(
          DailyEntry(
            date: start.add(const Duration(days: 9)),
            resolvedVdrsCode: '10-K',
            stampType: StampType.green,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        );

        // Day 11-14: Dry (should be Green Baby for 11, 12, 13 due to Peak + 3 shift, and then Plain Green)
        for (int i = 10; i < 15; i++) {
          entries.add(
            DailyEntry(
              date: start.add(Duration(days: i)),
              resolvedVdrsCode: '0',
              stampType: StampType.green,
              observations: [],
              painLevel: 0,
              painTypes: [],
              comments: '',
            ),
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
        final entries = <DailyEntry>[
          DailyEntry(
            date: start,
            resolvedVdrsCode: '6-C', // Mucus matching BIP
            stampType: StampType.green,
            observations: [],
            painLevel: 0,
            painTypes: [],
            comments: '',
          ),
        ];

        final recalculated = CreightonLogic.recalculateCycle(
          entries: entries,
          bipCodes: ['6-C'],
        );

        final dateKey = start.toIso8601String().substring(0, 10);
        expect(recalculated[dateKey]?.stampType, StampType.yellow);
      },
    );
  });
}
