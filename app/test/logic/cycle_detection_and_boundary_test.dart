import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    await db.createChart();
  });

  group('Automatic Cycle Detection & Boundary Operations', () {
    // 1. Auto detection: H/M menses >= 16 days starts new cycle.
    group('1. Auto detection (H/M menses >= 16 days starts new cycle)', () {
      test(
        'heavy or moderate bleeding >= 16 days from cycle start creates new cycle',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          // Day 17 (16 days difference from June 1): Heavy bleeding
          final june17 = DateTime(2026, 6, 17);
          await db.saveObservation(
            date: june17,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'New cycle menses',
          );

          final cycles = await db.streamCycles().first;
          expect(cycles.length, 2);
          // Cycles are sorted descending by startDate
          expect(cycles[0].startDate, june17);
          expect(cycles[1].startDate, cycle1Start);
          expect(cycles[0].dailyEntries.containsKey('2026-06-17'), isTrue);
          expect(cycles[1].dailyEntries.containsKey('2026-06-01'), isTrue);
        },
      );

      test('moderate bleeding at 16 days creates new cycle', () async {
        final cycle1Start = DateTime(2026, 6, 1);
        await db.saveObservation(
          date: cycle1Start,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.heavy,
          bleedingColor: 'R',
          painLevel: 0,
          painTypes: [],
          comment: 'Cycle 1 Start',
        );

        final june17 = DateTime(2026, 6, 17);
        await db.saveObservation(
          date: june17,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.moderate,
          bleedingColor: 'R',
          painLevel: 0,
          painTypes: [],
          comment: 'Moderate flow menses',
        );

        final cycles = await db.streamCycles().first;
        expect(cycles.length, 2);
        expect(cycles[0].startDate, june17);
      });
    });

    // 2. Pre-menstrual rollback: L/VL bleeding >= 16 days leading into H/M flow backdates cycle start date to the first L/VL day.
    group('2. Pre-menstrual rollback', () {
      test(
        'L/VL bleeding on day 16 leading into H/M flow on day 17 backdates cycle start date to day 16',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          // Day 17 (June 17, diff = 16 days): Light spotting
          final june17 = DateTime(2026, 6, 17);
          await db.saveObservation(
            date: june17,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.light,
            bleedingColor: 'B',
            painLevel: 0,
            painTypes: [],
            comment: 'Pre-menstrual light bleeding',
          );

          // Initially June 17 observation remains in Cycle 1
          var cycles = await db.streamCycles().first;
          expect(cycles.length, 1);

          // Day 18 (June 18, diff = 17 days): Heavy menses flow
          final june18 = DateTime(2026, 6, 18);
          await db.saveObservation(
            date: june18,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Heavy menses flow',
          );

          cycles = await db.streamCycles().first;
          expect(cycles.length, 2);

          // Cycle 2 start date should be backdated to June 17 (first L/VL day)
          expect(cycles[0].startDate, june17);
          expect(cycles[0].dailyEntries.containsKey('2026-06-17'), isTrue);
          expect(cycles[0].dailyEntries.containsKey('2026-06-18'), isTrue);
          expect(cycles[1].startDate, cycle1Start);
          expect(cycles[1].dailyEntries.containsKey('2026-06-17'), isFalse);
        },
      );

      test(
        'multiple contiguous L/VL days >= 16 days backdates to earliest contiguous L/VL day',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          // Day 17 (June 17, diff 16): Light bleeding
          final june17 = DateTime(2026, 6, 17);
          await db.saveObservation(
            date: june17,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.light,
            bleedingColor: 'B',
            painLevel: 0,
            painTypes: [],
            comment: 'Pre-menstrual light day 1',
          );

          // Day 18 (June 18, diff 17): Very light bleeding
          final june18 = DateTime(2026, 6, 18);
          await db.saveObservation(
            date: june18,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.veryLight,
            bleedingColor: 'B',
            painLevel: 0,
            painTypes: [],
            comment: 'Pre-menstrual light day 2',
          );

          // Day 19 (June 19, diff 18): Heavy menses flow
          final june19 = DateTime(2026, 6, 19);
          await db.saveObservation(
            date: june19,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Heavy menses flow',
          );

          final cycles = await db.streamCycles().first;
          expect(cycles.length, 2);
          // Backdated to June 17 (the earliest contiguous L/VL day on/after day 16)
          expect(cycles[0].startDate, june17);
          expect(cycles[0].dailyEntries.containsKey('2026-06-17'), isTrue);
          expect(cycles[0].dailyEntries.containsKey('2026-06-18'), isTrue);
          expect(cycles[0].dailyEntries.containsKey('2026-06-19'), isTrue);
        },
      );
    });

    // 3. Mid-cycle bleeding protection: Bleeding < 16 days stays in active cycle as intermenstrual bleeding.
    group('3. Mid-cycle bleeding protection', () {
      test(
        'bleeding < 16 days from cycle start does NOT start a new cycle',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          // Day 10 (June 10, diff = 9 days < 16): Heavy intermenstrual bleeding
          final june10 = DateTime(2026, 6, 10);
          await db.saveObservation(
            date: june10,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Mid-cycle heavy bleeding',
          );

          // Day 15 (June 15, diff = 14 days < 16): Moderate intermenstrual bleeding
          final june15 = DateTime(2026, 6, 15);
          await db.saveObservation(
            date: june15,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.moderate,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Mid-cycle moderate bleeding',
          );

          // Day 16 (June 16, diff = 15 days < 16): Light intermenstrual bleeding
          final june16 = DateTime(2026, 6, 16);
          await db.saveObservation(
            date: june16,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.light,
            bleedingColor: 'B',
            painLevel: 0,
            painTypes: [],
            comment: 'Mid-cycle light bleeding',
          );

          final cycles = await db.streamCycles().first;
          expect(cycles.length, 1);
          expect(cycles.first.startDate, cycle1Start);
          expect(cycles.first.dailyEntries.length, 4);
          expect(cycles.first.dailyEntries.containsKey('2026-06-10'), isTrue);
          expect(cycles.first.dailyEntries.containsKey('2026-06-15'), isTrue);
          expect(cycles.first.dailyEntries.containsKey('2026-06-16'), isTrue);
        },
      );
    });

    // 4. startNewCycle: Manual creation of a new cycle at a given date splits existing cycles and re-attributes daily entries cleanly.
    group('4. startNewCycle manual splitting', () {
      test(
        'manually starting a cycle splits existing cycle entries cleanly at the new boundary',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          final june5 = DateTime(2026, 6, 5);
          await db.saveObservation(
            date: june5,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 5 entry',
          );

          final june12 = DateTime(2026, 6, 12);
          await db.saveObservation(
            date: june12,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 12 entry',
          );

          final june20 = DateTime(2026, 6, 20);
          await db.saveObservation(
            date: june20,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 20 entry',
          );

          final june25 = DateTime(2026, 6, 25);
          await db.saveObservation(
            date: june25,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 25 entry',
          );

          var cycles = await db.streamCycles().first;
          expect(cycles.length, 1);
          expect(cycles.first.dailyEntries.length, 5);

          // Manually start a new cycle on June 15
          final june15 = DateTime(2026, 6, 15);
          await db.startNewCycle(june15, ['6C']);

          cycles = await db.streamCycles().first;
          expect(cycles.length, 2);

          final cycle2 = cycles[0]; // June 15
          final cycle1 = cycles[1]; // June 1

          expect(cycle1.startDate, cycle1Start);
          expect(cycle1.dailyEntries.containsKey('2026-06-01'), isTrue);
          expect(cycle1.dailyEntries.containsKey('2026-06-05'), isTrue);
          expect(cycle1.dailyEntries.containsKey('2026-06-12'), isTrue);
          expect(cycle1.dailyEntries.containsKey('2026-06-20'), isFalse);
          expect(cycle1.dailyEntries.containsKey('2026-06-25'), isFalse);

          expect(cycle2.startDate, june15);
          expect(cycle2.dailyEntries.containsKey('2026-06-20'), isTrue);
          expect(cycle2.dailyEntries.containsKey('2026-06-25'), isTrue);
          expect(cycle2.dailyEntries.containsKey('2026-06-12'), isFalse);
        },
      );
    });

    // 5. updateCycleStartDate: Changing cycle start date re-attributes entries across cycle boundaries.
    group('5. updateCycleStartDate re-attribution', () {
      test(
        'moving cycle start date earlier pulls entries from preceding cycle',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          final june15 = DateTime(2026, 6, 15);
          await db.saveObservation(
            date: june15,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 15 entry',
          );

          final june18 = DateTime(2026, 6, 18);
          await db.saveObservation(
            date: june18,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 18 entry',
          );

          // Manually start Cycle 2 on June 20
          final june20 = DateTime(2026, 6, 20);
          await db.startNewCycle(june20, ['6C']);

          final june22 = DateTime(2026, 6, 22);
          await db.saveObservation(
            date: june22,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 22 entry',
          );

          // Before update: June 18 is in Cycle 1 (June 1)
          var cycles = await db.streamCycles().first;
          expect(cycles[1].dailyEntries.containsKey('2026-06-18'), isTrue);

          // Update Cycle 2 start date from June 20 to June 16
          final june16 = DateTime(2026, 6, 16);
          await db.updateCycleStartDate('2026-06-20', june16);

          cycles = await db.streamCycles().first;
          expect(cycles.length, 2);

          final updatedCycle2 = cycles[0]; // June 16
          final updatedCycle1 = cycles[1]; // June 1

          expect(updatedCycle2.startDate, june16);
          // June 18 entry now belongs to Cycle 2 (June 16)
          expect(updatedCycle2.dailyEntries.containsKey('2026-06-18'), isTrue);
          expect(updatedCycle2.dailyEntries.containsKey('2026-06-22'), isTrue);

          // June 15 entry remains in Cycle 1
          expect(updatedCycle1.dailyEntries.containsKey('2026-06-15'), isTrue);
          expect(updatedCycle1.dailyEntries.containsKey('2026-06-18'), isFalse);
        },
      );

      test(
        'moving cycle start date later pushes entries back to preceding cycle',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          final june16 = DateTime(2026, 6, 16);
          await db.startNewCycle(june16, ['6C']);

          final june18 = DateTime(2026, 6, 18);
          await db.saveObservation(
            date: june18,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 18 entry',
          );

          // Before update: June 18 belongs to Cycle 2 (June 16)
          var cycles = await db.streamCycles().first;
          expect(cycles[0].dailyEntries.containsKey('2026-06-18'), isTrue);

          // Shift Cycle 2 start date later to June 20
          final june20 = DateTime(2026, 6, 20);
          await db.updateCycleStartDate('2026-06-16', june20);

          cycles = await db.streamCycles().first;
          final shiftedCycle2 = cycles[0]; // June 20
          final shiftedCycle1 = cycles[1]; // June 1

          expect(shiftedCycle2.startDate, june20);
          // June 18 entry moved back to Cycle 1 (June 1)
          expect(shiftedCycle1.dailyEntries.containsKey('2026-06-18'), isTrue);
          expect(shiftedCycle2.dailyEntries.containsKey('2026-06-18'), isFalse);
        },
      );
    });

    // 6. mergeCycleWithPrevious: Merging a cycle boundary into the preceding cycle moves entries and removes the cycle boundary.
    group('6. mergeCycleWithPrevious boundary merge', () {
      test(
        'merging cycle with previous merges entries and removes cycle boundary',
        () async {
          final cycle1Start = DateTime(2026, 6, 1);
          await db.saveObservation(
            date: cycle1Start,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Cycle 1 Start',
          );

          final june10 = DateTime(2026, 6, 10);
          await db.saveObservation(
            date: june10,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 10 entry',
          );

          // Start Cycle 2 on June 20
          final june20 = DateTime(2026, 6, 20);
          await db.startNewCycle(june20, ['6C']);

          final june25 = DateTime(2026, 6, 25);
          await db.saveObservation(
            date: june25,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.none,
            bleedingColor: '',
            painLevel: 0,
            painTypes: [],
            comment: 'June 25 entry',
          );

          var cycles = await db.streamCycles().first;
          expect(cycles.length, 2);

          // Merge Cycle 2 ('2026-06-20') into Cycle 1 ('2026-06-01')
          await db.mergeCycleWithPrevious('2026-06-20');

          cycles = await db.streamCycles().first;
          expect(cycles.length, 1);

          final mergedCycle = cycles.first;
          expect(mergedCycle.startDate, cycle1Start);
          // All entries from both cycles are now in Cycle 1
          expect(mergedCycle.dailyEntries.containsKey('2026-06-01'), isTrue);
          expect(mergedCycle.dailyEntries.containsKey('2026-06-10'), isTrue);
          expect(mergedCycle.dailyEntries.containsKey('2026-06-25'), isTrue);
        },
      );
    });
  });
}
