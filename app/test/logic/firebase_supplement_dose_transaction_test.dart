// ignore_for_file: subtype_of_sealed_class, prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/supplement.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';
import 'package:petal_count/logic/utils/date_utils.dart';

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> store = {};
  int transactionCount = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(this, collectionPath);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    transactionCount++;
    final transaction = FakeTransaction(this);
    return await transactionHandler(transaction);
  }
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
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final data = firestoreInstance.store[path];
    return FakeDocumentSnapshot<Map<String, dynamic>>(
      id: id,
      data: data != null ? Map<String, dynamic>.from(data) : null,
      reference: this,
    );
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    firestoreInstance.store[path] = Map<String, dynamic>.from(data);
  }
}

class FakeDocumentSnapshot<T extends Object?> extends Fake
    implements DocumentSnapshot<T> {
  @override
  final String id;
  final T? _data;
  @override
  final DocumentReference<T> reference;

  FakeDocumentSnapshot({
    required this.id,
    required T? data,
    required this.reference,
  }) : _data = data;

  @override
  bool get exists => _data != null;

  @override
  T? data() => _data;
}

class FakeTransaction extends Fake implements Transaction {
  final FakeFirebaseFirestore firestore;

  FakeTransaction(this.firestore);

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final data = firestore.store[documentReference.path];
    return FakeDocumentSnapshot<T>(
      id: documentReference.id,
      data: data != null ? Map<String, dynamic>.from(data) as T : null,
      reference: documentReference,
    );
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    firestore.store[documentReference.path] = Map<String, dynamic>.from(
      data as Map,
    );
    return this;
  }
}

void main() {
  const chartId = 'test_chart_123';
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseDatabaseService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirebaseDatabaseService(db: fakeFirestore);
    service.cachedChartId = chartId;
  });

  group('FirebaseDatabaseService.logSupplementDose transaction tests', () {
    final testDate = DateTime(2026, 9, 14);
    final dateKey = testDate.dateKey;
    final logDocPath = 'charts/$chartId/supplementLogs/$dateKey';

    test(
      'records initial dose within a transaction when no document exists',
      () async {
        expect(fakeFirestore.transactionCount, equals(0));
        expect(fakeFirestore.store[logDocPath], isNull);

        await service.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        expect(fakeFirestore.transactionCount, equals(1));
        final data = fakeFirestore.store[logDocPath];
        expect(data, isNotNull);
        expect(data!['date'], equals(dateKey));
        expect(
          data['takenDoses'],
          equals({
            'prenatal': ['morning'],
          }),
        );
      },
    );

    test('toggles an existing dose off within a transaction', () async {
      // Seed existing log with prenatal taken in the morning
      final initialLog = DailySupplementLog(
        date: testDate,
        takenDoses: {
          'prenatal': [SupplementTimeOfDay.morning],
        },
      );
      fakeFirestore.store[logDocPath] = initialLog.toMap();

      await service.logSupplementDose(
        date: testDate,
        supplementId: 'prenatal',
        timeOfDay: SupplementTimeOfDay.morning,
        taken: false,
      );

      expect(fakeFirestore.transactionCount, equals(1));
      final data = fakeFirestore.store[logDocPath];
      expect(data, isNotNull);
      expect(data!['takenDoses'], isEmpty);
    });

    test(
      'preserves multiple distinct supplements logged in succession for the same date',
      () async {
        await service.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        await service.logSupplementDose(
          date: testDate,
          supplementId: 'vitamin_d',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        await service.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.evening,
          taken: true,
        );

        expect(fakeFirestore.transactionCount, equals(3));
        final data = fakeFirestore.store[logDocPath];
        expect(data, isNotNull);
        final rawTaken = data!['takenDoses'] as Map;
        expect(rawTaken['prenatal'], containsAll(['morning', 'evening']));
        expect(rawTaken['vitamin_d'], containsAll(['morning']));

        // Verify deserializing through DailySupplementLog
        final log = DailySupplementLog.fromMap(data);
        expect(log.isTaken('prenatal', SupplementTimeOfDay.morning), isTrue);
        expect(log.isTaken('prenatal', SupplementTimeOfDay.evening), isTrue);
        expect(log.isTaken('vitamin_d', SupplementTimeOfDay.morning), isTrue);
        expect(log.isTaken('vitamin_d', SupplementTimeOfDay.evening), isFalse);
      },
    );

    test('does nothing when cachedChartId is null', () async {
      service.cachedChartId = null;

      await service.logSupplementDose(
        date: testDate,
        supplementId: 'prenatal',
        timeOfDay: SupplementTimeOfDay.morning,
        taken: true,
      );

      expect(fakeFirestore.transactionCount, equals(0));
      expect(fakeFirestore.store, isEmpty);
    });
  });
}
