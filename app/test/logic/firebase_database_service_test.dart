// ignore_for_file: subtype_of_sealed_class, prefer_initializing_formals, depend_on_referenced_packages

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart'
    as firestore_platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/cycle.dart';
import 'package:petal_count/logic/models/daily_entry.dart';
import 'package:petal_count/logic/models/notification_preferences.dart';
import 'package:petal_count/logic/models/observation.dart';
import 'package:petal_count/logic/models/supplement.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';
import 'package:petal_count/logic/utils/date_utils.dart';

// =============================================================================
// Fake Implementations for FirebaseAuth and FirebaseFirestore
// =============================================================================

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;

  FakeUser({required this.uid, this.email});
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();

  FakeFirebaseAuth({User? currentUser}) : _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user;
    _authController.add(user);
  }

  @override
  Stream<User?> authStateChanges() => _authController.stream;

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> store = {};
  int _autoIdCounter = 1;

  final Map<
    String,
    List<StreamController<DocumentSnapshot<Map<String, dynamic>>>>
  >
  _docListeners = {};
  final Map<String, List<StreamController<QuerySnapshot<Map<String, dynamic>>>>>
  _queryListeners = {};

  String generateAutoId() => 'auto_doc_${_autoIdCounter++}';

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(this, collectionPath);
  }

  @override
  WriteBatch batch() => FakeWriteBatch(this);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = FakeTransaction(this);
    return await transactionHandler(transaction);
  }

  dynamic _applyFieldValue(dynamic currentVal, dynamic updateVal) {
    if (updateVal is FieldValue) {
      final dynamic delegate =
          firestore_platform.FieldValuePlatform.getDelegate(updateVal);
      final String typeStr = delegate.type.toString();
      if (typeStr.contains('arrayUnion')) {
        final list = (currentVal is List)
            ? List<dynamic>.from(currentVal)
            : <dynamic>[];
        final toAdd = delegate.value as List;
        for (final item in toAdd) {
          if (!list.contains(item)) {
            list.add(item);
          }
        }
        return list;
      } else if (typeStr.contains('arrayRemove')) {
        final list = (currentVal is List)
            ? List<dynamic>.from(currentVal)
            : <dynamic>[];
        final toRemove = delegate.value as List;
        list.removeWhere((item) => toRemove.contains(item));
        return list;
      } else if (typeStr.contains('serverTimestamp')) {
        return DateTime.now().toIso8601String();
      }
    }
    return updateVal;
  }

  Map<String, dynamic> _deepMerge(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    final result = Map<String, dynamic>.from(target);
    source.forEach((key, val) {
      if (val is FieldValue) {
        result[key] = _applyFieldValue(result[key], val);
      } else if (val is Map<String, dynamic> && result[key] is Map) {
        result[key] = _deepMerge(
          Map<String, dynamic>.from(result[key] as Map),
          val,
        );
      } else {
        result[key] = val;
      }
    });
    return result;
  }

  void setDoc(String path, Map<String, dynamic> data, {bool merge = false}) {
    if (merge && store.containsKey(path)) {
      store[path] = _deepMerge(store[path]!, data);
    } else {
      final processed = <String, dynamic>{};
      data.forEach((k, v) {
        processed[k] = _applyFieldValue(null, v);
      });
      store[path] = processed;
    }
    notifyPath(path);
  }

  void updateDoc(String path, Map<String, dynamic> data) {
    final current = store[path] ?? <String, dynamic>{};
    final updated = Map<String, dynamic>.from(current);
    data.forEach((key, val) {
      if (key.contains('.')) {
        final parts = key.split('.');
        Map<String, dynamic> target = updated;
        for (var i = 0; i < parts.length - 1; i++) {
          final part = parts[i];
          final existing = target[part];
          target = (existing is Map)
              ? Map<String, dynamic>.from(existing)
              : <String, dynamic>{};
          updated[part] = target;
        }
        target[parts.last] = _applyFieldValue(target[parts.last], val);
      } else {
        updated[key] = _applyFieldValue(updated[key], val);
      }
    });
    store[path] = updated;
    notifyPath(path);
  }

  void deleteDoc(String path) {
    store.remove(path);
    notifyPath(path);
  }

  void notifyPath(String path) {
    final docSubs = _docListeners[path];
    if (docSubs != null) {
      final docRef = FakeDocumentReference(this, path);
      final data = store[path];
      final snap = FakeDocumentSnapshot<Map<String, dynamic>>(
        id: docRef.id,
        data: data != null ? Map<String, dynamic>.from(data) : null,
        reference: docRef,
      );
      for (final controller in List.from(docSubs)) {
        if (!controller.isClosed) {
          controller.add(snap);
        }
      }
    }

    final lastSlash = path.lastIndexOf('/');
    if (lastSlash > 0) {
      final colPath = path.substring(0, lastSlash);
      final querySubs = _queryListeners[colPath];
      if (querySubs != null) {
        final query = FakeQuery(this, colPath);
        for (final controller in List.from(querySubs)) {
          if (!controller.isClosed) {
            query.get().then((snap) {
              if (!controller.isClosed) controller.add(snap);
            });
          }
        }
      }
    }
  }

  void registerDocListener(
    String path,
    StreamController<DocumentSnapshot<Map<String, dynamic>>> controller,
  ) {
    _docListeners.putIfAbsent(path, () => []).add(controller);
  }

  void unregisterDocListener(
    String path,
    StreamController<DocumentSnapshot<Map<String, dynamic>>> controller,
  ) {
    _docListeners[path]?.remove(controller);
  }

  void registerQueryListener(
    String colPath,
    StreamController<QuerySnapshot<Map<String, dynamic>>> controller,
  ) {
    _queryListeners.putIfAbsent(colPath, () => []).add(controller);
  }

  void unregisterQueryListener(
    String colPath,
    StreamController<QuerySnapshot<Map<String, dynamic>>> controller,
  ) {
    _queryListeners[colPath]?.remove(controller);
  }
}

class FakeQueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isLessThanOrEqualTo;
  final dynamic arrayContains;

  FakeQueryFilter({
    required this.field,
    this.isEqualTo,
    this.isLessThanOrEqualTo,
    this.arrayContains,
  });

  bool matches(Map<String, dynamic> data) {
    if (isEqualTo != null) {
      if (data[field] != isEqualTo) return false;
    }
    if (isLessThanOrEqualTo != null) {
      final val = data[field];
      if (val == null) return false;
      if (val is Comparable) {
        if (val.compareTo(isLessThanOrEqualTo) > 0) return false;
      } else if (val.toString().compareTo(isLessThanOrEqualTo.toString()) > 0) {
        return false;
      }
    }
    if (arrayContains != null) {
      final val = data[field];
      if (val is! List || !val.contains(arrayContains)) return false;
    }
    return true;
  }
}

class FakeQueryOrderBy {
  final String field;
  final bool descending;

  FakeQueryOrderBy(this.field, {this.descending = false});
}

class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final FakeFirebaseFirestore firestoreInstance;
  final String collectionPath;
  final List<FakeQueryFilter> filters;
  final List<FakeQueryOrderBy> orders;
  final int? limitCount;

  FakeQuery(
    this.firestoreInstance,
    this.collectionPath, {
    List<FakeQueryFilter>? filters,
    List<FakeQueryOrderBy>? orders,
    this.limitCount,
  }) : filters = filters ?? [],
       orders = orders ?? [];

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return FakeQuery(
      firestoreInstance,
      collectionPath,
      filters: [
        ...filters,
        FakeQueryFilter(
          field: field.toString(),
          isEqualTo: isEqualTo,
          isLessThanOrEqualTo: isLessThanOrEqualTo,
          arrayContains: arrayContains,
        ),
      ],
      orders: orders,
      limitCount: limitCount,
    );
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return FakeQuery(
      firestoreInstance,
      collectionPath,
      filters: filters,
      orders: [
        ...orders,
        FakeQueryOrderBy(field.toString(), descending: descending),
      ],
      limitCount: limitCount,
    );
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return FakeQuery(
      firestoreInstance,
      collectionPath,
      filters: filters,
      orders: orders,
      limitCount: limit,
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _evaluate() {
    final prefix = '$collectionPath/';
    final matchingDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final entry in firestoreInstance.store.entries) {
      if (entry.key.startsWith(prefix)) {
        final remainder = entry.key.substring(prefix.length);
        if (!remainder.contains('/')) {
          final data = Map<String, dynamic>.from(entry.value);
          bool allMatch = true;
          for (final filter in filters) {
            if (!filter.matches(data)) {
              allMatch = false;
              break;
            }
          }
          if (allMatch) {
            matchingDocs.add(
              FakeQueryDocumentSnapshot(
                id: remainder,
                data: data,
                reference: FakeDocumentReference(firestoreInstance, entry.key),
              ),
            );
          }
        }
      }
    }

    if (orders.isNotEmpty) {
      matchingDocs.sort((a, b) {
        for (final order in orders) {
          final valA = a.data()[order.field];
          final valB = b.data()[order.field];
          int cmp = 0;
          if (valA != null && valB != null && valA is Comparable) {
            cmp = valA.compareTo(valB);
          } else {
            cmp = (valA?.toString() ?? '').compareTo(valB?.toString() ?? '');
          }
          if (cmp != 0) {
            return order.descending ? -cmp : cmp;
          }
        }
        return 0;
      });
    }

    if (limitCount != null && matchingDocs.length > limitCount!) {
      return matchingDocs.sublist(0, limitCount!);
    }
    return matchingDocs;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return FakeQuerySnapshot(_evaluate());
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    late StreamController<QuerySnapshot<Map<String, dynamic>>> controller;
    controller =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast(
          onListen: () {
            firestoreInstance.registerQueryListener(collectionPath, controller);
            controller.add(FakeQuerySnapshot(_evaluate()));
          },
          onCancel: () {
            firestoreInstance.unregisterQueryListener(
              collectionPath,
              controller,
            );
          },
        );
    return controller.stream;
  }
}

class FakeCollectionReference extends FakeQuery
    implements CollectionReference<Map<String, dynamic>> {
  @override
  final String path;

  FakeCollectionReference(FakeFirebaseFirestore firestoreInstance, this.path)
    : super(firestoreInstance, path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? documentPath]) {
    final effectivePath = documentPath != null
        ? '$path/$documentPath'
        : '$path/${firestoreInstance.generateAutoId()}';
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
    firestoreInstance.setDoc(path, data, merge: options?.merge ?? false);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    firestoreInstance.updateDoc(path, Map<String, dynamic>.from(data));
  }

  @override
  Future<void> delete() async {
    firestoreInstance.deleteDoc(path);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> controller;
    controller =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast(
          onListen: () {
            firestoreInstance.registerDocListener(path, controller);
            final data = firestoreInstance.store[path];
            controller.add(
              FakeDocumentSnapshot<Map<String, dynamic>>(
                id: id,
                data: data != null ? Map<String, dynamic>.from(data) : null,
                reference: this,
              ),
            );
          },
          onCancel: () {
            firestoreInstance.unregisterDocListener(path, controller);
          },
        );
    return controller.stream;
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

class FakeWriteBatch implements WriteBatch {
  final FakeFirebaseFirestore firestore;
  final List<void Function()> _operations = [];

  FakeWriteBatch(this.firestore);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _operations.add(() {
      firestore.setDoc(
        document.path,
        Map<String, dynamic>.from(data as Map),
        merge: options?.merge ?? false,
      );
    });
  }

  @override
  void update<T>(DocumentReference<T> document, T data) {
    _operations.add(() {
      firestore.updateDoc(
        document.path,
        Map<String, dynamic>.from(data as Map),
      );
    });
  }

  @override
  void delete(DocumentReference document) {
    _operations.add(() {
      firestore.deleteDoc(document.path);
    });
  }

  @override
  Future<void> commit() async {
    for (final op in _operations) {
      op();
    }
  }
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
    firestore.setDoc(
      documentReference.path,
      Map<String, dynamic>.from(data as Map),
      merge: options?.merge ?? false,
    );
    return this;
  }

  @override
  Transaction update(
    DocumentReference documentReference,
    Map<Object, Object?> data,
  ) {
    firestore.updateDoc(
      documentReference.path,
      Map<String, dynamic>.from(data),
    );
    return this;
  }

  @override
  Transaction delete(DocumentReference documentReference) {
    firestore.deleteDoc(documentReference.path);
    return this;
  }
}

// =============================================================================
// Unit Tests Suite
// =============================================================================

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
  // Group 1: Partner Invitation Flow
  // ===========================================================================
  group('Group 1: Partner Invitation Lifecycle', () {
    const chartId = 'chart_abc';

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {
        'id': chartId,
        'userIds': ['user_123'],
        'emails': ['user@example.com'],
      };
    });

    test(
      'invitePartner: creates document in invitations with pending status and normalized email',
      () async {
        const partnerEmail = '  Partner@Example.COM ';
        await service.invitePartner(partnerEmail);

        final expectedDoc = fakeDb.store['invitations/partner@example.com'];
        expect(expectedDoc, isNotNull);
        expect(expectedDoc!['invitationId'], equals('partner@example.com'));
        expect(expectedDoc['senderUid'], equals('user_123'));
        expect(expectedDoc['senderEmail'], equals('user@example.com'));
        expect(expectedDoc['chartId'], equals(chartId));
        expect(expectedDoc['status'], equals('pending'));
        expect(expectedDoc['createdAt'], isNotNull);
      },
    );

    test(
      'invitePartner: throws exception when active session or chart is missing',
      () async {
        service.cachedChartId = null;
        expect(
          () => service.invitePartner('partner@example.com'),
          throwsA(isA<Exception>()),
        );

        service.cachedChartId = chartId;
        fakeAuth.currentUser = null;
        expect(
          () => service.invitePartner('partner@example.com'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'getPendingInvitations: queries pending invites matching user email',
      () async {
        fakeDb.store['invitations/user@example.com'] = {
          'invitationId': 'user@example.com',
          'senderUid': 'other_uid',
          'chartId': 'other_chart',
          'status': 'pending',
        };
        fakeDb.store['invitations/someone_else@example.com'] = {
          'invitationId': 'someone_else@example.com',
          'senderUid': 'other_uid',
          'chartId': 'other_chart',
          'status': 'pending',
        };
        fakeDb.store['invitations/declined@example.com'] = {
          'invitationId': 'user@example.com',
          'senderUid': 'other_uid',
          'chartId': 'declined_chart',
          'status': 'declined',
        };

        final pending = await service.getPendingInvitations();
        expect(pending.length, equals(1));
        expect(pending.first['chartId'], equals('other_chart'));
        expect(pending.first['status'], equals('pending'));
      },
    );

    test(
      'getPendingInvitations: returns empty list if user is null or email is null',
      () async {
        fakeAuth.currentUser = null;
        expect(await service.getPendingInvitations(), isEmpty);

        fakeAuth.currentUser = FakeUser(uid: 'no_email');
        expect(await service.getPendingInvitations(), isEmpty);
      },
    );

    test(
      'acceptInvitation: updates status, appends user to chart userIds, updates profile, and emits auth',
      () async {
        const inviteeEmail = 'user@example.com';
        const targetChartId = 'invited_chart_789';

        fakeDb.store['charts/$targetChartId'] = {
          'id': targetChartId,
          'userIds': ['original_owner'],
          'emails': ['owner@example.com'],
        };
        fakeDb.store['invitations/$inviteeEmail'] = {
          'invitationId': inviteeEmail,
          'chartId': targetChartId,
          'status': 'pending',
        };

        final authStream = service.authStateChanges;
        final emittedUsers = <User?>[];
        final sub = authStream.listen(emittedUsers.add);
        addTearDown(sub.cancel);

        await service.acceptInvitation(inviteeEmail);

        // Invitation status updated
        expect(
          fakeDb.store['invitations/$inviteeEmail']!['status'],
          equals('accepted'),
        );

        // Chart collaborators updated
        final chartData = fakeDb.store['charts/$targetChartId']!;
        expect(
          chartData['userIds'],
          containsAll(['original_owner', 'user_123']),
        );
        expect(
          chartData['emails'],
          containsAll(['owner@example.com', 'user@example.com']),
        );

        // User profile linked
        final userData = fakeDb.store['users/user_123']!;
        expect(userData['chartId'], equals(targetChartId));

        // Cached chartId updated
        expect(service.currentChartId, equals(targetChartId));
        await pumpEventQueue();
        expect(emittedUsers.isNotEmpty, isTrue);
      },
    );

    test(
      'acceptInvitation: throws exception when invitation is not found',
      () async {
        expect(
          () => service.acceptInvitation('non_existent@example.com'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'declineInvitation: updates status to declined and does not modify chart',
      () async {
        const inviteeEmail = 'user@example.com';
        const targetChartId = 'invited_chart_789';

        fakeDb.store['charts/$targetChartId'] = {
          'id': targetChartId,
          'userIds': ['original_owner'],
        };
        fakeDb.store['invitations/$inviteeEmail'] = {
          'invitationId': inviteeEmail,
          'chartId': targetChartId,
          'status': 'pending',
        };

        await service.declineInvitation(inviteeEmail);

        expect(
          fakeDb.store['invitations/$inviteeEmail']!['status'],
          equals('declined'),
        );
        final chartData = fakeDb.store['charts/$targetChartId']!;
        expect(chartData['userIds'], equals(['original_owner']));
        expect(fakeDb.store['users/user_123'], isNull);
      },
    );

    test(
      'declineInvitation: returns gracefully when invitation does not exist',
      () async {
        // Should not throw
        await service.declineInvitation('unknown@example.com');
      },
    );
  });

  // ===========================================================================
  // Group 2: Chart CRUD and Membership Management
  // ===========================================================================
  group('Group 2: Chart CRUD & Membership Management', () {
    test(
      'createChart: creates chart doc with default reminderEnabled, presets, and links user',
      () async {
        fakeDb.store['users/user_123'] = {
          'uid': 'user_123',
          'email': 'user@example.com',
          'timezone': 'America/New_York',
        };

        await service.createChart();

        final createdChartId = service.currentChartId;
        expect(createdChartId, isNotNull);

        final chartData = fakeDb.store['charts/$createdChartId'];
        expect(chartData, isNotNull);
        expect(chartData!['id'], equals(createdChartId));
        expect(chartData['userIds'], equals(['user_123']));
        expect(chartData['emails'], equals(['user@example.com']));
        expect(chartData['reminderEnabled'], isTrue);
        expect(chartData['timezone'], equals('America/New_York'));

        // Supplements populated
        final defaultPresets = SupplementPresets.defaultList;
        for (final preset in defaultPresets) {
          final suppDoc =
              fakeDb.store['charts/$createdChartId/supplements/${preset.id}'];
          expect(suppDoc, isNotNull);
          expect(suppDoc!['name'], equals(preset.name));
        }

        // User document updated
        final userDoc = fakeDb.store['users/user_123'];
        expect(userDoc!['chartId'], equals(createdChartId));
      },
    );

    test(
      'unlinkChart: unlinks chart from user doc and emits null currentChartId',
      () async {
        service.cachedChartId = 'active_chart_1';
        fakeDb.store['users/user_123'] = {'chartId': 'active_chart_1'};

        await service.unlinkChart();

        expect(service.currentChartId, isNull);
        expect(fakeDb.store['users/user_123']!['chartId'], isNull);
      },
    );

    test(
      'setActiveChart: sets active chart in user doc and emits update',
      () async {
        fakeDb.store['users/user_123'] = {'chartId': null};

        await service.setActiveChart('target_chart_456');

        expect(service.currentChartId, equals('target_chart_456'));
        expect(
          fakeDb.store['users/user_123']!['chartId'],
          equals('target_chart_456'),
        );
      },
    );

    test(
      'leaveChart: throws exception when user is sole collaborator',
      () async {
        const chartId = 'solo_chart';
        service.cachedChartId = chartId;
        fakeDb.store['charts/$chartId'] = {
          'id': chartId,
          'userIds': ['user_123'],
          'emails': ['user@example.com'],
        };

        expect(() => service.leaveChart(chartId), throwsA(isA<Exception>()));
      },
    );

    test(
      'leaveChart: removes collaborator and unlinks if active chart',
      () async {
        const chartId = 'shared_chart';
        service.cachedChartId = chartId;
        fakeDb.store['charts/$chartId'] = {
          'id': chartId,
          'userIds': ['user_123', 'partner_456'],
          'emails': ['user@example.com', 'partner@example.com'],
        };
        fakeDb.store['users/user_123'] = {'chartId': chartId};

        await service.leaveChart(chartId);

        final chartData = fakeDb.store['charts/$chartId']!;
        expect(chartData['userIds'], equals(['partner_456']));
        expect(chartData['emails'], equals(['partner@example.com']));
        expect(service.currentChartId, isNull);
        expect(fakeDb.store['users/user_123']!['chartId'], isNull);
      },
    );

    test('deleteChart: deletes chart doc and all subcollections', () async {
      const chartId = 'chart_to_delete';
      service.cachedChartId = chartId;

      fakeDb.store['charts/$chartId'] = {'id': chartId};
      fakeDb.store['charts/$chartId/cycles/2026-09-01'] = {'id': '2026-09-01'};
      fakeDb.store['charts/$chartId/cycles/2026-09-01/dailyEntries/2026-09-01'] =
          {'date': '2026-09-01'};
      fakeDb.store['charts/$chartId/supplements/supp_1'] = {'id': 'supp_1'};
      fakeDb.store['charts/$chartId/supplementLogs/2026-09-01'] = {
        'date': '2026-09-01',
      };
      fakeDb.store['users/user_123'] = {'chartId': chartId};

      await service.deleteChart(chartId);

      expect(fakeDb.store['charts/$chartId'], isNull);
      expect(fakeDb.store['charts/$chartId/cycles/2026-09-01'], isNull);
      expect(
        fakeDb
            .store['charts/$chartId/cycles/2026-09-01/dailyEntries/2026-09-01'],
        isNull,
      );
      expect(fakeDb.store['charts/$chartId/supplements/supp_1'], isNull);
      expect(fakeDb.store['charts/$chartId/supplementLogs/2026-09-01'], isNull);
      expect(service.currentChartId, isNull);
      expect(fakeDb.store['users/user_123']!['chartId'], isNull);
    });

    test(
      'streamAvailableCharts: streams charts where userIds contains user',
      () async {
        fakeDb.store['charts/c1'] = {
          'id': 'c1',
          'userIds': ['user_123'],
        };
        fakeDb.store['charts/c2'] = {
          'id': 'c2',
          'userIds': ['other_user'],
        };
        fakeDb.store['charts/c3'] = {
          'id': 'c3',
          'userIds': ['user_123', 'other_user'],
        };

        final charts = await service.streamAvailableCharts().first;
        expect(charts.length, equals(2));
        final ids = charts.map((c) => c['id']).toList();
        expect(ids, containsAll(['c1', 'c3']));
      },
    );
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
        final dailyEntries = prevDoc!['dailyEntries'] as Map;
        expect(dailyEntries.containsKey(c2Start.dateKey), isTrue);
      },
    );

    test(
      'updateBipCodes: recalculates cycle entries and updates cycle doc and dailyEntries',
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
        fakeDb.store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'] =
            entry.toMap();

        await service.updateBipCodes(dateKey, ['8Y']);

        final cycleDoc = fakeDb.store['charts/$chartId/cycles/$dateKey'];
        expect(cycleDoc!['bipCodes'], equals(['8Y']));
        final subDoc = fakeDb
            .store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'];
        expect(subDoc, isNotNull);
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
      'saveObservation: creates initial cycle if none exists and persists daily entry in subcollection',
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

        final subDoc = fakeDb
            .store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'];
        expect(subDoc, isNotNull);
        final obsList = subDoc!['observations'] as List;
        expect(obsList.length, equals(1));
        expect(obsList.first['comment'], equals('Testing observation'));
        expect(obsList.first['userRole'], equals('wife'));
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

        final subDoc = fakeDb
            .store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'];
        final obsId = (subDoc!['observations'] as List).first['id'].toString();

        await service.deleteObservation(
          cycleId: dateKey,
          date: testDate,
          observationId: obsId,
        );

        // Subcollection doc should be removed because no observations remain
        expect(
          fakeDb.store['charts/$chartId/cycles/$dateKey/dailyEntries/$dateKey'],
          isNull,
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
  });

  // ===========================================================================
  // Group 5: Supplement Formulary & Dose Logging
  // ===========================================================================
  group('Group 5: Supplement Formulary & Dose Logging', () {
    const chartId = 'supp_chart_1';

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {'id': chartId};
    });

    test(
      'saveSupplement and deleteSupplement: assert persistence and deletion',
      () async {
        const item = SupplementItem(
          id: 'vitamin_c',
          name: 'Vitamin C',
          quantity: '1 tablet',
          morningDose: 1,
        );

        await service.saveSupplement(item);
        final suppDoc = fakeDb.store['charts/$chartId/supplements/vitamin_c'];
        expect(suppDoc, isNotNull);
        expect(suppDoc!['name'], equals('Vitamin C'));

        await service.deleteSupplement('vitamin_c');
        expect(fakeDb.store['charts/$chartId/supplements/vitamin_c'], isNull);
      },
    );

    test('streamSupplements: streams supplement items in chart', () async {
      fakeDb.store['charts/$chartId/supplements/item1'] = {
        'id': 'item1',
        'name': 'Item 1',
        'quantity': '10mg',
        'morningDose': 1,
      };

      final supplements = await service.streamSupplements().first;
      expect(supplements.length, equals(1));
      expect(supplements.first.name, equals('Item 1'));
    });

    test(
      'resetDefaultSupplements: replaces existing supplements with default presets',
      () async {
        fakeDb.store['charts/$chartId/supplements/custom_supp'] = {
          'id': 'custom_supp',
          'name': 'Custom',
        };

        await service.resetDefaultSupplements();

        expect(fakeDb.store['charts/$chartId/supplements/custom_supp'], isNull);
        for (final preset in SupplementPresets.defaultList) {
          expect(
            fakeDb.store['charts/$chartId/supplements/${preset.id}'],
            isNotNull,
          );
        }
      },
    );

    test(
      'logSupplementDose: toggles dose in supplementLogs transaction',
      () async {
        final testDate = DateTime(2026, 9, 14);
        final dateKey = testDate.dateKey;

        await service.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        final logDoc = fakeDb.store['charts/$chartId/supplementLogs/$dateKey'];
        expect(logDoc, isNotNull);
        final takenDoses = logDoc!['takenDoses'] as Map;
        expect(takenDoses['prenatal'], contains('morning'));

        // Toggle off
        await service.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: false,
        );

        final updatedDoc =
            fakeDb.store['charts/$chartId/supplementLogs/$dateKey'];
        final updatedTaken = updatedDoc!['takenDoses'] as Map;
        expect(updatedTaken['prenatal'] ?? [], isEmpty);
      },
    );

    test(
      'streamDailySupplementLogs: streams daily supplement log map',
      () async {
        final testDate = DateTime(2026, 9, 14);
        final dateKey = testDate.dateKey;
        fakeDb.store['charts/$chartId/supplementLogs/$dateKey'] = {
          'date': dateKey,
          'takenDoses': {
            'iron': ['evening'],
          },
        };

        final logs = await service.streamDailySupplementLogs().first;
        expect(logs.containsKey(dateKey), isTrue);
        expect(
          logs[dateKey]!.isTaken('iron', SupplementTimeOfDay.evening),
          isTrue,
        );
      },
    );
  });

  // ===========================================================================
  // Group 6: Notification Settings & Profile State
  // ===========================================================================
  group('Group 6: Notification Settings & Profile State', () {
    const chartId = 'prefs_chart_1';

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {
        'id': chartId,
        'reminderEnabled': true,
      };
      fakeDb.store['users/user_123'] = {'uid': 'user_123', 'role': 'wife'};
    });

    test(
      'updateChartReminderSettings and streamChartReminderEnabled',
      () async {
        await service.updateChartReminderSettings(chartId, false);

        final chartDoc = fakeDb.store['charts/$chartId'];
        expect(chartDoc!['reminderEnabled'], isFalse);

        final isEnabled = await service
            .streamChartReminderEnabled(chartId)
            .first;
        expect(isEnabled, isFalse);
      },
    );

    test(
      'updateNotificationPreferences and streamNotificationPreferences',
      () async {
        const prefs = NotificationPreferences(
          dailyLoggingReminder: false,
          fertilePatternAlerts: true,
          partnerSupportReminders: false,
          breastSelfExamReminder: true,
        );

        await service.updateNotificationPreferences(chartId, prefs);

        expect(
          service.getLatestNotificationPreferences(chartId),
          equals(prefs),
        );
        expect(service.latestNotificationPreferences, equals(prefs));

        final streamed = await service
            .streamNotificationPreferences(chartId)
            .first;
        expect(streamed.fertilePatternAlerts, isTrue);
        expect(streamed.dailyLoggingReminder, isFalse);
        expect(streamed.partnerSupportReminders, isFalse);
        expect(streamed.breastSelfExamReminder, isTrue);
      },
    );

    test('updateUserRole and streamUserRole', () async {
      await service.updateUserRole('husband');

      expect(service.cachedRole, equals('husband'));
      final userDoc = fakeDb.store['users/user_123'];
      expect(userDoc!['role'], equals('husband'));

      final role = await service.streamUserRole().first;
      expect(role, equals('husband'));
    });

    test(
      'saveFcmToken and removeFcmToken: performs arrayUnion and arrayRemove',
      () async {
        await service.saveFcmToken('token_1');
        await service.saveFcmToken('token_2');

        final userDocAfterAdd = fakeDb.store['users/user_123']!;
        expect(
          userDocAfterAdd['fcmTokens'],
          containsAll(['token_1', 'token_2']),
        );

        await service.removeFcmToken('token_1');

        final userDocAfterRemove = fakeDb.store['users/user_123']!;
        expect(userDocAfterRemove['fcmTokens'], equals(['token_2']));
      },
    );

    test(
      'updateUserTimezone: updates timezone in users and active chart',
      () async {
        await service.updateUserTimezone('America/Chicago');

        expect(
          fakeDb.store['users/user_123']!['timezone'],
          equals('America/Chicago'),
        );
        expect(
          fakeDb.store['charts/$chartId']!['timezone'],
          equals('America/Chicago'),
        );
      },
    );
  });
}
