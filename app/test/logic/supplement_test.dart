import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  group('Supplement Model Tests', () {
    test(
      'SupplementPresets defaultList contains all 14 Google Sheet items',
      () {
        final presets = SupplementPresets.defaultList;
        expect(presets.length, 14);

        final names = presets.map((s) => s.name).toList();
        expect(names, contains('Prenatal'));
        expect(names, contains('CoQ10'));
        expect(names, contains('Vitamin D'));
        expect(names, contains('NAC (N-Acetyl Cysteine)'));
        expect(names, contains('L-methylfolate and sublingual B12'));
        expect(names, contains('Myo-inositol'));
        expect(names, contains('Berberine'));
        expect(names, contains('Fatty 15'));
        expect(names, contains('Magnesium L-Theonate'));
        expect(names, contains('Perfect Amino'));
        expect(names, contains('Clomid'));
        expect(names, contains('FertileCM'));
        expect(names, contains('Mucinex ER'));
        expect(names, contains('Progesterone (sustained release)'));
      },
    );

    test('isScheduledFor evaluates allDays daily supplements accurately', () {
      const supp = SupplementItem(
        id: '1',
        name: 'Prenatal',
        quantity: '1 tablet',
        morningDose: 1,
        ruleType: SupplementScheduleRuleType.allDays,
      );

      expect(supp.isScheduledFor(cycleDay: 1), isTrue);
      expect(supp.isScheduledFor(cycleDay: 14), isTrue);
      expect(supp.isScheduledFor(cycleDay: 35), isTrue);
    });

    test('isScheduledFor evaluates cycleDays rule (Clomid Days 4-8)', () {
      const clomid = SupplementItem(
        id: 'clomid',
        name: 'Clomid',
        quantity: '50 mg',
        morningDose: 1,
        ruleType: SupplementScheduleRuleType.cycleDays,
        startCycleDay: 4,
        endCycleDay: 8,
      );

      expect(clomid.isScheduledFor(cycleDay: 1), isFalse);
      expect(clomid.isScheduledFor(cycleDay: 3), isFalse);
      expect(clomid.isScheduledFor(cycleDay: 4), isTrue);
      expect(clomid.isScheduledFor(cycleDay: 6), isTrue);
      expect(clomid.isScheduledFor(cycleDay: 8), isTrue);
      expect(clomid.isScheduledFor(cycleDay: 9), isFalse);
    });

    test(
      'isScheduledFor evaluates peakOffset rule (Progesterone P+3 for 10 days)',
      () {
        const prog = SupplementItem(
          id: 'prog',
          name: 'Progesterone',
          quantity: '400 mg',
          morningDose: 1,
          eveningDose: 1,
          ruleType: SupplementScheduleRuleType.peakOffset,
          startPeakOffset: 3,
          durationDays: 10,
          startCycleDay: 21,
        );

        // When peak has occurred
        expect(
          prog.isScheduledFor(
            cycleDay: 15,
            daysPastPeak: 0,
            hasPeakOccurred: true,
          ),
          isFalse,
        );
        expect(
          prog.isScheduledFor(
            cycleDay: 17,
            daysPastPeak: 2,
            hasPeakOccurred: true,
          ),
          isFalse,
        );
        expect(
          prog.isScheduledFor(
            cycleDay: 18,
            daysPastPeak: 3,
            hasPeakOccurred: true,
          ),
          isTrue,
        );
        expect(
          prog.isScheduledFor(
            cycleDay: 27,
            daysPastPeak: 12,
            hasPeakOccurred: true,
          ),
          isTrue,
        );
        expect(
          prog.isScheduledFor(
            cycleDay: 28,
            daysPastPeak: 13,
            hasPeakOccurred: true,
          ),
          isFalse,
        );

        // Fallback when peak has not occurred yet
        expect(
          prog.isScheduledFor(cycleDay: 10, hasPeakOccurred: false),
          isFalse,
        );
        expect(
          prog.isScheduledFor(cycleDay: 21, hasPeakOccurred: false),
          isTrue,
        );
        expect(
          prog.isScheduledFor(cycleDay: 30, hasPeakOccurred: false),
          isTrue,
        );
        expect(
          prog.isScheduledFor(cycleDay: 31, hasPeakOccurred: false),
          isFalse,
        );
      },
    );

    test(
      'isScheduledFor evaluates cycleDaysOrPeak rule (FertileCM/Mucinex)',
      () {
        const fertileCM = SupplementItem(
          id: 'fertilecm',
          name: 'FertileCM',
          quantity: 'tablet',
          morningDose: 1,
          afternoonDose: 1,
          eveningDose: 1,
          ruleType: SupplementScheduleRuleType.cycleDaysOrPeak,
          startCycleDay: 8,
          endCycleDay: 19,
          endPeakOffset: 1,
        );

        // Before start day
        expect(fertileCM.isScheduledFor(cycleDay: 5), isFalse);

        // In fertile window before peak
        expect(fertileCM.isScheduledFor(cycleDay: 8), isTrue);
        expect(fertileCM.isScheduledFor(cycleDay: 14), isTrue);

        // Peak occurred: active through P+1
        expect(
          fertileCM.isScheduledFor(
            cycleDay: 15,
            daysPastPeak: 0,
            hasPeakOccurred: true,
          ),
          isTrue,
        );
        expect(
          fertileCM.isScheduledFor(
            cycleDay: 16,
            daysPastPeak: 1,
            hasPeakOccurred: true,
          ),
          isTrue,
        );
        expect(
          fertileCM.isScheduledFor(
            cycleDay: 17,
            daysPastPeak: 2,
            hasPeakOccurred: true,
          ),
          isFalse,
        );
      },
    );

    test('Serialization toMap and fromMap roundtrip', () {
      const original = SupplementItem(
        id: 'test_1',
        name: 'Myo-inositol',
        quantity: '2 g',
        takeWithFood: true,
        morningDose: 1,
        eveningDose: 1,
        ruleType: SupplementScheduleRuleType.allDays,
        instructions: 'Take with food',
      );

      final map = original.toMap();
      final reconstructed = SupplementItem.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.quantity, original.quantity);
      expect(reconstructed.takeWithFood, isTrue);
      expect(reconstructed.morningDose, 1);
      expect(reconstructed.eveningDose, 1);
      expect(reconstructed.afternoonDose, 0);
      expect(reconstructed.totalDailyDoses, 2);
      expect(reconstructed.instructions, 'Take with food');
    });

    test('DailySupplementLog toggles doses correctly', () {
      final date = DateTime(2026, 8, 25);
      var log = DailySupplementLog(date: date, takenDoses: {});

      expect(log.isTaken('prenatal', SupplementTimeOfDay.morning), isFalse);

      log = log.withToggled('prenatal', SupplementTimeOfDay.morning, true);
      expect(log.isTaken('prenatal', SupplementTimeOfDay.morning), isTrue);

      log = log.withToggled('prenatal', SupplementTimeOfDay.morning, false);
      expect(log.isTaken('prenatal', SupplementTimeOfDay.morning), isFalse);
    });
  });
}
