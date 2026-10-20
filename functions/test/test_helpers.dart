import 'dart:async';
import 'package:functions/src/interop/firebase_admin.dart';

class MockAuthService implements AuthService {
  Future<DecodedIdToken> Function(String idToken)? onVerifyIdToken;
  Future<void> Function(String uid)? onDeleteUser;

  final List<String> verifiedTokens = [];
  final List<String> deletedUserIds = [];

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken) async {
    verifiedTokens.add(idToken);
    if (onVerifyIdToken != null) {
      return onVerifyIdToken!(idToken);
    }
    return DecodedIdToken(uid: idToken);
  }

  @override
  Future<void> deleteUser(String uid) async {
    deletedUserIds.add(uid);
    if (onDeleteUser != null) {
      await onDeleteUser!(uid);
    }
  }
}

class MockMessagingService implements MessagingService {
  @override
  dynamic get rawMessaging => null;

  Future<BatchResponse> Function(Map<String, dynamic> message)?
      onSendEachForMulticast;
  final List<Map<String, dynamic>> sentMessages = [];

  MockMessagingService({this.onSendEachForMulticast});

  @override
  Future<BatchResponse> sendEachForMulticast(
    Map<String, dynamic> message,
  ) async {
    sentMessages.add(message);
    if (onSendEachForMulticast != null) {
      return onSendEachForMulticast!(message);
    }
    final tokens = (message['tokens'] as List?) ?? const [];
    return BatchResponse(
      successCount: tokens.length,
      failureCount: 0,
      responses: List.generate(
        tokens.length,
        (_) => const SendResponse(success: true),
      ),
    );
  }
}

class MockFirestoreDatabase implements FirestoreDatabase {
  @override
  dynamic get rawDb => null;

  final Map<String, MockCollectionReference> collections = {};
  final List<DocumentReference> recursiveDeletedRefs = [];
  final List<List<DocumentReference>> getAllCalls = [];
  Future<List<DocumentSnapshot>> Function(List<DocumentReference> refs)?
      onGetAll;
  MockQuery Function(String collectionId)? onCollectionGroup;
  WriteBatch Function()? onBatch;

  @override
  MockCollectionReference collection(String path) {
    final cleanPath = path.replaceAll(RegExp(r'^/+|/+$'), '');
    return collections.putIfAbsent(
      cleanPath,
      () => MockCollectionReference(cleanPath, this),
    );
  }

  @override
  Query collectionGroup(String collectionId) {
    if (onCollectionGroup != null) {
      return onCollectionGroup!(collectionId);
    }
    return MockQuery();
  }

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    getAllCalls.add(List<DocumentReference>.from(refs));
    if (onGetAll != null) {
      return onGetAll!(refs);
    }
    return Future.wait(refs.map((r) => r.get()));
  }

  MockWriteBatch currentBatch = MockWriteBatch();
  final List<MockWriteBatch> committedBatches = [];

  @override
  WriteBatch batch() {
    if (onBatch != null) {
      final b = onBatch!();
      if (b is MockWriteBatch) committedBatches.add(b);
      return b;
    }
    currentBatch = MockWriteBatch(
      onCommit: () {
        committedBatches.add(currentBatch);
      },
    );
    return currentBatch;
  }

  @override
  Future<void> recursiveDelete(DocumentReference ref) async {
    recursiveDeletedRefs.add(ref);
  }
}

class MockCollectionReference extends MockQuery implements CollectionReference {
  final String path;
  final MockFirestoreDatabase? db;
  final Map<String, MockDocumentReference> documents = {};
  final List<String> docCalls = [];

  MockCollectionReference(this.path, [this.db]) {
    onGet = _defaultCollectionGet;
  }

  Future<QuerySnapshot> _defaultCollectionGet() async {
    if (cannedDocs != null) {
      var docs = cannedDocs!;
      if (limitCount != null && limitCount! >= 0 && docs.length > limitCount!) {
        docs = docs.take(limitCount!).toList();
      }
      return MockQuerySnapshot(docs);
    }
    var docs = documents.values
        .where((d) => d.isExisting && d.docData != null)
        .map((d) => MockDocumentSnapshot(d.id, d.docData, true, d))
        .toList();
    if (limitCount != null && limitCount! >= 0 && docs.length > limitCount!) {
      docs = docs.take(limitCount!).toList();
    }
    return MockQuerySnapshot(docs);
  }

  @override
  MockDocumentReference doc([String? id]) {
    final docId = id ?? 'mock_doc_${documents.length + 1}';
    docCalls.add(docId);
    return documents.putIfAbsent(
      docId,
      () => MockDocumentReference(docId, path: '$path/$docId', db: db),
    );
  }

  @override
  MockQuery limit(int count) {
    final q = super.limit(count);
    q.onGet ??= () async {
      final allDocsSnap = await get();
      return MockQuerySnapshot(allDocsSnap.docs.take(count).toList());
    };
    return q;
  }

  @override
  Future<QuerySnapshot> get() async {
    getCalls++;
    if (onGet != null) {
      return onGet!();
    }
    if (cannedDocs != null) {
      var docs = cannedDocs!;
      if (limitCount != null && limitCount! >= 0 && docs.length > limitCount!) {
        docs = docs.take(limitCount!).toList();
      }
      return MockQuerySnapshot(docs);
    }
    var docs = documents.values
        .where((d) => d.isExisting && d.docData != null)
        .map((d) => MockDocumentSnapshot(d.id, d.docData, true, d))
        .toList();
    if (limitCount != null && limitCount! >= 0 && docs.length > limitCount!) {
      docs = docs.take(limitCount!).toList();
    }
    return MockQuerySnapshot(docs);
  }
}

class MockQuery implements Query {
  final List<Map<String, dynamic>> whereConditions = [];
  final List<Map<String, String>> orderByClauses = [];
  int? limitCount;
  int getCalls = 0;
  final List<int> limitCalls = [];
  Future<QuerySnapshot> Function()? onGet;
  void Function(String field, String op, dynamic value)? onWhere;
  void Function(String field, String direction)? onOrderBy;
  void Function(int count)? onLimit;
  List<MockDocumentSnapshot>? cannedDocs;

  void _copyStateTo(MockQuery target) {
    target.whereConditions.addAll(whereConditions);
    target.orderByClauses.addAll(orderByClauses);
    target.limitCount = limitCount;
    target.onGet = onGet;
    target.onWhere = onWhere;
    target.onOrderBy = onOrderBy;
    target.onLimit = onLimit;
    target.cannedDocs = cannedDocs;
  }

  @override
  MockQuery where(String field, String op, dynamic value) {
    onWhere?.call(field, op, value);
    final q = MockQuery();
    _copyStateTo(q);
    q.whereConditions.add({'field': field, 'op': op, 'value': value});
    return q;
  }

  @override
  MockQuery orderBy(String field, [String direction = 'asc']) {
    onOrderBy?.call(field, direction);
    final q = MockQuery();
    _copyStateTo(q);
    q.orderByClauses.add({'field': field, 'direction': direction});
    return q;
  }

  @override
  MockQuery limit(int count) {
    limitCalls.add(count);
    onLimit?.call(count);
    final q = MockQuery();
    _copyStateTo(q);
    q.limitCount = count;
    return q;
  }

  @override
  Future<QuerySnapshot> get() async {
    getCalls++;
    if (onGet != null) {
      return onGet!();
    }
    var docs = cannedDocs ?? <MockDocumentSnapshot>[];
    if (limitCount != null && limitCount! >= 0 && docs.length > limitCount!) {
      docs = docs.take(limitCount!).toList();
    }
    return MockQuerySnapshot(docs);
  }
}

class MockQuerySnapshot implements QuerySnapshot {
  @override
  final List<DocumentSnapshot> docs;

  MockQuerySnapshot(this.docs);

  @override
  bool get empty => docs.isEmpty;

  @override
  int get size => docs.length;
}

class MockSetCall {
  final Map<String, dynamic> data;
  final bool merge;

  const MockSetCall({required this.data, required this.merge});
}

class MockDocumentReference implements DocumentReference {
  @override
  final String id;
  final String path;
  final MockFirestoreDatabase? db;
  Map<String, dynamic>? docData;
  bool isExisting = true;

  final Map<String, MockCollectionReference> subcollections = {};
  final List<Map<String, dynamic>> updateCalls = [];
  final List<MockSetCall> setCalls = [];
  int getCalls = 0;
  int deleteCalls = 0;

  Future<DocumentSnapshot> Function()? onGet;
  Future<void> Function(Map<String, dynamic> data, {required bool merge})?
      onSet;
  Future<void> Function(Map<String, dynamic> data)? onUpdate;

  MockDocumentReference(
    this.id, {
    this.path = '',
    this.db,
    this.docData,
    this.isExisting = true,
  });

  @override
  MockCollectionReference collection(String subPath) {
    if (db != null && path.isNotEmpty) {
      return db!.collection('$path/$subPath');
    }
    return subcollections.putIfAbsent(
      subPath,
      () => MockCollectionReference('$path/$subPath'),
    );
  }

  @override
  Future<DocumentSnapshot> get() async {
    getCalls++;
    if (onGet != null) {
      return onGet!();
    }
    return MockDocumentSnapshot(id, docData, isExisting, this);
  }

  @override
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {
    setCalls.add(
      MockSetCall(data: Map<String, dynamic>.from(data), merge: merge),
    );
    if (onSet != null) {
      await onSet!(data, merge: merge);
      return;
    }
    if (merge && docData != null) {
      docData = {...docData!, ...data};
    } else {
      docData = Map<String, dynamic>.from(data);
    }
    isExisting = true;
  }

  @override
  Future<void> update(Map<String, dynamic> data) async {
    updateCalls.add(Map<String, dynamic>.from(data));
    if (onUpdate != null) {
      await onUpdate!(data);
      return;
    }
    docData ??= {};
    for (final entry in data.entries) {
      if (entry.value == FieldValue.deleteToken) {
        docData!.remove(entry.key);
      } else if (entry.value is FieldValueArrayRemove) {
        final toRemove = (entry.value as FieldValueArrayRemove).elements;
        final existing = docData![entry.key];
        if (existing is List) {
          docData![entry.key] =
              existing.where((item) => !toRemove.contains(item)).toList();
        }
      } else {
        docData![entry.key] = entry.value;
      }
    }
  }

  @override
  Future<void> delete() async {
    deleteCalls++;
    isExisting = false;
    docData = null;
  }
}

class MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic>? _data;
  final bool _exists;
  @override
  final DocumentReference? ref;

  MockDocumentSnapshot(
    this.id,
    this._data, [
    this._exists = true,
    this.ref,
  ]);

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

class MockWriteBatch implements WriteBatch {
  final Map<DocumentReference, Map<String, dynamic>> setOperations = {};
  final Map<DocumentReference, Map<String, dynamic>> updateOperations = {};
  final List<DocumentReference> deletedRefs = [];
  final void Function()? onCommit;
  Future<void> Function()? onCommitAsync;
  int commitCount = 0;

  MockWriteBatch({this.onCommit, this.onCommitAsync});

  @override
  void set(
    DocumentReference ref,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    setOperations[ref] = Map<String, dynamic>.from(data);
    if (ref is MockDocumentReference) {
      ref.set(data, merge: merge);
    }
  }

  @override
  void update(DocumentReference ref, Map<String, dynamic> data) {
    updateOperations[ref] = Map<String, dynamic>.from(data);
    if (ref is MockDocumentReference) {
      ref.update(data);
    }
  }

  @override
  void delete(DocumentReference ref) {
    deletedRefs.add(ref);
    if (ref is MockDocumentReference) {
      ref.delete();
    }
  }

  @override
  Future<void> commit() async {
    commitCount++;
    if (onCommitAsync != null) {
      await onCommitAsync!();
    }
    onCommit?.call();
  }
}
