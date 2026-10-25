import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  const testSupplements = <SupplementItem>[
    SupplementItem(
      id: 'prenatal',
      name: 'Prenatal',
      quantity: 'tablet',
      morningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.allDays,
    ),
    SupplementItem(
      id: 'clomid',
      name: 'Clomid',
      quantity: '50 mg (1 tablet)',
      morningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.cycleDays,
      startCycleDay: 4,
      endCycleDay: 8,
    ),
    SupplementItem(
      id: 'fertilecm',
      name: 'FertileCM',
      quantity: 'tablet',
      morningDose: 1,
      afternoonDose: 1,
      eveningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.cycleDaysOrPeak,
      startCycleDay: 8,
      endCycleDay: 19,
      endPeakOffset: 1,
    ),
    SupplementItem(
      id: 'mucinex',
      name: 'Mucinex ER',
      quantity: '600mg',
      morningDose: 1,
      eveningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.cycleDaysOrPeak,
      startCycleDay: 9,
      endCycleDay: 19,
      endPeakOffset: 1,
    ),
    SupplementItem(
      id: 'progesterone',
      name: 'Progesterone (sustained release)',
      quantity: '400mg (2 tablets)',
      morningDose: 1,
      eveningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.peakOffset,
      startPeakOffset: 3,
      startCycleDay: 21,
      durationDays: 10,
    ),
    SupplementItem(
      id: 'mens_multi',
      name: "Men's Multivitamin",
      quantity: '1 tablet',
      morningDose: 1,
      targetRole: UserRole.husband,
      ruleType: SupplementScheduleRuleType.allDays,
    ),
  ];

  group('SupplementForecastEngine', () {
    final startDate = DateTime(2026, 8, 25);

    test(
      'separates definite and conditional-on-peak supplements when Peak has not yet occurred',
      () {
        // Cycle starts Aug 20 -> Aug 25 is Cycle Day 6
        final cycle = Cycle(id: 'c1', startDate: DateTime(2026, 8, 20));
        final forecast = SupplementForecastEngine.buildForecast(
          startDate: startDate,
          supplements: testSupplements,
          role: UserRole.wife,
          cycles: [cycle],
        );

        expect(forecast, hasLength(7));

        // Day 0 (Aug 25, Cycle Day 6):
        // Clomid (Days 4-8) + daily items are scheduled; no peak-conditional items yet
        final day0 = forecast[0];
        expect(day0.cycleDay, 6);
        expect(day0.hasPeakOccurred, isFalse);
        expect(
          day0.scheduledSupplements.any((s) => s.name == 'Clomid'),
          isTrue,
        );
        expect(day0.conditionalOnPeakSupplements, isEmpty);

        // Day 2 (Aug 27, Cycle Day 8):
        // Clomid (Day 8) is definite; FertileCM (Day 8 to P+1) is conditional on Peak
        final day2 = forecast[2];
        expect(day2.cycleDay, 8);
        expect(day2.hasPeakOccurred, isFalse);
        expect(
          day2.scheduledSupplements.any((s) => s.name == 'Clomid'),
          isTrue,
        );
        expect(
          day2.scheduledSupplements.any((s) => s.name == 'FertileCM'),
          isFalse,
        );
        expect(
          day2.conditionalOnPeakSupplements.any((s) => s.name == 'FertileCM'),
          isTrue,
        );

        // Day 3 (Aug 28, Cycle Day 9):
        // Clomid ended on Day 8; FertileCM, Mucinex ER, and Progesterone (P+3) are conditional on Peak
        final day3 = forecast[3];
        expect(day3.cycleDay, 9);
        expect(
          day3.scheduledSupplements.any((s) => s.name == 'Clomid'),
          isFalse,
        );
        expect(
          day3.conditionalOnPeakSupplements.map((s) => s.name),
          containsAll([
            'FertileCM',
            'Mucinex ER',
            'Progesterone (sustained release)',
          ]),
        );
      },
    );

    test(
      'includes active fallback peak-dependent items on Today (dayOffset 0) in both scheduled and conditional',
      () {
        // Cycle starts Aug 16 -> Aug 25 is Cycle Day 10 (FertileCM & Mucinex active)
        final cycle = Cycle(id: 'c1', startDate: DateTime(2026, 8, 16));
        final forecast = SupplementForecastEngine.buildForecast(
          startDate: startDate,
          supplements: testSupplements,
          role: UserRole.wife,
          cycles: [cycle],
        );

        final today = forecast.first;
        expect(today.cycleDay, 10);
        expect(today.hasPeakOccurred, isFalse);
        expect(
          today.scheduledSupplements.map((s) => s.name),
          containsAll(['FertileCM', 'Mucinex ER']),
        );
        expect(
          today.conditionalOnPeakSupplements.map((s) => s.name),
          containsAll(['FertileCM', 'Mucinex ER']),
        );
      },
    );

    test(
      'auto-uses Peak from active cycle when detected and clears conditionalOnPeakSupplements',
      () {
        // Cycle starts Aug 12; Peak Day logged on Aug 24 (Cycle Day 13)
        // Aug 25 = P+1 (Day 14), Aug 26 = P+2 (Day 15), Aug 27 = P+3 (Day 16)
        final peakDate = DateTime(2026, 8, 24);
        final cycle = Cycle(
          id: 'c1',
          startDate: DateTime(2026, 8, 12),
          dailyEntries: {
            peakDate.dateKey: DailyEntry.raw(date: peakDate, peakDayLabel: 'P'),
          },
        );

        final forecast = SupplementForecastEngine.buildForecast(
          startDate: startDate,
          supplements: testSupplements,
          role: UserRole.wife,
          cycles: [cycle],
        );

        // Day 0 (Aug 25, P+1): FertileCM & Mucinex ER active (until P+1), Progesterone not yet (P+3)
        expect(forecast[0].daysPastPeak, 1);
        expect(forecast[0].hasPeakOccurred, isTrue);
        expect(forecast[0].conditionalOnPeakSupplements, isEmpty);
        expect(
          forecast[0].scheduledSupplements.map((s) => s.name),
          containsAll(['FertileCM', 'Mucinex ER']),
        );
        expect(
          forecast[0].scheduledSupplements.any(
            (s) => s.name.startsWith('Progesterone'),
          ),
          isFalse,
        );

        // Day 1 (Aug 26, P+2): FertileCM & Mucinex ER stopped after P+1
        expect(forecast[1].daysPastPeak, 2);
        expect(forecast[1].hasPeakOccurred, isTrue);
        expect(forecast[1].conditionalOnPeakSupplements, isEmpty);
        expect(
          forecast[1].scheduledSupplements.any((s) => s.name == 'FertileCM'),
          isFalse,
        );
        expect(
          forecast[1].scheduledSupplements.any((s) => s.name == 'Mucinex ER'),
          isFalse,
        );

        // Day 2 (Aug 27, P+3): Progesterone starts at P+3!
        expect(forecast[2].daysPastPeak, 3);
        expect(forecast[2].hasPeakOccurred, isTrue);
        expect(forecast[2].conditionalOnPeakSupplements, isEmpty);
        expect(
          forecast[2].scheduledSupplements.any(
            (s) => s.name.startsWith('Progesterone'),
          ),
          isTrue,
        );
      },
    );

    test(
      'handles navigating to a pre-Peak date when Peak Day is already recorded later in the cycle (daysPastPeak < 0 transitioning to >= 0)',
      () {
        // Cycle starts Aug 12; Peak Day is recorded on Aug 27 (Cycle Day 16).
        // Forecast starts on Aug 25 (2 days before recorded Peak, daysPastPeak = -2).
        final peakDate = DateTime(2026, 8, 27);
        final cycle = Cycle(
          id: 'c1',
          startDate: DateTime(2026, 8, 12),
          dailyEntries: {
            peakDate.dateKey: DailyEntry.raw(date: peakDate, peakDayLabel: 'P'),
          },
        );

        final forecast = SupplementForecastEngine.buildForecast(
          startDate: startDate, // Aug 25
          supplements: testSupplements,
          role: UserRole.wife,
          cycles: [cycle],
        );

        // Day 0 (Aug 25, P-2) and Day 1 (Aug 26, P-1): Peak has not yet occurred as of date,
        // but Peak Date is already known (daysPastPeak < 0), so Progesterone (P+3) cannot
        // start on Day 1 via couldStartIfPeakSoon.
        expect(forecast[0].daysPastPeak, -2);
        expect(forecast[0].hasPeakOccurred, isFalse);

        expect(forecast[1].daysPastPeak, -1);
        expect(forecast[1].hasPeakOccurred, isFalse);
        expect(
          forecast[1].conditionalOnPeakSupplements.any(
            (s) => s.name.startsWith('Progesterone'),
          ),
          isFalse,
        );

        // Day 2 (Aug 27, P): Transitions to hasPeakOccurred == true
        expect(forecast[2].daysPastPeak, 0);
        expect(forecast[2].hasPeakOccurred, isTrue);
        expect(forecast[2].conditionalOnPeakSupplements, isEmpty);
        expect(
          forecast[2].scheduledSupplements.map((s) => s.name),
          containsAll(['FertileCM', 'Mucinex ER']),
        );

        // Day 4 (Aug 29, P+2): FertileCM & Mucinex ER stopped after P+1; Progesterone not yet
        expect(forecast[4].daysPastPeak, 2);
        expect(forecast[4].hasPeakOccurred, isTrue);
        expect(
          forecast[4].scheduledSupplements.any((s) => s.name == 'FertileCM'),
          isFalse,
        );
        expect(
          forecast[4].scheduledSupplements.any(
            (s) => s.name.startsWith('Progesterone'),
          ),
          isFalse,
        );

        // Day 5 (Aug 30, P+3): Progesterone starts deterministically on P+3
        expect(forecast[5].daysPastPeak, 3);
        expect(forecast[5].hasPeakOccurred, isTrue);
        expect(
          forecast[5].scheduledSupplements.any(
            (s) => s.name.startsWith('Progesterone'),
          ),
          isTrue,
        );
      },
    );

    test(
      'excludes custom peakOffset supplements with invalid or pre-Peak-only windows from conditionalOnPeakSupplements',
      () {
        final cycle = Cycle(id: 'c1', startDate: DateTime(2026, 8, 20));
        final customSupplements = [
          const SupplementItem(
            id: 'pre_peak_only',
            name: 'PrePeakOffsetOnly',
            quantity: '1 cap',
            morningDose: 1,
            ruleType: SupplementScheduleRuleType.peakOffset,
            startPeakOffset: -2,
            endPeakOffset: -1,
          ),
          const SupplementItem(
            id: 'zero_duration',
            name: 'ZeroDurationPeakOffset',
            quantity: '1 cap',
            morningDose: 1,
            ruleType: SupplementScheduleRuleType.peakOffset,
            startPeakOffset: 1,
            durationDays: 0,
          ),
          const SupplementItem(
            id: 'inverted_window',
            name: 'InvertedPeakOffset',
            quantity: '1 cap',
            morningDose: 1,
            ruleType: SupplementScheduleRuleType.peakOffset,
            startPeakOffset: 3,
            endPeakOffset: 1,
          ),
        ];

        final forecast = SupplementForecastEngine.buildForecast(
          startDate: startDate,
          supplements: customSupplements,
          role: UserRole.wife,
          cycles: [cycle],
        );

        for (final day in forecast) {
          expect(day.conditionalOnPeakSupplements, isEmpty);
          expect(day.scheduledSupplements, isEmpty);
        }
      },
    );

    test(
      'keeps cycleDay at 1 across all forecast days when no cycle exists and does not schedule Cycle Day 4-8 medications',
      () {
        final forecast = SupplementForecastEngine.buildForecast(
          startDate: startDate,
          supplements: testSupplements,
          role: UserRole.wife,
          cycles: const [],
          fallbackCycle: null,
        );

        expect(forecast, hasLength(7));
        for (final day in forecast) {
          expect(day.cycleDay, 1);
          expect(
            day.scheduledSupplements.any((s) => s.name == 'Clomid'),
            isFalse,
          );
        }
      },
    );
  });
}
