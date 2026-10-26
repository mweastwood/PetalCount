import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';

import '../helpers/fake_firebase.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FakeFirebaseAuth fakeAuth;
  late FakeUser currentUser;
  late FirebaseDatabaseService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    currentUser = FakeUser(uid: 'user_123', email: 'user@example.com');
    fakeAuth = FakeFirebaseAuth(currentUser: currentUser);
    service = FirebaseDatabaseService(auth: fakeAuth, db: fakeDb);
  });

  // ===========================================================================
  // Group 3: Cycle CRUD & Recalculation
  // ===========================================================================
  group('Group 3: Cycle CRUD & Recalculation', () {
    const chartId = 'cycle_chart_1';
    final startDate = DateTime(2026, 9, 1);

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {'id': chartId};
    });

    test(
      'startNewCycle: creates cycle document and triggers reallocation',
      () async {
        await service.startNewCycle(startDate, ['6C', '8Y']);

        final cycleDoc = fakeDb.store['charts/$chartId/cycles/2026-09-01'];
        expect(cycleDoc, isNotNull);
        expect(cycleDoc!['id'], equals('2026-09-01'));
        expect(cycleDoc['startDate'], equals('2026-09-01'));
        expect(cycleDoc['bipCodes'], equals(['6C', '8Y']));
      },
    );

    test(
      'deleteCycle: removes cycle document and its dailyEntries subcollection',
      () async {
        final dateKey = startDate.dateKey;
        fakeDb.store['charts/$chartId/cycles/$dateKey'] = {
          'id': dateKey,
          'startDate': dateKey,
        };
        fakeDb.store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'] =
            {'date': dateKey};

        await service.deleteCycle(dateKey);

        expect(fakeDb.store['charts/$chartId/cycles/$dateKey'], isNull);
        expect(
          fakeDb.store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'],
          isNull,
        );
      },
    );

    test(
      'updateCycleStartDate: deletes old cycle and creates new with updated start date',
      () async {
        final oldStart = DateTime(2026, 9, 1);
        final newStart = DateTime(2026, 9, 5);
        final cycle = Cycle(
          id: oldStart.dateKey,
          startDate: oldStart,
          bipCodes: ['6C'],
        );
        fakeDb.store['charts/$chartId/cycles/${oldStart.dateKey}'] = cycle
            .toMap();
        fakeDb.store['charts/$chartId/cycles/${oldStart.dateKey}/dailyEntries/${oldStart.dateKey}'] =
            {'date': oldStart.dateKey};

        await service.updateCycleStartDate(oldStart.dateKey, newStart);

        expect(
          fakeDb.store['charts/$chartId/cycles/${oldStart.dateKey}'],
          isNull,
        );
        expect(
          fakeDb
              .store['charts/$chartId/cycles/${oldStart.dateKey}/dailyEntries/${oldStart.dateKey}'],
          isNull,
        );
        final newDoc =
            fakeDb.store['charts/$chartId/cycles/${newStart.dateKey}'];
        expect(newDoc, isNotNull);
        expect(newDoc!['startDate'], equals(newStart.dateKey));
      },
    );

    test(
      'mergeCycleWithPrevious: merges entries into previous cycle and deletes target',
      () async {
        final c1Start = DateTime(2026, 8, 1);
        final c2Start = DateTime(2026, 9, 1);

        final c1 = Cycle(
          id: c1Start.dateKey,
          startDate: c1Start,
          endDate: DateTime(2026, 8, 31),
          bipCodes: ['6C'],
        );
        final c2 = Cycle(
          id: c2Start.dateKey,
          startDate: c2Start,
          bipCodes: ['6C'],
          dailyEntries: {
            c2Start.dateKey: DailyEntry(
              date: c2Start,
              resolvedVdrsCode: '',
              stampType: StampType.green,
              observations: [],
              painLevel: 0,
              painTypes: [],
              comments: '',
            ),
          },
        );

        fakeDb.store['charts/$chartId/cycles/${c1.id}'] = c1.toMap();
        fakeDb.store['charts/$chartId/cycles/${c2.id}'] = c2.toMap();
        fakeDb.store['charts/$chartId/cycles/${c2.id}/dailyEntries/${c2Start.dateKey}'] =
            c2.dailyEntries[c2Start.dateKey]!.toMap();

        await service.mergeCycleWithPrevious(c2.id);

        expect(fakeDb.store['charts/$chartId/cycles/${c2.id}'], isNull);
        expect(
          fakeDb
              .store['charts/$chartId/cycles/${c2.id}/dailyEntries/${c2Start.dateKey}'],
          isNull,
        );

        final prevDoc = fakeDb.store['charts/$chartId/cycles/${c1.id}'];
        expect(prevDoc, isNotNull);
        expect(prevDoc!['endDate'], isNull);
        final dailyEntries = prevDoc['dailyEntries'] as Map;
        expect(dailyEntries.containsKey(c2Start.dateKey), isTrue);
      },
    );

    test(
      'updateBipCodes: recalculates cycle entries and updates cycle doc dailyEntries map',
      () async {
        final dateKey = startDate.dateKey;
        final entry = DailyEntry(
          date: startDate,
          resolvedVdrsCode: '',
          stampType: StampType.green,
          observations: [],
          painLevel: 0,
          painTypes: [],
          comments: '',
        );
        final cycle = Cycle(
          id: dateKey,
          startDate: startDate,
          bipCodes: ['6C'],
          dailyEntries: {dateKey: entry},
        );

        fakeDb.store['charts/$chartId/cycles/$dateKey'] = cycle.toMap();

        await service.updateBipCodes(dateKey, ['8Y']);

        final cycleDoc = fakeDb.store['charts/$chartId/cycles/$dateKey'];
        expect(cycleDoc!['bipCodes'], equals(['8Y']));
        final dailyEntries = cycleDoc['dailyEntries'] as Map;
        expect(dailyEntries.containsKey(dateKey), isTrue);
        expect(
          fakeDb.store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'],
          isNull,
        );
      },
    );

    test(
      'streamCycles: emits cycles ordered descending by startDate',
      () async {
        final c1 = Cycle(id: '2026-08-01', startDate: DateTime(2026, 8, 1));
        final c2 = Cycle(id: '2026-09-01', startDate: DateTime(2026, 9, 1));

        fakeDb.store['charts/$chartId/cycles/2026-08-01'] = c1.toMap();
        fakeDb.store['charts/$chartId/cycles/2026-09-01'] = c2.toMap();

        final cycles = await service.streamCycles().first;
        expect(cycles.length, equals(2));
        expect(cycles.first.id, equals('2026-09-01'));
        expect(cycles.last.id, equals('2026-08-01'));
      },
    );
  });

  // ===========================================================================
  // Group 4: Observation Persistence
  // ===========================================================================
  group('Group 4: Observation Persistence', () {
    const chartId = 'obs_chart_1';
    final testDate = DateTime(2026, 9, 10);
    final dateKey = testDate.dateKey;

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {
        'id': chartId,
        'userIds': ['user_123'],
      };
      fakeDb.store['users/user_123'] = {'uid': 'user_123', 'role': 'wife'};
    });

    test(
      'saveObservation: creates initial cycle if none exists and persists daily entry in cycle dailyEntries map only',
      () async {
        await service.saveObservation(
          date: testDate,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [MucusColor.clear],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: 'none',
          painLevel: 0,
          painTypes: [],
          comment: 'Testing observation',
        );

        final cycleDoc = fakeDb.store['charts/$chartId/cycles/$dateKey'];
        expect(cycleDoc, isNotNull);
        final dailyEntries = cycleDoc!['dailyEntries'] as Map;
        expect(dailyEntries.containsKey(dateKey), isTrue);

        final entryMap = dailyEntries[dateKey] as Map;
        final obsList = entryMap['observations'] as List;
        expect(obsList.length, equals(1));
        expect(obsList.first['comment'], equals('Testing observation'));
        expect(obsList.first['userRole'], equals('wife'));

        expect(
          fakeDb.store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'],
          isNull,
        );
      },
    );

    test(
      'deleteObservation: deletes observation and cleans up empty daily entry',
      () async {
        await service.saveObservation(
          date: testDate,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: 'none',
          painLevel: 0,
          painTypes: [],
          comment: 'To be deleted',
        );

        final cycleDoc = fakeDb.store['charts/$chartId/cycles/$dateKey'];
        final dailyEntries = cycleDoc!['dailyEntries'] as Map;
        final entryMap = dailyEntries[dateKey] as Map;
        final obsId = (entryMap['observations'] as List).first['id'].toString();

        await service.deleteObservation(
          cycleId: dateKey,
          date: testDate,
          observationId: obsId,
        );

        final updatedCycle = fakeDb.store['charts/$chartId/cycles/$dateKey'];
        expect(
          (updatedCycle!['dailyEntries'] as Map).containsKey(dateKey),
          isFalse,
        );
      },
    );

    test(
      'saveObservation: returns early when currentUser or currentChartId is null',
      () async {
        service.cachedChartId = null;
        await service.saveObservation(
          date: testDate,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: 'none',
          painLevel: 0,
          painTypes: [],
          comment: 'No chart',
        );
        expect(fakeDb.store['charts/$chartId/cycles/$dateKey'], isNull);
      },
    );

    test(
      'saveObservation: before all existing cycles creates a new cycle starting on observation date (fixes #245)',
      () async {
        final sep1 = DateTime(2026, 9, 1);
        await service.startNewCycle(sep1, ['6C']);

        final aug25 = DateTime(2026, 8, 25);
        await service.saveObservation(
          date: aug25,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Backfilled observation before first cycle',
        );

        final cycles = await service.streamCycles().first;
        expect(cycles.length, 2);
        final preCycle = cycles.firstWhere(
          (c) => c.startDate == aug25,
          orElse: () =>
              throw TestFailure('Expected a cycle with startDate 2026-08-25'),
        );
        expect(preCycle.dailyEntries.containsKey('2026-08-25'), isTrue);
        expect(preCycle.dayNumberFor(aug25), equals(1));

        final subDoc = fakeDb
            .store['charts/$chartId/cycles/2026-08-25/dailyEntries/2026-08-25'];
        expect(subDoc, isNull);
      },
    );

    test(
      'saveObservation: pre-cycle observation inherits BIP codes from earliest existing cycle',
      () async {
        final sep1 = DateTime(2026, 9, 1);
        await service.startNewCycle(sep1, ['6C', '8Y']);

        final aug20 = DateTime(2026, 8, 20);
        await service.saveObservation(
          date: aug20,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Pre-cycle observation',
        );

        final cycles = await service.streamCycles().first;
        final preCycle = cycles.firstWhere((c) => c.startDate == aug20);
        expect(preCycle.bipCodes, equals(['6C', '8Y']));
      },
    );

    test(
      'saveObservation: pre-cycle observation falls back to default 6C when earliest existing cycle has empty BIP codes',
      () async {
        final sep1 = DateTime(2026, 9, 1);
        await service.startNewCycle(sep1, []);

        final aug20 = DateTime(2026, 8, 20);
        await service.saveObservation(
          date: aug20,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Pre-cycle observation with empty bipCodes',
        );

        final cycles = await service.streamCycles().first;
        final preCycle = cycles.firstWhere((c) => c.startDate == aug20);
        expect(preCycle.bipCodes, equals(['6C']));
      },
    );

    test(
      'saveObservation: pre-cycle heavy bleeding observation creates cycle with positive day index',
      () async {
        final sep1 = DateTime(2026, 9, 1);
        await service.startNewCycle(sep1, ['6C']);

        final aug28 = DateTime(2026, 8, 28);
        await service.saveObservation(
          date: aug28,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.heavy,
          bleedingColor: 'R',
          painLevel: 0,
          painTypes: [],
          comment: 'Backfilled period bleeding',
        );

        final cycles = await service.streamCycles().first;
        final preCycle = cycles.firstWhere(
          (c) => c.startDate == aug28,
          orElse: () =>
              throw TestFailure('Expected a cycle with startDate 2026-08-28'),
        );
        expect(preCycle.dailyEntries.containsKey('2026-08-28'), isTrue);
        expect(preCycle.dayNumberFor(aug28), equals(1));
      },
    );

    test(
      'saveObservation: multiple pre-cycle observations end up in same cycle and trigger daily entry reallocation',
      () async {
        final oct1 = DateTime(2026, 10, 1);
        await service.startNewCycle(oct1, ['6C']);

        final sep27 = DateTime(2026, 9, 27);
        final sep28 = DateTime(2026, 9, 28);

        await service.saveObservation(
          date: sep27,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'First pre-cycle obs',
        );

        await service.saveObservation(
          date: sep28,
          sensation: Sensation.damp,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Second pre-cycle obs',
        );

        final cycles = await service.streamCycles().first;
        final preCycle = cycles.firstWhere(
          (c) => c.startDate == sep27,
          orElse: () =>
              throw TestFailure('Expected a cycle with startDate 2026-09-27'),
        );
        expect(preCycle.dailyEntries.containsKey('2026-09-27'), isTrue);
        expect(preCycle.dailyEntries.containsKey('2026-09-28'), isTrue);
        expect(preCycle.dayNumberFor(sep28), equals(2));

        expect(
          fakeDb
              .store['charts/$chartId/cycles/2026-09-27/dailyEntries/2026-09-27'],
          isNull,
        );
        expect(
          fakeDb
              .store['charts/$chartId/cycles/2026-09-27/dailyEntries/2026-09-28'],
          isNull,
        );
      },
    );

    test(
      'saveObservation: reallocates misplaced daily entry to newly created pre-cycle and cleans up old cycle subcollection doc',
      () async {
        final sep10 = DateTime(2026, 9, 10);
        await service.startNewCycle(sep10, ['6C']);

        // Manually place a daily entry with date Sep 5 inside Sep 10 cycle (e.g. legacy data before fix)
        final sep5 = DateTime(2026, 9, 5);
        final legacyObs = Observation(
          id: 'legacy_obs_1',
          timestamp: sep5,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'user_123',
          comment: 'Misplaced observation before fix',
        );
        final legacyEntry = DailyEntry(
          date: sep5,
          resolvedVdrsCode: '',
          stampType: StampType.green,
          observations: [legacyObs],
          painLevel: 0,
          painTypes: const [],
          comments: 'Misplaced observation before fix',
        );
        final sep10Doc = fakeDb.store['charts/$chartId/cycles/2026-09-10']!;
        final sep10Entries = Map<String, dynamic>.from(
          sep10Doc['dailyEntries'] as Map? ?? {},
        );
        sep10Entries['2026-09-05'] = legacyEntry.toMap();
        fakeDb.store['charts/$chartId/cycles/2026-09-10'] = {
          ...sep10Doc,
          'dailyEntries': sep10Entries,
        };
        fakeDb.store['charts/$chartId/cycles/2026-09-10/dailyEntries/2026-09-05'] =
            legacyEntry.toMap();

        // Now save a pre-cycle observation on Sep 1
        final sep1 = DateTime(2026, 9, 1);
        await service.saveObservation(
          date: sep1,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: [],
          consistencies: [],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Pre-cycle observation triggering reallocation',
        );

        final cycles = await service.streamCycles().first;
        final preCycle = cycles.firstWhere((c) => c.startDate == sep1);
        final postCycle = cycles.firstWhere((c) => c.startDate == sep10);

        expect(preCycle.dailyEntries.containsKey('2026-09-01'), isTrue);
        expect(preCycle.dailyEntries.containsKey('2026-09-05'), isTrue);
        expect(postCycle.dailyEntries.containsKey('2026-09-05'), isFalse);

        expect(
          fakeDb
              .store['charts/$chartId/cycles/2026-09-01/dailyEntries/2026-09-05'],
          isNull,
        );
        expect(
          fakeDb
              .store['charts/$chartId/cycles/2026-09-10/dailyEntries/2026-09-05'],
          isNull,
        );
      },
    );
  });
}
