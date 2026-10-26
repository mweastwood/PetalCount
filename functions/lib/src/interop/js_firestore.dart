import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'abstract_admin.dart';
import 'js_bridge_helpers.dart';

class JsFirestoreDatabase implements FirestoreDatabase {
  final dynamic _db;
  final js.JsObject _adminRef;

  JsFirestoreDatabase(this._db, this._adminRef);

  @override
  dynamic get rawDb => _db;

  @override
  CollectionReference collection(String path) {
    final col = _db is js.JsObject
        ? _db.callMethod('collection', [path])
        : js_util.callMethod(_db, 'collection', [path]);
    return JsCollectionReference(col, _adminRef);
  }

  @override
  Query collectionGroup(String collectionId) {
    final q = _db is js.JsObject
        ? _db.callMethod('collectionGroup', [collectionId])
        : js_util.callMethod(_db, 'collectionGroup', [collectionId]);
    return JsQuery(q, _adminRef);
  }

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    if (refs.isEmpty) return <DocumentSnapshot>[];
    final hasGetAll = _db is js.JsObject
        ? _db.hasProperty('getAll')
        : js_util.hasProperty(_db, 'getAll');
    if (!hasGetAll) {
      return Future.wait(refs.map((r) => r.get()));
    }
    final jsRefs =
        refs.map((r) => (r as JsDocumentReference).rawJsRef).toList();
    final promise = _db is js.JsObject
        ? _db.callMethod('getAll', jsRefs)
        : js_util.callMethod(
            _db,
            'getAll',
            jsRefs.map(unwrapJsObject).toList(),
          );
    final rawSnaps = await safePromiseToFuture(promise);
    final snapsList = rawSnaps as List?;
    if (snapsList == null) return <DocumentSnapshot>[];
    return snapsList
        .map((snap) => JsDocumentSnapshot(snap, _adminRef))
        .toList();
  }

  @override
  WriteBatch batch() {
    final b = _db is js.JsObject
        ? _db.callMethod('batch')
        : js_util.callMethod(_db, 'batch', []);
    return JsWriteBatch(b, _adminRef);
  }

  @override
  Future<void> recursiveDelete(DocumentReference ref) async {
    final jsRef = (ref as JsDocumentReference).rawJsRef;
    if (js_util.hasProperty(_db, 'recursiveDelete')) {
      final promise = _db is js.JsObject
          ? _db.callMethod('recursiveDelete', [jsRef])
          : js_util.callMethod(_db, 'recursiveDelete', [jsRef]);
      await safePromiseToFuture(promise);
    } else {
      await ref.delete();
    }
  }
}

class JsCollectionReference extends JsQuery implements CollectionReference {
  JsCollectionReference(super.rawQuery, super.adminRef);

  @override
  DocumentReference doc([String? id]) {
    final docRef = id != null
        ? (rawQuery is js.JsObject
            ? rawQuery.callMethod('doc', [id])
            : js_util.callMethod(rawQuery, 'doc', [id]))
        : (rawQuery is js.JsObject
            ? rawQuery.callMethod('doc')
            : js_util.callMethod(rawQuery, 'doc', []));
    return JsDocumentReference(docRef, adminRef);
  }
}

class JsQuery implements Query {
  final dynamic rawQuery;
  final js.JsObject adminRef;

  JsQuery(this.rawQuery, this.adminRef);

  @override
  Query where(String field, String op, dynamic value) {
    final jsVal = convertValueForJs(value, adminRef);
    final nextQ = rawQuery is js.JsObject
        ? rawQuery.callMethod('where', [field, op, jsVal])
        : js_util.callMethod(rawQuery, 'where', [field, op, jsVal]);
    return JsQuery(nextQ, adminRef);
  }

  @override
  Query orderBy(String field, [String direction = 'asc']) {
    final nextQ = rawQuery is js.JsObject
        ? rawQuery.callMethod('orderBy', [field, direction])
        : js_util.callMethod(rawQuery, 'orderBy', [field, direction]);
    return JsQuery(nextQ, adminRef);
  }

  @override
  Query limit(int count) {
    final nextQ = rawQuery is js.JsObject
        ? rawQuery.callMethod('limit', [count])
        : js_util.callMethod(rawQuery, 'limit', [count]);
    return JsQuery(nextQ, adminRef);
  }

  @override
  Future<QuerySnapshot> get() async {
    final promise = rawQuery is js.JsObject
        ? rawQuery.callMethod('get')
        : js_util.callMethod(rawQuery, 'get', []);
    final snap = await safePromiseToFuture(promise);
    return JsQuerySnapshot(snap, adminRef);
  }
}

class JsQuerySnapshot implements QuerySnapshot {
  final dynamic _snap;
  final js.JsObject _adminRef;

  JsQuerySnapshot(this._snap, this._adminRef);

  @override
  bool get empty {
    final dynamic docsProp = _snap is js.JsObject
        ? _snap['docs']
        : js_util.getProperty(_snap, 'docs');
    final dynamic emptyProp = _snap is js.JsObject
        ? _snap['empty']
        : js_util.getProperty(_snap, 'empty');
    if (emptyProp is bool) return emptyProp;
    if (docsProp is List) return docsProp.isEmpty;
    return true;
  }

  @override
  int get size {
    if (_snap is js.JsObject) {
      return (_snap['size'] as num?)?.toInt() ?? docs.length;
    }
    return (js_util.getProperty(_snap, 'size') as num?)?.toInt() ?? docs.length;
  }

  @override
  List<DocumentSnapshot> get docs {
    final dynamic rawDocs = _snap is js.JsObject
        ? _snap['docs']
        : js_util.getProperty(_snap, 'docs');
    final docsList = rawDocs as List?;
    if (docsList == null) return [];
    return docsList.map((d) => JsDocumentSnapshot(d, _adminRef)).toList();
  }
}

class JsDocumentReference implements DocumentReference, RawJsReferenceHolder {
  @override
  final dynamic rawJsRef;
  final js.JsObject adminRef;

  JsDocumentReference(this.rawJsRef, this.adminRef);

  @override
  String get id {
    if (rawJsRef is js.JsObject) return (rawJsRef['id'] as String?) ?? '';
    return (js_util.getProperty(rawJsRef, 'id') as String?) ?? '';
  }

  @override
  CollectionReference collection(String path) {
    final col = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('collection', [path])
        : js_util.callMethod(rawJsRef, 'collection', [path]);
    return JsCollectionReference(col, adminRef);
  }

  @override
  Future<DocumentSnapshot> get() async {
    final promise = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('get')
        : js_util.callMethod(rawJsRef, 'get', []);
    final snap = await safePromiseToFuture(promise);
    return JsDocumentSnapshot(snap, adminRef);
  }

  @override
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {
    final converted = convertMapForJs(data, adminRef);
    final args = merge
        ? [
            converted,
            convertMapForJs({'merge': true}, adminRef)
          ]
        : [converted];
    final promise = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('set', args)
        : js_util.callMethod(
            rawJsRef,
            'set',
            args.map(unwrapJsObject).toList(),
          );
    await safePromiseToFuture(promise);
  }

  @override
  Future<void> update(Map<String, dynamic> data) async {
    final converted = convertMapForJs(data, adminRef);
    final promise = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('update', [converted])
        : js_util.callMethod(rawJsRef, 'update', [unwrapJsObject(converted)]);
    await safePromiseToFuture(promise);
  }

  @override
  Future<void> delete() async {
    final promise = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('delete')
        : js_util.callMethod(rawJsRef, 'delete', []);
    await safePromiseToFuture(promise);
  }
}

class JsDocumentSnapshot implements DocumentSnapshot {
  final dynamic _snap;
  final js.JsObject _adminRef;

  JsDocumentSnapshot(this._snap, this._adminRef);

  @override
  String get id {
    if (_snap == null) return '';
    if (_snap is js.JsObject) return (_snap['id'] as String?) ?? '';
    return (js_util.getProperty(_snap, 'id') as String?) ?? '';
  }

  @override
  bool get exists {
    if (_snap == null) return false;
    final dynamic rawExists = _snap is js.JsObject
        ? _snap['exists']
        : js_util.getProperty(_snap, 'exists');
    if (rawExists is bool) return rawExists;
    return true;
  }

  @override
  DocumentReference? get ref {
    if (_snap == null) return null;
    final rawRef =
        _snap is js.JsObject ? _snap['ref'] : js_util.getProperty(_snap, 'ref');
    if (rawRef == null) return null;
    return JsDocumentReference(rawRef, _adminRef);
  }

  @override
  Map<String, dynamic>? data() {
    if (_snap == null) return null;
    final dynamic dataFn = _snap is js.JsObject
        ? _snap['data']
        : js_util.getProperty(_snap, 'data');
    if (dataFn == null) return null;
    final rawData = _snap is js.JsObject
        ? _snap.callMethod('data')
        : js_util.callMethod(_snap, 'data', []);
    if (rawData == null) return null;
    return jsObjectToDartMap(rawData);
  }
}

class JsWriteBatch implements WriteBatch {
  final dynamic _batch;
  final js.JsObject _adminRef;

  JsWriteBatch(this._batch, this._adminRef);

  @override
  void set(
    DocumentReference ref,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    final jsRef = (ref as JsDocumentReference).rawJsRef;
    final converted = convertMapForJs(data, _adminRef);
    final args = merge
        ? [
            jsRef,
            converted,
            convertMapForJs({'merge': true}, _adminRef)
          ]
        : [jsRef, converted];
    if (_batch is js.JsObject) {
      _batch.callMethod('set', args);
    } else {
      js_util.callMethod(_batch, 'set', args);
    }
  }

  @override
  void update(DocumentReference ref, Map<String, dynamic> data) {
    final jsRef = (ref as JsDocumentReference).rawJsRef;
    final converted = convertMapForJs(data, _adminRef);
    if (_batch is js.JsObject) {
      _batch.callMethod('update', [jsRef, converted]);
    } else {
      js_util.callMethod(_batch, 'update', [jsRef, converted]);
    }
  }

  @override
  void delete(DocumentReference ref) {
    final jsRef = (ref as JsDocumentReference).rawJsRef;
    if (_batch is js.JsObject) {
      _batch.callMethod('delete', [jsRef]);
    } else {
      js_util.callMethod(_batch, 'delete', [jsRef]);
    }
  }

  @override
  Future<void> commit() async {
    final promise = _batch is js.JsObject
        ? _batch.callMethod('commit')
        : js_util.callMethod(_batch, 'commit', []);
    await safePromiseToFuture(promise);
  }
}
