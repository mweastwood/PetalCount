import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('SupplementForecastEngine', () {
    final startDate = DateTime(2026, 8, 25);

    test(
      'separates definite and conditional-on-peak supplements when Peak has not yet occurred',
      () {
        // Cycle starts Aug 20 -> Aug 25 is Cycle Day 6
        final cycle = Cycle(id: 'c1', startDate: DateTime(2026, 8, 20));
        final forecast = SupplementForecastEngine.buildForecast(
          startDate: startDate,
          supplements: SupplementPresets.defaultList,
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
          supplements: SupplementPresets.defaultList,
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
          supplements: SupplementPresets.defaultList,
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
  });
}
