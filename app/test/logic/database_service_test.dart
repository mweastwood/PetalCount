import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() {
    db = InMemoryDatabaseService();
  });

  test('InMemoryDatabaseService initial state has a currentChartId', () {
    expect(db.currentChartId, 'mock_shared_chart');
    expect(db.currentUser, isNotNull);
  });

  test('unlinkChart sets currentChartId to null and clears cache', () async {
    expect(db.currentChartId, 'mock_shared_chart');

    await db.unlinkChart();

    expect(db.currentChartId, isNull);
  });

  test('unlinkChart triggers authStateChanges stream broadcast', () async {
    final userStates = <Object?>[];
    final subscription = db.authStateChanges.listen((user) {
      userStates.add(user);
    });

    // Perform unlink which triggers auth controller event
    await db.unlinkChart();

    await Future.delayed(Duration.zero); // Allow stream to flush events

    expect(userStates, isNotEmpty);
    expect(db.currentChartId, isNull);

    await subscription.cancel();
  });

  test('streamAvailableCharts streams all charts linked to user', () async {
    final chartsList = await db.streamAvailableCharts().first;
    expect(chartsList.length, 1);
    expect(chartsList.first['id'], 'mock_shared_chart');
  });

  test('setActiveChart updates currentChartId', () async {
    await db.setActiveChart('another_mock_chart');
    expect(db.currentChartId, 'another_mock_chart');
  });

  test(
    'createChart creates a new chart, sets it active, and streams it',
    () async {
      final initialCharts = await db.streamAvailableCharts().first;
      expect(initialCharts.length, 1);

      await db.createChart();

      final updatedCharts = await db.streamAvailableCharts().first;
      expect(updatedCharts.length, 2);
      expect(db.currentChartId, startsWith('chart_'));
    },
  );

  test(
    'deleteChart permanently deletes a chart and clears user link',
    () async {
      final initialCharts = await db.streamAvailableCharts().first;
      expect(initialCharts.length, 1);
      final activeId = db.currentChartId;
      expect(activeId, isNotNull);

      await db.deleteChart(activeId!);

      final updatedCharts = await db.streamAvailableCharts().first;
      expect(updatedCharts, isEmpty);
      expect(db.currentChartId, isNull);
    },
  );

  test(
    'leaveChart removes user access to the chart and unlinks active profile',
    () async {
      final initialCharts = await db.streamAvailableCharts().first;
      expect(initialCharts.length, 1);
      final activeId = db.currentChartId;
      expect(activeId, isNotNull);

      // Add a collaborator so leaving is allowed
      await db.invitePartner('partner@example.com');

      await db.leaveChart(activeId!);

      final updatedCharts = await db.streamAvailableCharts().first;
      expect(updatedCharts, isEmpty);
      expect(db.currentChartId, isNull);
    },
  );

  test(
    'leaveChart throws Exception when user is the sole collaborator',
    () async {
      // Create a new chart which starts with only 1 user (the current user)
      await db.createChart();
      final activeId = db.currentChartId;
      expect(activeId, isNotNull);

      expect(
        db.leaveChart(activeId!),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot leave a chart when you are the sole collaborator'),
          ),
        ),
      );
    },
  );

  group('Automatic Cycle Detection', () {
    test(
      'auto-creates initial cycle when saving observation on an empty chart',
      () async {
        await db.createChart();

        final obsDate = DateTime(2026, 7, 1);
        await db.saveObservation(
          date: obsDate,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Initial entry',
        );

        final cycles = await db.streamCycles().first;
        expect(cycles.length, 1);
        expect(cycles.first.startDate, obsDate);
        expect(cycles.first.dailyEntries.containsKey('2026-07-01'), true);
      },
    );

    test(
      'auto-detects a NEW cycle when menses is reported >= 10 days after cycle start',
      () async {
        await db.createChart();

        // Start cycle on June 1
        final june1 = DateTime(2026, 6, 1);
        await db.saveObservation(
          date: june1,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.heavy,
          bleedingColor: 'R',
          painLevel: 0,
          painTypes: [],
          comment: 'Day 1 of June cycle',
        );

        var cycles = await db.streamCycles().first;
        expect(cycles.length, 1);
        expect(cycles.first.startDate, june1);

        // Log menses 27 days later on June 28
        final june28 = DateTime(2026, 6, 28);
        await db.saveObservation(
          date: june28,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.heavy,
          bleedingColor: 'R',
          painLevel: 0,
          painTypes: [],
          comment: 'Period starts for next cycle',
        );

        cycles = await db.streamCycles().first;
        expect(cycles.length, 2);
        // Cycles sorted descending: newest first
        expect(cycles[0].startDate, june28);
        expect(cycles[1].startDate, june1);
        expect(cycles[0].dailyEntries.containsKey('2026-06-28'), true);
      },
    );

    test(
      'does NOT split cycle when menses is reported < 10 days from cycle start (e.g. Day 2 of period)',
      () async {
        await db.createChart();

        final june1 = DateTime(2026, 6, 1);
        await db.saveObservation(
          date: june1,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.heavy,
          bleedingColor: 'R',
          painLevel: 0,
          painTypes: [],
          comment: 'Day 1',
        );

        final june2 = DateTime(2026, 6, 2);
        await db.saveObservation(
          date: june2,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.moderate,
          bleedingColor: 'R',
          painLevel: 0,
          painTypes: [],
          comment: 'Day 2',
        );

        final cycles = await db.streamCycles().first;
        expect(cycles.length, 1);
        expect(cycles.first.startDate, june1);
        expect(cycles.first.dailyEntries.length, 2);
      },
    );

    test('routes non-menses observations to existing matching cycle', () async {
      await db.createChart();

      final june1 = DateTime(2026, 6, 1);
      await db.saveObservation(
        date: june1,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Day 1',
      );

      // Log stretchy mucus mid-cycle on June 14
      final june14 = DateTime(2026, 6, 14);
      await db.saveObservation(
        date: june14,
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: 'Peak mucus',
      );

      final cycles = await db.streamCycles().first;
      expect(cycles.length, 1);
      expect(cycles.first.dailyEntries.containsKey('2026-06-14'), true);
      expect(
        cycles.first.dailyEntries['2026-06-14']?.resolvedVdrsCode,
        contains('10'),
      );
    });
  });
}
