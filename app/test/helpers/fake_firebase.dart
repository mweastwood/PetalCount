// ignore_for_file: subtype_of_sealed_class, prefer_initializing_formals, depend_on_referenced_packages

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart'
    as firestore_platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Fake Implementations for FirebaseAuth and FirebaseFirestore
// =============================================================================

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool isAnonymous;

  FakeUser({required this.uid, this.email, this.isAnonymous = false});
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
  final Map<String, Object> getDocErrors = {};
  final Map<String, FirebaseException> snapshotErrors = {};
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
    if (firestoreInstance.getDocErrors.containsKey(path)) {
      throw firestoreInstance.getDocErrors[path]!;
    }
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
            if (firestoreInstance.snapshotErrors.containsKey(path)) {
              controller.addError(firestoreInstance.snapshotErrors[path]!);
              return;
            }
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
  bool get exists => true;

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
