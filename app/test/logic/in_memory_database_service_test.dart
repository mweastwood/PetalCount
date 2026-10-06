import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'firebase_database_service_test.dart' hide main;

void main() {
  late InMemoryDatabaseService db;

  setUp(() {
    db = InMemoryDatabaseService();
    addTearDown(() => db.dispose());
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
    final authQueue = StreamQueue(db.authStateChanges.asBroadcastStream());
    expect(await authQueue.next, isNotNull);
    await pumpEventQueue();

    // Perform unlink which triggers auth controller event
    await db.unlinkChart();

    expect(await authQueue.next, isNotNull);
    expect(db.currentChartId, isNull);

    await authQueue.cancel();
  });

  test(
    'authStateChanges immediately provides currentUser with synchronized currentChartId',
    () async {
      final firstUser = await db.authStateChanges.first;
      expect(firstUser, isNotNull);
      expect(db.currentChartId, 'mock_shared_chart');
    },
  );

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

    test(
      'deleteObservation removes observation and recalculates cycle',
      () async {
        await db.createChart();

        final obsDate = DateTime(2026, 7, 10);
        await db.saveObservation(
          date: obsDate,
          sensation: Sensation.wet,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Peak entry',
        );

        var cycles = await db.streamCycles().first;
        expect(cycles.first.dailyEntries.containsKey('2026-07-10'), true);
        final obsId =
            cycles.first.dailyEntries['2026-07-10']!.observations.first.id;

        await db.deleteObservation(
          cycleId: cycles.first.id,
          date: obsDate,
          observationId: obsId,
        );

        cycles = await db.streamCycles().first;
        expect(cycles.first.dailyEntries.containsKey('2026-07-10'), false);
      },
    );

    test('deleteCycle deletes specific cycle from chart', () async {
      await db.createChart();

      final start1 = DateTime(2026, 1, 1);
      await db.startNewCycle(start1, ['6C']);

      final start2 = DateTime(2026, 2, 1);
      await db.startNewCycle(start2, ['6C']);

      var cycles = await db.streamCycles().first;
      expect(cycles.length, 2);

      await db.deleteCycle(cycles.first.id);

      cycles = await db.streamCycles().first;
      expect(cycles.length, 1);
      expect(cycles.first.startDate, start1);
    });

    test('mergeCycleWithPrevious merges entries into previous cycle', () async {
      await db.createChart();

      final start1 = DateTime(2026, 1, 1);
      await db.startNewCycle(start1, ['6C']);
      await db.saveObservation(
        date: start1,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: 'Cycle 1 Entry',
      );

      final start2 = DateTime(2026, 2, 1);
      await db.startNewCycle(start2, ['6C']);
      await db.saveObservation(
        date: start2,
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: 'Cycle 2 Entry',
      );

      var cycles = await db.streamCycles().first;
      expect(cycles.length, 2);

      await db.mergeCycleWithPrevious(start2.dateKey);

      cycles = await db.streamCycles().first;
      expect(cycles.length, 1);
      expect(cycles.first.startDate, start1);
      expect(cycles.first.dailyEntries.containsKey('2026-01-01'), isTrue);
      expect(cycles.first.dailyEntries.containsKey('2026-02-01'), isTrue);
    });
  });

  group('Observation Persistence & Sorting', () {
    test(
      'saveObservation preserves user-selected date and time in Observation.timestamp',
      () async {
        await db.createChart();

        final explicitDate = DateTime(2026, 7, 1, 8, 30);
        await db.saveObservation(
          date: explicitDate,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Morning observation',
        );

        final cycles = await db.streamCycles().first;
        final entry = cycles.first.dailyEntries['2026-07-01'];
        expect(entry, isNotNull);
        expect(entry!.observations.length, 1);
        expect(entry.observations.first.timestamp, equals(explicitDate));
      },
    );

    test(
      'saveObservation sorts multiple observations on the same day chronologically',
      () async {
        await db.createChart();

        final morningObs = DateTime(2026, 7, 1, 8, 30);
        final afternoonObs = DateTime(2026, 7, 1, 14, 0);

        // Save afternoon observation first
        await db.saveObservation(
          date: afternoonObs,
          sensation: Sensation.damp,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Afternoon observation',
        );

        // Then backfill morning observation
        await db.saveObservation(
          date: morningObs,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Morning observation',
        );

        final cycles = await db.streamCycles().first;
        final entry = cycles.first.dailyEntries['2026-07-01'];
        expect(entry, isNotNull);
        expect(entry!.observations.length, 2);
        expect(entry.observations[0].timestamp, equals(morningObs));
        expect(entry.observations[1].timestamp, equals(afternoonObs));
      },
    );
  });

  group('Supplement Database Operations', () {
    test('streamSupplements yields preset list for initial chart', () async {
      final supps = await db.streamSupplements().first;
      expect(supps.length, 20);
      expect(supps.any((s) => s.name == 'Prenatal'), isTrue);
      expect(supps.any((s) => s.name == "Men's Multivitamin"), isTrue);
    });

    test('saveSupplement adds new supplement and updates stream', () async {
      const newSupp = SupplementItem(
        id: 'supp_custom_1',
        name: 'Iron Glycinate',
        quantity: '25 mg',
        morningDose: 1,
      );

      await db.saveSupplement(newSupp);

      final supps = await db.streamSupplements().first;
      expect(supps.length, 21);
      expect(supps.any((s) => s.id == 'supp_custom_1'), isTrue);
    });

    test(
      'deleteSupplement removes supplement and does not re-seed when empty',
      () async {
        var supps = await db.streamSupplements().first;
        expect(supps.length, 20);

        // Delete one supplement
        await db.deleteSupplement('preset_prenatal');
        supps = await db.streamSupplements().first;
        expect(supps.length, 19);
        expect(supps.any((s) => s.id == 'preset_prenatal'), isFalse);

        // Delete all remaining supplements to verify empty list does not silently re-seed
        final remainingIds = supps.map((s) => s.id).toList();
        for (final id in remainingIds) {
          await db.deleteSupplement(id);
        }

        supps = await db.streamSupplements().first;
        expect(supps, isEmpty);
      },
    );

    test('resetDefaultSupplements restores all standard presets', () async {
      // Clear all supplements first
      final suppsInitial = await db.streamSupplements().first;
      for (final s in suppsInitial) {
        await db.deleteSupplement(s.id);
      }
      expect(await db.streamSupplements().first, isEmpty);

      // Reset to presets
      await db.resetDefaultSupplements();

      final suppsReset = await db.streamSupplements().first;
      expect(suppsReset.length, 20);
      expect(
        suppsReset.map((s) => s.name),
        containsAll(['Prenatal', 'CoQ10', 'Vitamin D', "Men's Multivitamin"]),
      );
    });

    test(
      'logSupplementDose records and toggles dose adherence per date and time of day',
      () async {
        final date = DateTime(2026, 8, 27);
        final dateKey = date.dateKey;

        var logs = await db.streamDailySupplementLogs().first;
        expect(logs[dateKey], isNull);

        // Log morning dose taken
        await db.logSupplementDose(
          date: date,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        logs = await db.streamDailySupplementLogs().first;
        expect(logs[dateKey], isNotNull);
        expect(
          logs[dateKey]!.isTaken('prenatal', SupplementTimeOfDay.morning),
          isTrue,
        );
        expect(
          logs[dateKey]!.isTaken('prenatal', SupplementTimeOfDay.evening),
          isFalse,
        );

        // Log morning dose untaken (toggle off)
        await db.logSupplementDose(
          date: date,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: false,
        );

        logs = await db.streamDailySupplementLogs().first;
        expect(
          logs[dateKey]!.isTaken('prenatal', SupplementTimeOfDay.morning),
          isFalse,
        );
      },
    );

    test(
      'streamSupplements and streamDailySupplementLogs update dynamically when active chart changes or unlinks',
      () async {
        final suppQueue = StreamQueue(
          db.streamSupplements().asBroadcastStream(),
        );
        final logQueue = StreamQueue(
          db.streamDailySupplementLogs().asBroadcastStream(),
        );

        expect(await suppQueue.next, hasLength(20));
        expect(await logQueue.next, isEmpty);
        await pumpEventQueue();

        // Unlink chart
        await db.unlinkChart();
        expect(await suppQueue.next, isEmpty);
        expect(await logQueue.next, isEmpty);

        // Create new chart
        await db.createChart();
        expect(await suppQueue.next, hasLength(20));
        expect(await logQueue.next, isEmpty);

        // Log dose on new chart
        final testDate = DateTime(2026, 8, 30);
        await db.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );
        final latestLogs = await logQueue.next;
        expect(latestLogs[testDate.dateKey], isNotNull);

        await suppQueue.cancel();
        await logQueue.cancel();
      },
    );

    test(
      'deleteChart cascades and removes supplements and supplement logs',
      () async {
        final activeId = db.currentChartId!;

        // Add custom supplement and log dose
        const customSupp = SupplementItem(
          id: 'custom_iron',
          name: 'Iron Glycinate',
          quantity: '25 mg',
          morningDose: 1,
        );
        await db.saveSupplement(customSupp);

        final testDate = DateTime(2026, 9, 1);
        await db.logSupplementDose(
          date: testDate,
          supplementId: 'custom_iron',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        final suppQueue = StreamQueue(
          db.streamSupplements().asBroadcastStream(),
        );
        final logQueue = StreamQueue(
          db.streamDailySupplementLogs().asBroadcastStream(),
        );

        final currentSupps = await suppQueue.next;
        expect(currentSupps.any((s) => s.id == 'custom_iron'), isTrue);
        final currentLogs = await logQueue.next;
        expect(currentLogs[testDate.dateKey], isNotNull);

        // Delete chart
        await db.deleteChart(activeId);

        // Streams should emit empty states
        expect(await suppQueue.next, isEmpty);
        expect(await logQueue.next, isEmpty);

        // Accessing the deleted chart ID directly should yield empty state without orphaned entries
        await db.setActiveChart(activeId);
        expect(await db.streamSupplements().first, isEmpty);
        expect(await db.streamDailySupplementLogs().first, isEmpty);

        await suppQueue.cancel();
        await logQueue.cancel();
      },
    );

    test(
      'streamSupplements supports re-subscription and forwards errors correctly',
      () async {
        final stream = db.streamSupplements();

        // 1. Initial subscription receives initial list of supplements
        final sub1 = stream.listen(null);
        await pumpEventQueue();
        await sub1.cancel();

        // 2. Re-subscription after cancellation
        final receivedLists = <List<SupplementItem>>[];
        Object? receivedError;
        final sub2 = stream.listen(
          (data) => receivedLists.add(data),
          onError: (Object err) {
            receivedError = err;
          },
        );
        await pumpEventQueue();

        // Should receive current items upon re-subscribing
        expect(receivedLists, hasLength(1));
        expect(receivedLists.first, hasLength(20));

        // 3. Error forwarding
        final testException = Exception('Test supplements error propagation');
        db.emitSupplementsError(testException);
        await pumpEventQueue();

        expect(receivedError, equals(testException));

        await sub2.cancel();
      },
    );

    test(
      'streamDailySupplementLogs supports re-subscription and forwards errors correctly',
      () async {
        final stream = db.streamDailySupplementLogs();

        // 1. Initial subscription receives initial logs map
        final sub1 = stream.listen(null);
        await pumpEventQueue();
        await sub1.cancel();

        // 2. Re-subscription after cancellation
        final receivedLogs = <Map<String, DailySupplementLog>>[];
        Object? receivedError;
        final sub2 = stream.listen(
          (data) => receivedLogs.add(data),
          onError: (Object err) {
            receivedError = err;
          },
        );
        await pumpEventQueue();

        // Should receive current logs upon re-subscribing
        expect(receivedLogs, hasLength(1));
        expect(receivedLogs.first, isEmpty);

        // 3. Error forwarding
        final testException = Exception('Test logs error propagation');
        db.emitDailySupplementLogsError(testException);
        await pumpEventQueue();

        expect(receivedError, equals(testException));

        await sub2.cancel();
      },
    );
  });

  group('DatabaseService Notification Preferences Cache', () {
    test(
      'latestNotificationPreferences returns current chart preferences synchronously',
      () async {
        final initialPrefs = db.latestNotificationPreferences;
        expect(initialPrefs, isNotNull);
        expect(initialPrefs!.fertilePatternAlerts, isTrue);
        expect(initialPrefs.partnerSupportReminders, isTrue);
        expect(initialPrefs.dailyLoggingReminder, isTrue);

        final byChartPrefs = db.getLatestNotificationPreferences(
          'mock_shared_chart',
        );
        expect(byChartPrefs, isNotNull);
        expect(byChartPrefs!.fertilePatternAlerts, isTrue);
      },
    );

    test(
      'updateNotificationPreferences synchronously updates cached preferences',
      () async {
        const chartId = 'mock_shared_chart';
        const updatedPrefs = NotificationPreferences(
          fertilePatternAlerts: false,
          partnerSupportReminders: false,
          dailyLoggingReminder: false,
          breastSelfExamReminder: false,
        );

        await db.updateNotificationPreferences(chartId, updatedPrefs);

        expect(db.getLatestNotificationPreferences(chartId), updatedPrefs);
        expect(db.latestNotificationPreferences, updatedPrefs);
      },
    );

    test(
      'updateChartReminderSettings synchronously updates cached preferences dailyLoggingReminder',
      () async {
        const chartId = 'mock_shared_chart';
        expect(
          db.getLatestNotificationPreferences(chartId)?.dailyLoggingReminder,
          isTrue,
        );

        await db.updateChartReminderSettings(chartId, false);

        expect(
          db.getLatestNotificationPreferences(chartId)?.dailyLoggingReminder,
          isFalse,
        );
        expect(db.latestNotificationPreferences?.dailyLoggingReminder, isFalse);
      },
    );

    test(
      'latestNotificationPreferences returns null after chart is deleted',
      () async {
        await db.deleteChart('mock_shared_chart');
        expect(db.currentChartId, isNull);
        expect(db.latestNotificationPreferences, isNull);
        expect(
          db.getLatestNotificationPreferences('mock_shared_chart'),
          isNull,
        );
      },
    );

    test(
      'latestNotificationPreferences returns null after leaving chart',
      () async {
        await db.invitePartner('partner@example.com');
        await db.leaveChart('mock_shared_chart');
        expect(db.currentChartId, isNull);
        expect(db.latestNotificationPreferences, isNull);
      },
    );

    test(
      'latestNotificationPreferences returns null when chart is unlinked',
      () async {
        await db.unlinkChart();
        expect(db.currentChartId, isNull);
        expect(db.latestNotificationPreferences, isNull);
      },
    );

    test(
      'getLatestNotificationPreferences returns null for non-existent chart',
      () {
        expect(
          db.getLatestNotificationPreferences('non_existent_chart_id'),
          isNull,
        );
      },
    );

    test(
      'setMockChartCollaborators updates chart userIds and emails and emits update',
      () async {
        db.setMockChartCollaborators(
          'mock_shared_chart',
          ['husband_uid'],
          emails: ['husband@example.com'],
        );

        final charts = await db.streamAvailableCharts().first;
        final chart = charts.firstWhere((c) => c['id'] == 'mock_shared_chart');
        expect(chart['userIds'], equals(['husband_uid']));
        expect(chart['emails'], equals(['husband@example.com']));
      },
    );

    test(
      'isolateSoleCollaboratorChart isolates mock_shared_chart to current user',
      () async {
        db.isolateSoleCollaboratorChart();

        final charts = await db.streamAvailableCharts().first;
        final chart = charts.firstWhere((c) => c['id'] == 'mock_shared_chart');
        expect(chart['userIds'], equals(['husband_uid']));
        expect(chart['emails'], equals(['husband@example.com']));
      },
    );
  });

  group('Invitation Operations', () {
    test(
      'declineInvitation gracefully completes without error when invitation is not found',
      () async {
        await expectLater(
          db.declineInvitation('non_existent_invite_id'),
          completes,
        );
      },
    );

    test(
      'declineInvitation successfully marks pending invitation as declined',
      () async {
        await db.invitePartner('husband@example.com');

        final pendingBefore = await db.getPendingInvitations();
        expect(pendingBefore.length, 1);
        expect(pendingBefore.first['invitationId'], 'husband@example.com');

        await db.declineInvitation('husband@example.com');

        final pendingAfter = await db.getPendingInvitations();
        expect(pendingAfter, isEmpty);
      },
    );

    test(
      'acceptInvitation: successfully accepts invite, joins chart, and triggers broadcasts',
      () async {
        await db.createChart();
        final chartId = db.currentChartId!;
        const partnerEmail = 'partner@example.com';
        await db.invitePartner(partnerEmail);

        // Partner signs in
        final partner = MockUser(uid: 'partner_uid', email: partnerEmail);
        db.setMockCurrentUser(partner);

        final authQueue = StreamQueue(db.authStateChanges);
        final chartsQueue = StreamQueue(db.streamAvailableCharts());
        final cyclesQueue = StreamQueue(db.streamCycles());

        // Consume initial emissions
        await authQueue.next;
        await chartsQueue.next;
        await cyclesQueue.next;

        await db.acceptInvitation(partnerEmail);

        // Verify streams broadcast
        expect(await authQueue.next, isNotNull);
        final updatedCharts = await chartsQueue.next;
        expect(updatedCharts.any((c) => c['id'] == chartId), isTrue);
        final chart = updatedCharts.firstWhere((c) => c['id'] == chartId);
        expect((chart['userIds'] as List).contains('partner_uid'), isTrue);
        expect((chart['emails'] as List).contains(partnerEmail), isTrue);
        expect(db.currentChartId, chartId);

        await authQueue.cancel();
        await chartsQueue.cancel();
        await cyclesQueue.cancel();
      },
    );

    test(
      'acceptInvitation: throws exception when invitation is not found matching Firebase semantics',
      () async {
        await expectLater(
          () => db.acceptInvitation('non_existent_invite'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invitation not found'),
            ),
          ),
        );
      },
    );

    test(
      'acceptInvitation: successfully accepts invite when user was not previously registered in _users',
      () async {
        await db.createChart();
        final chartId = db.currentChartId!;
        const newPartnerEmail = 'new_partner@example.com';
        await db.invitePartner(newPartnerEmail);

        // Switch to a brand new user not previously in _users map
        final newPartner = MockUser(
          uid: 'completely_new_uid',
          email: newPartnerEmail,
        );
        db.setMockCurrentUser(newPartner);

        // Accept invitation without throwing null assertion
        await db.acceptInvitation(newPartnerEmail);

        expect(db.currentChartId, chartId);
        final availableCharts = await db.streamAvailableCharts().first;
        expect(availableCharts.any((c) => c['id'] == chartId), isTrue);
      },
    );
  });

  group('Cycle CRUD, Modifications & Stream Ordering', () {
    test(
      'updateBipCodes recalculates daily entries and emits via streamCycles',
      () async {
        await db.createChart();
        final cycleStart = DateTime(2026, 8, 1);
        await db.startNewCycle(cycleStart, ['6C']);
        final cycleId = cycleStart.dateKey;

        // Add observation matching 6C
        await db.saveObservation(
          cycleId: cycleId,
          date: cycleStart.add(const Duration(days: 1)),
          sensation: Sensation.dry,
          stretch: Stretch.sticky,
          colors: [MucusColor.cloudy],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'matching BIP 6C',
        );

        var cycles = await db.streamCycles().first;
        var cycle = cycles.firstWhere((c) => c.id == cycleId);
        final obsKey = cycleStart.add(const Duration(days: 1)).dateKey;
        expect(cycle.bipCodes, equals(['6C']));
        expect(cycle.dailyEntries[obsKey]?.stampType, StampType.yellow);

        // Now update BIP codes to ['8Y']
        await db.updateBipCodes(cycleId, ['8Y']);

        cycles = await db.streamCycles().first;
        cycle = cycles.firstWhere((c) => c.id == cycleId);
        expect(cycle.bipCodes, equals(['8Y']));
        expect(cycle.dailyEntries[obsKey]?.stampType, StampType.whiteBaby);
      },
    );

    test(
      'updateCycleStartDate shifts cycle start date and reallocates entries',
      () async {
        await db.createChart();
        final start1 = DateTime(2026, 6, 1);
        final start2 = DateTime(2026, 7, 1);

        await db.startNewCycle(start1, ['6C']);
        await db.startNewCycle(start2, ['6C']);

        // Add observation on June 28 (belongs to cycle 1)
        final june28 = DateTime(2026, 6, 28);
        await db.saveObservation(
          date: june28,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'June 28',
        );

        var cycles = await db.streamCycles().first;
        var cycle1 = cycles.firstWhere((c) => c.id == start1.dateKey);
        var cycle2 = cycles.firstWhere((c) => c.id == start2.dateKey);
        expect(cycle1.dailyEntries.containsKey(june28.dateKey), isTrue);
        expect(cycle2.dailyEntries.containsKey(june28.dateKey), isFalse);

        // Shift second cycle start date to June 25
        final newStart2 = DateTime(2026, 6, 25);
        await db.updateCycleStartDate(start2.dateKey, newStart2);

        cycles = await db.streamCycles().first;
        expect(cycles.any((c) => c.id == start2.dateKey), isFalse);
        final updatedCycle2 = cycles.firstWhere(
          (c) => c.id == newStart2.dateKey,
        );
        cycle1 = cycles.firstWhere((c) => c.id == start1.dateKey);

        expect(updatedCycle2.startDate, newStart2);
        expect(updatedCycle2.dailyEntries.containsKey(june28.dateKey), isTrue);
        expect(cycle1.dailyEntries.containsKey(june28.dateKey), isFalse);
      },
    );

    test(
      'streamCycles maintains descending chronological order on add, update, and delete',
      () async {
        await db.createChart();

        final may = DateTime(2026, 5, 1);
        final june = DateTime(2026, 6, 1);
        final july = DateTime(2026, 7, 1);

        await db.startNewCycle(july, ['6C']);
        await db.startNewCycle(may, ['6C']);
        await db.startNewCycle(june, ['6C']);

        final cycles = await db.streamCycles().first;
        expect(cycles.length, 3);
        expect(cycles[0].startDate, july);
        expect(cycles[1].startDate, june);
        expect(cycles[2].startDate, may);

        final cycleQueue = StreamQueue(db.streamCycles());
        expect((await cycleQueue.next).length, 3);

        await db.deleteCycle(june.dateKey);
        final afterDelete = await cycleQueue.next;
        expect(afterDelete.length, 2);
        expect(afterDelete[0].startDate, july);
        expect(afterDelete[1].startDate, may);

        await cycleQueue.cancel();
      },
    );
  });

  group('Observation Operations, Boundary Cases & Notifications', () {
    test(
      'observation recorded exactly on cycle startDate maps to Day 1',
      () async {
        await db.createChart();
        final start = DateTime(2026, 8, 1);
        await db.startNewCycle(start, ['6C']);

        await db.saveObservation(
          date: start,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Day 1 entry',
        );

        final cycles = await db.streamCycles().first;
        final entry = cycles.first.dailyEntries[start.dateKey];
        expect(entry, isNotNull);
        expect(cycles.first.dayNumberFor(entry!.date), 1);
      },
    );

    test(
      'observation recorded prior to earliest cycle start date is handled without error',
      () async {
        await db.createChart();
        final start = DateTime(2026, 8, 10);
        await db.startNewCycle(start, ['6C']);

        final earlyDate = DateTime(2026, 8, 1);
        await expectLater(
          db.saveObservation(
            date: earlyDate,
            sensation: Sensation.dry,
            stretch: Stretch.none,
            colors: [],
            consistencies: [],
            bleeding: Bleeding.heavy,
            bleedingColor: 'R',
            painLevel: 0,
            painTypes: [],
            comment: 'Pre-cycle entry',
          ),
          completes,
        );

        final cycles = await db.streamCycles().first;
        expect(
          cycles.first.dailyEntries.containsKey(earlyDate.dateKey),
          isTrue,
        );
      },
    );

    test(
      'saveObservation preserves isVdrsExplicit flag on resolved daily entry',
      () async {
        await db.createChart();
        final date = DateTime(2026, 8, 5);

        await db.saveObservation(
          date: date,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Explicit VDRS test',
          isVdrsExplicit: true,
        );

        final cycles = await db.streamCycles().first;
        final entry = cycles.first.dailyEntries[date.dateKey];
        expect(entry, isNotNull);
        expect(entry!.observations.first.isVdrsExplicit, isTrue);
      },
    );

    test(
      'saveObservation triggers notifications when fertilePatternAlerts is true and suppresses when false',
      () async {
        final notif = InMemoryNotificationService();
        final originalNotifications = Services.notifications;
        Services.notifications = notif;
        addTearDown(() => Services.notifications = originalNotifications);
        await db.createChart();
        final chartId = db.currentChartId!;

        await db.updateNotificationPreferences(
          chartId,
          const NotificationPreferences(
            fertilePatternAlerts: true,
            partnerSupportReminders: true,
            dailyLoggingReminder: true,
          ),
        );

        final fertileDate = DateTime(2026, 8, 15);
        await db.saveObservation(
          date: fertileDate,
          sensation: Sensation.wet,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Peak Fertile mucus',
        );

        expect(notif.dispatchedNotifications.isNotEmpty, isTrue);
        final hasFertileOrPeak = notif.dispatchedNotifications.any(
          (n) =>
              n['id'] ==
                  InMemoryNotificationService.fertilePatternNotificationId ||
              n['id'] == InMemoryNotificationService.peakDayNotificationId ||
              n['id'] ==
                  InMemoryNotificationService.kindnessSupportNotificationId,
        );
        expect(hasFertileOrPeak, isTrue);

        // Disable notifications
        notif.dispatchedNotifications.clear();
        await db.updateNotificationPreferences(
          chartId,
          const NotificationPreferences(
            fertilePatternAlerts: false,
            partnerSupportReminders: false,
            dailyLoggingReminder: false,
          ),
        );

        final fertileDate2 = DateTime(2026, 8, 16);
        await db.saveObservation(
          date: fertileDate2,
          sensation: Sensation.wet,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Fertile mucus 2',
        );

        expect(notif.dispatchedNotifications, isEmpty);
      },
    );
  });

  group('Late Subscribers, Stream Behavior & Teardown', () {
    test(
      'late subscribers immediately receive current value across all 8 reactive streams',
      () async {
        final chartId = db.currentChartId!;

        // 1. streamCycles
        final cycles = await db.streamCycles().first;
        expect(cycles, isNotEmpty);

        // 2. streamSupplements
        final supplements = await db.streamSupplements().first;
        expect(supplements, isNotEmpty);

        // 3. streamDailySupplementLogs
        final logs = await db.streamDailySupplementLogs().first;
        expect(logs, isA<Map<String, DailySupplementLog>>());

        // 4. streamAvailableCharts
        final charts = await db.streamAvailableCharts().first;
        expect(charts, isNotEmpty);

        // 5. authStateChanges
        final user = await db.authStateChanges.first;
        expect(user, isNotNull);

        // 6. streamUserRole
        final role = await db.streamUserRole().first;
        expect(role, isNotNull);

        // 7. streamNotificationPreferences
        final prefs = await db.streamNotificationPreferences(chartId).first;
        expect(prefs, isNotNull);

        // 8. streamChartReminderEnabled
        final reminder = await db.streamChartReminderEnabled(chartId).first;
        expect(reminder, isA<bool>());
      },
    );

    test(
      're-subscription stability: subscribing, cancelling, and re-subscribing succeeds and concurrent listeners receive data',
      () async {
        final chartId = db.currentChartId!;

        // Test each reactive stream for re-subscription stability and concurrent listening
        final streams = <String, Stream<dynamic>>{
          'streamCycles': db.streamCycles(),
          'streamSupplements': db.streamSupplements(),
          'streamDailySupplementLogs': db.streamDailySupplementLogs(),
          'streamAvailableCharts': db.streamAvailableCharts(),
          'authStateChanges': db.authStateChanges,
          'streamUserRole': db.streamUserRole(),
          'streamNotificationPreferences': db.streamNotificationPreferences(chartId),
          'streamChartReminderEnabled': db.streamChartReminderEnabled(chartId),
        };

        for (final entry in streams.entries) {
          final s = entry.value;

          // First subscription - assert data reception
          dynamic val1;
          final sub1 = s.listen((val) => val1 = val);
          await pumpEventQueue();
          expect(val1, isNotNull, reason: '${entry.key} initial subscription received data');
          await sub1.cancel();

          // Second subscription - assert data reception on re-subscription
          dynamic val2;
          final sub2 = s.listen((val) => val2 = val);
          await pumpEventQueue();
          expect(val2, isNotNull, reason: '${entry.key} re-subscription received data');
          await sub2.cancel();

          // Concurrent multi-listener validation on the same stream instance
          dynamic concurrentVal1;
          dynamic concurrentVal2;
          final cSub1 = s.listen((val) => concurrentVal1 = val);
          final cSub2 = s.listen((val) => concurrentVal2 = val);
          await pumpEventQueue();
          expect(concurrentVal1, isNotNull, reason: '${entry.key} concurrent listener 1 received data');
          expect(concurrentVal2, isNotNull, reason: '${entry.key} concurrent listener 2 received data');
          await cSub1.cancel();
          await cSub2.cancel();
        }
      },
    );

    test(
      'dispose closes stream controllers and asserts active and late streams complete',
      () async {
        final testDb = InMemoryDatabaseService();
        final chartId = testDb.currentChartId!;

        final authDone = Completer<void>();
        final chartsDone = Completer<void>();
        final roleDone = Completer<void>();
        final cyclesDone = Completer<void>();
        final suppsDone = Completer<void>();
        final logsDone = Completer<void>();
        final prefsDone = Completer<void>();
        final reminderDone = Completer<void>();

        testDb.authStateChanges.listen((_) {}, onDone: authDone.complete);
        testDb.streamAvailableCharts().listen(
          (_) {},
          onDone: chartsDone.complete,
        );
        testDb.streamUserRole().listen((_) {}, onDone: roleDone.complete);
        testDb.streamCycles().listen((_) {}, onDone: cyclesDone.complete);
        testDb.streamSupplements().listen((_) {}, onDone: suppsDone.complete);
        testDb.streamDailySupplementLogs().listen(
          (_) {},
          onDone: logsDone.complete,
        );
        testDb.streamNotificationPreferences(chartId).listen(
          (_) {},
          onDone: prefsDone.complete,
        );
        testDb.streamChartReminderEnabled(chartId).listen(
          (_) {},
          onDone: reminderDone.complete,
        );

        var emittedAfterDispose = false;

        // Verify active streams complete when service is disposed (onDone path)
        testDb.dispose();

        await expectLater(authDone.future, completes);
        await expectLater(chartsDone.future, completes);
        await expectLater(roleDone.future, completes);
        await expectLater(cyclesDone.future, completes);
        await expectLater(suppsDone.future, completes);
        await expectLater(logsDone.future, completes);
        await expectLater(prefsDone.future, completes);
        await expectLater(reminderDone.future, completes);

        // Verify late subscribers on disposed service complete immediately (closed-controller guard path)
        final lateSub = testDb.streamCycles().listen((_) {
          emittedAfterDispose = true;
        });
        await pumpEventQueue();
        expect(emittedAfterDispose, isFalse);
        await lateSub.cancel();

        await expectLater(testDb.authStateChanges, emitsDone);
        await expectLater(testDb.streamAvailableCharts(), emitsDone);
        await expectLater(testDb.streamUserRole(), emitsDone);
        await expectLater(testDb.streamCycles(), emitsDone);
        await expectLater(testDb.streamSupplements(), emitsDone);
        await expectLater(testDb.streamDailySupplementLogs(), emitsDone);
        await expectLater(testDb.streamNotificationPreferences(chartId), emitsDone);
        await expectLater(testDb.streamChartReminderEnabled(chartId), emitsDone);
      },
    );

    test(
      'role stream synchronizes accurately across signOut, setMockCurrentUser, and signInWithGoogle',
      () async {
        final roleQueue = StreamQueue(db.streamUserRole());

        // Initial emission for default user (husband_uid -> 'husband')
        expect(await roleQueue.next, equals('husband'));

        // Sign out emits null
        await db.signOut();
        expect(await roleQueue.next, isNull);

        // Sign in with Google emits role ('wife' for new user)
        await db.signInWithGoogle();
        expect(await roleQueue.next, equals('wife'));

        // Switching mock user to wife_uid emits 'wife'
        final wife = MockUser(uid: 'wife_uid', email: 'wife@example.com');
        db.setMockCurrentUser(wife);
        expect(await roleQueue.next, equals('wife'));

        // Switching to husband emits 'husband'
        final husband = MockUser(uid: 'husband_uid', email: 'husband@example.com');
        db.setMockCurrentUser(husband);
        expect(await roleQueue.next, equals('husband'));

        // Switching mock user to null emits null
        db.setMockCurrentUser(null);
        expect(await roleQueue.next, isNull);

        await roleQueue.cancel();
      },
    );
  });

  group(
    'Parity Check Suite (InMemoryDatabaseService vs FirebaseDatabaseService)',
    () {
      test(
        'identical sequence of domain actions produces equivalent state snapshots',
        () async {
          final fakeDb = FakeFirebaseFirestore();
          final currentUser = FakeUser(
            uid: 'parity_user_uid',
            email: 'parity@example.com',
          );
          final fakeAuth = FakeFirebaseAuth(currentUser: currentUser);
          final fbService = FirebaseDatabaseService(auth: fakeAuth, db: fakeDb);
          final inMemService = InMemoryDatabaseService();
          inMemService.setMockCurrentUser(
            MockUser(uid: 'parity_user_uid', email: 'parity@example.com'),
          );

          // 1. Create a chart on both
          await inMemService.createChart();
          await fbService.createChart();

          final inMemChartId = inMemService.currentChartId!;
          final fbChartId = fbService.currentChartId!;

          // 2. Save observations (menses on days 1-3, dry on days 4-7, fertile peak mucus on day 8)
          final baseDate = DateTime(2026, 9, 1);
          for (int day = 0; day < 8; day++) {
            final date = baseDate.add(Duration(days: day));
            if (day < 3) {
              // Days 1-3: Menstruation
              await inMemService.saveObservation(
                date: date,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.heavy,
                bleedingColor: 'R',
                painLevel: 0,
                painTypes: [],
                comment: 'Menses day ${day + 1}',
              );
              await fbService.saveObservation(
                date: date,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.heavy,
                bleedingColor: 'R',
                painLevel: 0,
                painTypes: [],
                comment: 'Menses day ${day + 1}',
              );
            } else if (day < 7) {
              // Days 4-7: Dry
              await inMemService.saveObservation(
                date: date,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.none,
                bleedingColor: '',
                painLevel: 0,
                painTypes: [],
                comment: 'Dry day ${day + 1}',
              );
              await fbService.saveObservation(
                date: date,
                sensation: Sensation.dry,
                stretch: Stretch.none,
                colors: [],
                consistencies: [],
                bleeding: Bleeding.none,
                bleedingColor: '',
                painLevel: 0,
                painTypes: [],
                comment: 'Dry day ${day + 1}',
              );
            } else {
              // Day 8: Fertile Peak mucus
              await inMemService.saveObservation(
                date: date,
                sensation: Sensation.wet,
                stretch: Stretch.stretchy,
                colors: [MucusColor.clear],
                consistencies: [Consistency.lubricative],
                bleeding: Bleeding.none,
                bleedingColor: '',
                painLevel: 0,
                painTypes: [],
                comment: 'Peak day 8',
              );
              await fbService.saveObservation(
                date: date,
                sensation: Sensation.wet,
                stretch: Stretch.stretchy,
                colors: [MucusColor.clear],
                consistencies: [Consistency.lubricative],
                bleeding: Bleeding.none,
                bleedingColor: '',
                painLevel: 0,
                painTypes: [],
                comment: 'Peak day 8',
              );
            }
          }

          // 3. Update BIP codes
          final cyclesInMemBeforeBip = await inMemService.streamCycles().first;
          final cyclesFbBeforeBip = await fbService.streamCycles().first;
          expect(cyclesInMemBeforeBip.length, equals(cyclesFbBeforeBip.length));

          final activeInMemCycleId = cyclesInMemBeforeBip.first.id;
          final activeFbCycleId = cyclesFbBeforeBip.first.id;

          await inMemService.updateBipCodes(activeInMemCycleId, ['8Y']);
          await fbService.updateBipCodes(activeFbCycleId, ['8Y']);

          // 4. Save custom supplements and log doses (morning and evening)
          const customSupplement = SupplementItem(
            id: 'supp_omega3',
            name: 'Omega 3',
            quantity: '1000 mg',
            morningDose: 1,
            eveningDose: 1,
          );
          await inMemService.saveSupplement(customSupplement);
          await fbService.saveSupplement(customSupplement);

          await inMemService.logSupplementDose(
            date: baseDate,
            supplementId: 'supp_omega3',
            timeOfDay: SupplementTimeOfDay.morning,
            taken: true,
          );
          await fbService.logSupplementDose(
            date: baseDate,
            supplementId: 'supp_omega3',
            timeOfDay: SupplementTimeOfDay.morning,
            taken: true,
          );

          await inMemService.logSupplementDose(
            date: baseDate,
            supplementId: 'supp_omega3',
            timeOfDay: SupplementTimeOfDay.evening,
            taken: true,
          );
          await fbService.logSupplementDose(
            date: baseDate,
            supplementId: 'supp_omega3',
            timeOfDay: SupplementTimeOfDay.evening,
            taken: true,
          );

          // 5. Update notification preferences and chart reminder settings
          const newPrefs = NotificationPreferences(
            fertilePatternAlerts: false,
            partnerSupportReminders: true,
            dailyLoggingReminder: false,
          );
          await inMemService.updateNotificationPreferences(
            inMemChartId,
            newPrefs,
          );
          await fbService.updateNotificationPreferences(fbChartId, newPrefs);

          await inMemService.updateChartReminderSettings(inMemChartId, false);
          await fbService.updateChartReminderSettings(fbChartId, false);

          // Parity assertions
          final cyclesInMemory = await inMemService.streamCycles().first;
          final cyclesFirebase = await fbService.streamCycles().first;
          expect(cyclesInMemory.length, equals(cyclesFirebase.length));
          expect(
            cyclesInMemory.first.startDate,
            equals(cyclesFirebase.first.startDate),
          );
          expect(
            cyclesInMemory.first.bipCodes,
            equals(cyclesFirebase.first.bipCodes),
          );

          // Assert daily entry keys and VDRS codes match
          final inMemEntries = cyclesInMemory.first.dailyEntries;
          final fbEntries = cyclesFirebase.first.dailyEntries;
          expect(inMemEntries.keys.toSet(), equals(fbEntries.keys.toSet()));
          for (final key in inMemEntries.keys) {
            expect(
              inMemEntries[key]?.resolvedVdrsCode,
              equals(fbEntries[key]?.resolvedVdrsCode),
            );
          }

          // Assert supplement lists match
          final suppsInMem = await inMemService.streamSupplements().first;
          final suppsFb = await fbService.streamSupplements().first;
          expect(
            suppsInMem.map((s) => s.id).toSet(),
            equals(suppsFb.map((s) => s.id).toSet()),
          );
          expect(
            suppsInMem.firstWhere((s) => s.id == 'supp_omega3').name,
            equals(suppsFb.firstWhere((s) => s.id == 'supp_omega3').name),
          );

          // Assert daily supplement logs match
          final logsInMem = await inMemService
              .streamDailySupplementLogs()
              .first;
          final logsFb = await fbService.streamDailySupplementLogs().first;
          final logKey = baseDate.dateKey;
          expect(logsInMem.containsKey(logKey), isTrue);
          expect(logsFb.containsKey(logKey), isTrue);
          expect(
            logsInMem[logKey]!.isTaken(
              'supp_omega3',
              SupplementTimeOfDay.morning,
            ),
            equals(
              logsFb[logKey]!.isTaken(
                'supp_omega3',
                SupplementTimeOfDay.morning,
              ),
            ),
          );
          expect(
            logsInMem[logKey]!.isTaken(
              'supp_omega3',
              SupplementTimeOfDay.evening,
            ),
            equals(
              logsFb[logKey]!.isTaken(
                'supp_omega3',
                SupplementTimeOfDay.evening,
              ),
            ),
          );

          // Assert notification preferences match
          final prefsInMem = await inMemService
              .streamNotificationPreferences(inMemChartId)
              .first;
          final prefsFb = await fbService
              .streamNotificationPreferences(fbChartId)
              .first;
          expect(
            prefsInMem.fertilePatternAlerts,
            equals(prefsFb.fertilePatternAlerts),
          );
          expect(
            prefsInMem.partnerSupportReminders,
            equals(prefsFb.partnerSupportReminders),
          );
          expect(
            prefsInMem.dailyLoggingReminder,
            equals(prefsFb.dailyLoggingReminder),
          );
        },
      );
    },
  );
}
