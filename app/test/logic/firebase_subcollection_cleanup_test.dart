// ignore_for_file: subtype_of_sealed_class, prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/cycle.dart';
import 'package:petal_count/logic/models/daily_entry.dart';
import 'package:petal_count/logic/models/observation.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';
import 'package:petal_count/logic/utils/date_utils.dart';

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> store = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(this, collectionPath);
  }

  @override
  WriteBatch batch() => FakeWriteBatch(this);
}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final FakeFirebaseFirestore firestoreInstance;
  @override
  final String path;

  FakeCollectionReference(this.firestoreInstance, this.path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? documentPath]) {
    final effectivePath = documentPath != null
        ? '$path/$documentPath'
        : '$path/auto_id';
    return FakeDocumentReference(firestoreInstance, effectivePath);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final prefix = '$path/';
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final entry in firestoreInstance.store.entries) {
      if (entry.key.startsWith(prefix)) {
        final remainder = entry.key.substring(prefix.length);
        if (!remainder.contains('/')) {
          docs.add(
            FakeQueryDocumentSnapshot(
              id: remainder,
              data: Map<String, dynamic>.from(entry.value),
              reference: FakeDocumentReference(firestoreInstance, entry.key),
            ),
          );
        }
      }
    }
    return FakeQuerySnapshot(docs);
  }
}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final FakeFirebaseFirestore firestoreInstance;
  @override
  final String path;

  FakeDocumentReference(this.firestoreInstance, this.path);

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(firestoreInstance, '$path/$collectionPath');
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    firestoreInstance.store[path] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> delete() async {
    firestoreInstance.store.remove(path);
  }
}

class FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot(this.docs);
}

class FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;
  @override
  final DocumentReference<Map<String, dynamic>> reference;

  FakeQueryDocumentSnapshot({
    required this.id,
    required Map<String, dynamic> data,
    required this.reference,
  }) : _data = data;

  @override
  Map<String, dynamic> data() => _data;
}

class FakeWriteBatch extends Fake implements WriteBatch {
  final FakeFirebaseFirestore firestoreInstance;
  final List<void Function()> _pending = [];

  FakeWriteBatch(this.firestoreInstance);

  @override
  void delete(DocumentReference document) {
    _pending.add(() {
      firestoreInstance.store.remove(document.path);
    });
  }

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _pending.add(() {
      firestoreInstance.store[document.path] = Map<String, dynamic>.from(
        data as Map,
      );
    });
  }

  @override
  void update<T>(DocumentReference<T> document, T data) {
    _pending.add(() {
      final current = firestoreInstance.store[document.path] ?? {};
      firestoreInstance.store[document.path] = {
        ...current,
        ...data as Map<String, dynamic>,
      };
    });
  }

  @override
  Future<void> commit() async {
    for (final op in _pending) {
      op();
    }
    _pending.clear();
  }
}

void main() {
  const chartId = 'test_chart_123';
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseDatabaseService service;

  DailyEntry createDailyEntry(DateTime date, {String comment = ''}) {
    return DailyEntry(
      date: date,
      resolvedVdrsCode: 'dry',
      stampType: StampType.green,
      observations: [
        Observation(
          id: 'obs_${date.millisecondsSinceEpoch}',
          timestamp: date,
          sensation: Sensation.dry,
          stretch: Stretch.none,
          colors: const [],
          consistencies: const [],
          bleeding: Bleeding.none,
          userId: 'user_1',
          comment: comment,
        ),
      ],
      painLevel: 0.0,
      painTypes: const [],
      comments: comment,
    );
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirebaseDatabaseService(db: fakeFirestore);
    service.cachedChartId = chartId;
  });

  group('updateCycleStartDate orphaned dailyEntries subcollection cleanup', () {
    test(
      'deletes both old cycle document and all documents within its dailyEntries subcollection',
      () async {
        final oldStartDate = DateTime(2026, 6, 1);
        final oldCycleId = oldStartDate.dateKey;
        final newStartDate = DateTime(2026, 6, 2);
        final newCycleId = newStartDate.dateKey;

        final entry1Date = DateTime(2026, 6, 3);
        final entry2Date = DateTime(2026, 6, 4);

        final entry1 = createDailyEntry(entry1Date, comment: 'Entry 1');
        final entry2 = createDailyEntry(entry2Date, comment: 'Entry 2');

        final initialCycle = Cycle(
          id: oldCycleId,
          startDate: oldStartDate,
          bipCodes: const [],
          dailyEntries: {
            entry1Date.dateKey: entry1,
            entry2Date.dateKey: entry2,
          },
        );

        // Populate old cycle doc and dailyEntries in Firestore
        final cycleDocPath = 'charts/$chartId/cycles/$oldCycleId';
        fakeFirestore.store[cycleDocPath] = initialCycle.toMap();
        fakeFirestore
            .store['$cycleDocPath/dailyEntries/${entry1Date.dateKey}'] = entry1
            .toMap();
        fakeFirestore
            .store['$cycleDocPath/dailyEntries/${entry2Date.dateKey}'] = entry2
            .toMap();

        expect(fakeFirestore.store.containsKey(cycleDocPath), isTrue);
        expect(
          fakeFirestore.store.containsKey(
            '$cycleDocPath/dailyEntries/${entry1Date.dateKey}',
          ),
          isTrue,
        );
        expect(
          fakeFirestore.store.containsKey(
            '$cycleDocPath/dailyEntries/${entry2Date.dateKey}',
          ),
          isTrue,
        );

        // Perform cycle start date update
        await service.updateCycleStartDate(oldCycleId, newStartDate);

        // Old cycle doc AND its dailyEntries subcollection documents must be completely deleted
        expect(
          fakeFirestore.store.containsKey(cycleDocPath),
          isFalse,
          reason: 'Old cycle document should be deleted',
        );
        expect(
          fakeFirestore.store.containsKey(
            '$cycleDocPath/dailyEntries/${entry1Date.dateKey}',
          ),
          isFalse,
          reason: 'Old dailyEntries entry 1 should be deleted',
        );
        expect(
          fakeFirestore.store.containsKey(
            '$cycleDocPath/dailyEntries/${entry2Date.dateKey}',
          ),
          isFalse,
          reason: 'Old dailyEntries entry 2 should be deleted',
        );

        // New cycle doc AND its dailyEntries subcollection documents must exist
        final newCycleDocPath = 'charts/$chartId/cycles/$newCycleId';
        expect(
          fakeFirestore.store.containsKey(newCycleDocPath),
          isTrue,
          reason: 'New cycle document should exist',
        );
        expect(
          fakeFirestore.store.containsKey(
            '$newCycleDocPath/dailyEntries/${entry1Date.dateKey}',
          ),
          isTrue,
          reason: 'New dailyEntries entry 1 should be populated',
        );
        expect(
          fakeFirestore.store.containsKey(
            '$newCycleDocPath/dailyEntries/${entry2Date.dateKey}',
          ),
          isTrue,
          reason: 'New dailyEntries entry 2 should be populated',
        );
      },
    );

    test('does not delete when cycleId does not change', () async {
      final startDate = DateTime(2026, 6, 1);
      final cycleId = startDate.dateKey;
      final entryDate = DateTime(2026, 6, 3);
      final entry = createDailyEntry(entryDate);

      final cycle = Cycle(
        id: cycleId,
        startDate: startDate,
        bipCodes: const [],
        dailyEntries: {entryDate.dateKey: entry},
      );

      final cycleDocPath = 'charts/$chartId/cycles/$cycleId';
      fakeFirestore.store[cycleDocPath] = cycle.toMap();
      fakeFirestore.store['$cycleDocPath/dailyEntries/${entryDate.dateKey}'] =
          entry.toMap();

      // Update with same start date
      await service.updateCycleStartDate(cycleId, startDate);

      expect(fakeFirestore.store.containsKey(cycleDocPath), isTrue);
      expect(
        fakeFirestore.store.containsKey(
          '$cycleDocPath/dailyEntries/${entryDate.dateKey}',
        ),
        isTrue,
      );
    });
  });

  group('_reallocateAndRecalculate migrated dailyEntries subcollection pruning', () {
    test(
      'removes migrated daily entries from source cycle subcollection when shifted to target cycle',
      () async {
        final cycle1Start = DateTime(2026, 6, 1);
        final cycle2Start = DateTime(2026, 6, 15);

        final june5 = DateTime(2026, 6, 5);
        final june20 = DateTime(2026, 6, 20);

        final entryJune5 = createDailyEntry(june5, comment: 'Cycle 1 entry');
        final entryJune20 = createDailyEntry(june20, comment: 'Migrated entry');

        // Simulate initial state where June 20 is erroneously filed under Cycle 1 (e.g. before Cycle 2 was added)
        final cycle1 = Cycle(
          id: cycle1Start.dateKey,
          startDate: cycle1Start,
          bipCodes: const [],
          dailyEntries: {
            june5.dateKey: entryJune5,
            june20.dateKey: entryJune20,
          },
        );

        final cycle2 = Cycle(
          id: cycle2Start.dateKey,
          startDate: cycle2Start,
          bipCodes: const [],
          dailyEntries: const {},
        );

        final c1DocPath = 'charts/$chartId/cycles/${cycle1Start.dateKey}';
        final c2DocPath = 'charts/$chartId/cycles/${cycle2Start.dateKey}';

        fakeFirestore.store[c1DocPath] = cycle1.toMap();
        fakeFirestore.store['$c1DocPath/dailyEntries/${june5.dateKey}'] =
            entryJune5.toMap();
        fakeFirestore.store['$c1DocPath/dailyEntries/${june20.dateKey}'] =
            entryJune20.toMap();

        fakeFirestore.store[c2DocPath] = cycle2.toMap();

        // Run reallocation
        await service.reallocateAndRecalculate(chartId);

        // Cycle 1 dailyEntries subcollection: June 5 remains, June 20 must be DELETED
        expect(
          fakeFirestore.store.containsKey(
            '$c1DocPath/dailyEntries/${june5.dateKey}',
          ),
          isTrue,
          reason: 'June 5 should remain under Cycle 1',
        );
        expect(
          fakeFirestore.store.containsKey(
            '$c1DocPath/dailyEntries/${june20.dateKey}',
          ),
          isFalse,
          reason:
              'June 20 must be pruned from Cycle 1 subcollection after migrating to Cycle 2',
        );

        // Cycle 2 dailyEntries subcollection: June 20 must be present
        expect(
          fakeFirestore.store.containsKey(
            '$c2DocPath/dailyEntries/${june20.dateKey}',
          ),
          isTrue,
          reason: 'June 20 must exist in Cycle 2 subcollection',
        );

        // Cycle 1 document dailyEntries map should also only contain June 5
        final c1Data = fakeFirestore.store[c1DocPath]!;
        final c1Entries = c1Data['dailyEntries'] as Map;
        expect(c1Entries.containsKey(june5.dateKey), isTrue);
        expect(c1Entries.containsKey(june20.dateKey), isFalse);

        // Cycle 2 document dailyEntries map should contain June 20
        final c2Data = fakeFirestore.store[c2DocPath]!;
        final c2Entries = c2Data['dailyEntries'] as Map;
        expect(c2Entries.containsKey(june20.dateKey), isTrue);
      },
    );

    test(
      'preserves all entries when no migration across boundaries occurs',
      () async {
        final cycle1Start = DateTime(2026, 6, 1);
        final cycle2Start = DateTime(2026, 6, 15);

        final june5 = DateTime(2026, 6, 5);
        final june18 = DateTime(2026, 6, 18);

        final entryJune5 = createDailyEntry(june5);
        final entryJune18 = createDailyEntry(june18);

        final cycle1 = Cycle(
          id: cycle1Start.dateKey,
          startDate: cycle1Start,
          bipCodes: const [],
          dailyEntries: {june5.dateKey: entryJune5},
        );

        final cycle2 = Cycle(
          id: cycle2Start.dateKey,
          startDate: cycle2Start,
          bipCodes: const [],
          dailyEntries: {june18.dateKey: entryJune18},
        );

        final c1DocPath = 'charts/$chartId/cycles/${cycle1Start.dateKey}';
        final c2DocPath = 'charts/$chartId/cycles/${cycle2Start.dateKey}';

        fakeFirestore.store[c1DocPath] = cycle1.toMap();
        fakeFirestore.store['$c1DocPath/dailyEntries/${june5.dateKey}'] =
            entryJune5.toMap();

        fakeFirestore.store[c2DocPath] = cycle2.toMap();
        fakeFirestore.store['$c2DocPath/dailyEntries/${june18.dateKey}'] =
            entryJune18.toMap();

        await service.reallocateAndRecalculate(chartId);

        expect(
          fakeFirestore.store.containsKey(
            '$c1DocPath/dailyEntries/${june5.dateKey}',
          ),
          isTrue,
        );
        expect(
          fakeFirestore.store.containsKey(
            '$c2DocPath/dailyEntries/${june18.dateKey}',
          ),
          isTrue,
        );
      },
    );
  });
}
