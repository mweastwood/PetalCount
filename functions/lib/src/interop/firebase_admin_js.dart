export 'abstract_admin.dart';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'abstract_admin.dart';

js.JsObject? _adminInstance;
js.JsObject? _appModuleInstance;
js.JsObject? _firestoreModuleInstance;
js.JsObject? _authModuleInstance;
js.JsObject? _messagingModuleInstance;
dynamic _dbInstance;
dynamic _authInstance;
dynamic _messagingInstance;

js.JsObject _requireModule(String moduleName) {
  final require = js.context['require'];
  if (require == null) {
    throw StateError("Node 'require' is not available in current environment");
  }
  return js.context.callMethod('require', [moduleName]) as js.JsObject;
}

js.JsObject get _admin => _adminInstance ??= _requireModule('firebase-admin');

js.JsObject get _appModule {
  if (_appModuleInstance == null) {
    try {
      _appModuleInstance = _requireModule('firebase-admin/app');
    } catch (_) {
      _appModuleInstance = _admin;
    }
  }
  return _appModuleInstance!;
}

js.JsObject get _firestoreModule {
  if (_firestoreModuleInstance == null) {
    try {
      _firestoreModuleInstance = _requireModule('firebase-admin/firestore');
    } catch (_) {
      final fs = _admin['firestore'];
      if (fs is js.JsObject) {
        _firestoreModuleInstance = fs;
      } else {
        _firestoreModuleInstance = _admin;
      }
    }
  }
  return _firestoreModuleInstance!;
}

js.JsObject get _authModule {
  if (_authModuleInstance == null) {
    try {
      _authModuleInstance = _requireModule('firebase-admin/auth');
    } catch (_) {
      final auth = _admin['auth'];
      if (auth is js.JsObject) {
        _authModuleInstance = auth;
      } else {
        _authModuleInstance = _admin;
      }
    }
  }
  return _authModuleInstance!;
}

js.JsObject get _messagingModule {
  if (_messagingModuleInstance == null) {
    try {
      _messagingModuleInstance = _requireModule('firebase-admin/messaging');
    } catch (_) {
      final msg = _admin['messaging'];
      if (msg is js.JsObject) {
        _messagingModuleInstance = msg;
      } else {
        _messagingModuleInstance = _admin;
      }
    }
  }
  return _messagingModuleInstance!;
}

void initializeFirebaseAdmin() {
  final apps = (_appModule.hasProperty('getApps')
          ? _appModule.callMethod('getApps') as List?
          : null) ??
      _appModule['apps'] as List? ??
      (_admin.hasProperty('getApps')
          ? _admin.callMethod('getApps') as List?
          : null) ??
      _admin['apps'] as List?;
  if (apps == null || apps.isEmpty) {
    if (_appModule.hasProperty('initializeApp')) {
      _appModule.callMethod('initializeApp');
    } else if (_admin.hasProperty('initializeApp')) {
      _admin.callMethod('initializeApp');
    }
  }
}

FirestoreDatabase getFirebaseAdminDb([dynamic jsDb]) {
  initializeFirebaseAdmin();
  if (jsDb != null) {
    return JsFirestoreDatabase(jsDb, _firestoreModule);
  }
  dynamic dbInstance;
  try {
    if (_firestoreModule.hasProperty('getFirestore')) {
      dbInstance = _firestoreModule.callMethod('getFirestore');
    }
  } catch (_) {}
  if (dbInstance == null) {
    if (_admin.hasProperty('firestore')) {
      dbInstance = _admin.callMethod('firestore');
    } else {
      throw StateError(
        'Neither getFirestore nor admin.firestore found in firebase-admin',
      );
    }
  }
  _dbInstance = dbInstance;
  return JsFirestoreDatabase(_dbInstance!, _firestoreModule);
}

AuthService getFirebaseAdminAuth([dynamic jsAuth]) {
  initializeFirebaseAdmin();
  if (jsAuth != null) {
    return JsAuthService(jsAuth);
  }
  dynamic authInstance;
  try {
    if (_authModule.hasProperty('getAuth')) {
      authInstance = _authModule.callMethod('getAuth');
    }
  } catch (_) {}
  if (authInstance == null) {
    if (_admin.hasProperty('auth')) {
      authInstance = _admin.callMethod('auth');
    } else {
      throw StateError(
        'Neither getAuth nor admin.auth found in firebase-admin',
      );
    }
  }
  _authInstance = authInstance;
  return JsAuthService(_authInstance!);
}

MessagingService getFirebaseAdminMessaging([dynamic jsMessaging]) {
  initializeFirebaseAdmin();
  if (jsMessaging != null) {
    return JsMessagingService(jsMessaging);
  }
  dynamic messagingInstance;
  try {
    if (_messagingModule.hasProperty('getMessaging')) {
      messagingInstance = _messagingModule.callMethod('getMessaging');
    }
  } catch (_) {}
  if (messagingInstance == null) {
    if (_admin.hasProperty('messaging')) {
      messagingInstance = _admin.callMethod('messaging');
    } else {
      throw StateError(
        'Neither getMessaging nor admin.messaging found in firebase-admin',
      );
    }
  }
  _messagingInstance = messagingInstance;
  return JsMessagingService(_messagingInstance!);
}

void _ensureJsBridge() {
  if (js_util.hasProperty(
        js_util.globalThis,
        '__antigravity_store_unwrapped',
      ) ||
      js.context.hasProperty('__antigravity_store_unwrapped')) {
    return;
  }
  js.context.callMethod('eval', [
    '''
    (function() {
      var g = typeof globalThis !== 'undefined' ? globalThis : (typeof self !== 'undefined' ? self : global);
      g.__antigravity_unwrapped = null;
      g.__antigravity_store_unwrapped = function(target) {
        g.__antigravity_unwrapped = target;
      };
      g.__antigravity_json_stringify = function(target) {
        return JSON.stringify(target);
      };
    })();
    ''',
  ]);
}

dynamic _unwrapJsObject(dynamic obj) {
  if (obj is! js.JsObject) return obj;

  if (js_util.hasProperty(obj, '_jsObject')) {
    final raw = js_util.getProperty(obj, '_jsObject');
    if (raw != null) return raw;
  }

  _ensureJsBridge();
  if (js.context.hasProperty('__antigravity_store_unwrapped')) {
    js.context.callMethod('__antigravity_store_unwrapped', [obj]);
  } else if (js_util.hasProperty(
    js_util.globalThis,
    '__antigravity_store_unwrapped',
  )) {
    js_util.callMethod(
      js_util.globalThis,
      '__antigravity_store_unwrapped',
      [obj],
    );
  }
  final unwrapped =
      js_util.getProperty(js_util.globalThis, '__antigravity_unwrapped') ??
          (js.context.hasProperty('__antigravity_unwrapped')
              ? js.context['__antigravity_unwrapped']
              : null);
  js_util.setProperty(js_util.globalThis, '__antigravity_unwrapped', null);
  if (js.context.hasProperty('__antigravity_unwrapped')) {
    js.context['__antigravity_unwrapped'] = null;
  }
  return unwrapped ?? obj;
}

bool _isThenable(dynamic obj) {
  if (obj == null) return false;
  if (obj is String || obj is num || obj is bool) return false;
  try {
    if (obj is js.JsObject) {
      return obj.hasProperty('then');
    }
    return js_util.hasProperty(obj, 'then');
  } catch (_) {
    return false;
  }
}

Future<T> _safePromiseToFuture<T>(dynamic jsPromiseOrObject) {
  if (jsPromiseOrObject is Future<T>) return jsPromiseOrObject;
  if (jsPromiseOrObject is Future) return jsPromiseOrObject.then((v) => v as T);

  final unwrapped = _unwrapJsObject(jsPromiseOrObject);

  if (!_isThenable(unwrapped)) {
    throw StateError(
      'Expected a JavaScript Promise/thenable but received object without a "then" method: $unwrapped',
    );
  }

  return js_util.promiseToFuture<T>(unwrapped);
}

Future<T> safePromiseToFuture<T>(dynamic jsPromiseOrObject) =>
    _safePromiseToFuture<T>(jsPromiseOrObject);

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
            jsRefs.map(_unwrapJsObject).toList(),
          );
    final rawSnaps = await _safePromiseToFuture(promise);
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
      await _safePromiseToFuture(promise);
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
    final jsVal = _convertValueForJs(value, adminRef);
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
    final snap = await _safePromiseToFuture(promise);
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

class JsDocumentReference implements DocumentReference {
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
    final snap = await _safePromiseToFuture(promise);
    return JsDocumentSnapshot(snap, adminRef);
  }

  @override
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {
    final converted = _convertMapForJs(data, adminRef);
    final args = merge
        ? [
            converted,
            _convertMapForJs({'merge': true}, adminRef)
          ]
        : [converted];
    final promise = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('set', args)
        : js_util.callMethod(
            rawJsRef,
            'set',
            args.map(_unwrapJsObject).toList(),
          );
    await _safePromiseToFuture(promise);
  }

  @override
  Future<void> update(Map<String, dynamic> data) async {
    final converted = _convertMapForJs(data, adminRef);
    final promise = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('update', [converted])
        : js_util.callMethod(rawJsRef, 'update', [_unwrapJsObject(converted)]);
    await _safePromiseToFuture(promise);
  }

  @override
  Future<void> delete() async {
    final promise = rawJsRef is js.JsObject
        ? rawJsRef.callMethod('delete')
        : js_util.callMethod(rawJsRef, 'delete', []);
    await _safePromiseToFuture(promise);
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

Map<String, dynamic>? jsObjectToDartMap(dynamic rawData) {
  if (rawData == null) return null;
  if (rawData is Map<String, dynamic>) return rawData;
  if (rawData is Map) return Map<String, dynamic>.from(rawData);
  final unwrapped = _unwrapJsObject(rawData);
  _ensureJsBridge();
  final jsonStr = js_util.hasProperty(
    js_util.globalThis,
    '__antigravity_json_stringify',
  )
      ? js_util.callMethod(
          js_util.globalThis,
          '__antigravity_json_stringify',
          [unwrapped],
        ) as String?
      : (js.context.hasProperty('__antigravity_json_stringify')
          ? js.context.callMethod(
              '__antigravity_json_stringify',
              [unwrapped],
            ) as String?
          : js.context['JSON'].callMethod('stringify', [unwrapped]) as String?);
  if (jsonStr == null) return null;
  final decoded = jsonDecode(jsonStr);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  } else if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  return null;
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
    final converted = _convertMapForJs(data, _adminRef);
    final args = merge
        ? [
            jsRef,
            converted,
            _convertMapForJs({'merge': true}, _adminRef)
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
    final converted = _convertMapForJs(data, _adminRef);
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
    await _safePromiseToFuture(promise);
  }
}

class JsAuthService implements AuthService {
  final dynamic _auth;

  JsAuthService(this._auth);

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken) async {
    final promise = _auth is js.JsObject
        ? _auth.callMethod('verifyIdToken', [idToken])
        : js_util.callMethod(_auth, 'verifyIdToken', [idToken]);
    final decoded = await _safePromiseToFuture(promise);
    final uid = decoded is js.JsObject
        ? (decoded['uid'] as String?) ?? ''
        : (js_util.getProperty(decoded, 'uid') as String?) ?? '';
    final email = decoded is js.JsObject
        ? decoded['email'] as String?
        : js_util.getProperty(decoded, 'email') as String?;
    final admin = decoded is js.JsObject
        ? decoded['admin'] as bool?
        : js_util.getProperty(decoded, 'admin') as bool?;
    return DecodedIdToken(
      uid: uid,
      email: email,
      admin: admin,
    );
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      final promise = _auth is js.JsObject
          ? _auth.callMethod('deleteUser', [uid])
          : js_util.callMethod(_auth, 'deleteUser', [uid]);
      await _safePromiseToFuture(promise);
    } catch (e) {
      final code = js_util.getProperty(e, 'code');
      if (code == 'auth/user-not-found') {
        throw const FirebaseAuthException(
          code: 'auth/user-not-found',
          message: 'User not found',
        );
      }
      rethrow;
    }
  }
}

class JsMessagingService implements MessagingService {
  final dynamic _messaging;

  JsMessagingService(this._messaging);

  @override
  dynamic get rawMessaging => _messaging;

  @override
  Future<BatchResponse> sendEachForMulticast(
    Map<String, dynamic> message,
  ) async {
    final jsMessage = _convertMapForJs(message, null);
    final promise = _messaging is js.JsObject
        ? _messaging.callMethod('sendEachForMulticast', [jsMessage])
        : js_util.callMethod(
            _messaging,
            'sendEachForMulticast',
            [_unwrapJsObject(jsMessage)],
          );
    final rawResp = await _safePromiseToFuture(promise);

    final successCount = rawResp is js.JsObject
        ? (rawResp['successCount'] as num?)?.toInt() ?? 0
        : (js_util.getProperty(rawResp, 'successCount') as num?)?.toInt() ?? 0;
    final failureCount = rawResp is js.JsObject
        ? (rawResp['failureCount'] as num?)?.toInt() ?? 0
        : (js_util.getProperty(rawResp, 'failureCount') as num?)?.toInt() ?? 0;
    final dynamic rawResponses = rawResp is js.JsObject
        ? rawResp['responses']
        : js_util.getProperty(rawResp, 'responses');
    final responsesList = rawResponses as List?;
    final parsedResponses = <SendResponse>[];
    if (responsesList != null) {
      for (final item in responsesList) {
        final success = item is js.JsObject
            ? (item['success'] as bool?) ?? false
            : (js_util.getProperty(item, 'success') as bool?) ?? false;
        final dynamic err = item is js.JsObject
            ? item['error']
            : js_util.getProperty(item, 'error');
        String? errorCode;
        String? errorMessage;
        if (err != null) {
          errorCode = err is js.JsObject
              ? err['code'] as String?
              : js_util.getProperty(err, 'code') as String?;
          errorMessage = err is js.JsObject
              ? err['message'] as String?
              : js_util.getProperty(err, 'message') as String?;
        }
        parsedResponses.add(
          SendResponse(
            success: success,
            errorCode: errorCode,
            errorMessage: errorMessage,
          ),
        );
      }
    }

    return BatchResponse(
      successCount: successCount,
      failureCount: failureCount,
      responses: parsedResponses,
    );
  }
}

js.JsObject? _getFieldValueClass(dynamic firestoreRef) {
  if (firestoreRef is js.JsObject) {
    if (firestoreRef.hasProperty('FieldValue')) {
      final fv = firestoreRef['FieldValue'];
      if (fv is js.JsObject) return fv;
    }
    if (firestoreRef.hasProperty('firestore')) {
      final fs = firestoreRef['firestore'];
      if (fs is js.JsObject && fs.hasProperty('FieldValue')) {
        final fv = fs['FieldValue'];
        if (fv is js.JsObject) return fv;
      }
    }
  }
  try {
    final module = _firestoreModule;
    if (module.hasProperty('FieldValue')) {
      final fv = module['FieldValue'];
      if (fv is js.JsObject) return fv;
    }
  } catch (_) {}
  return null;
}

js.JsObject? _getTimestampClass(dynamic firestoreRef) {
  if (firestoreRef is js.JsObject) {
    if (firestoreRef.hasProperty('Timestamp')) {
      final ts = firestoreRef['Timestamp'];
      if (ts is js.JsObject) return ts;
    }
    if (firestoreRef.hasProperty('firestore')) {
      final fs = firestoreRef['firestore'];
      if (fs is js.JsObject && fs.hasProperty('Timestamp')) {
        final ts = fs['Timestamp'];
        if (ts is js.JsObject) return ts;
      }
    }
  }
  try {
    final module = _firestoreModule;
    if (module.hasProperty('Timestamp')) {
      final ts = module['Timestamp'];
      if (ts is js.JsObject) return ts;
    }
  } catch (_) {}
  return null;
}

dynamic _convertValueForJs(
  dynamic value,
  dynamic firestoreRef, [
  js.JsObject? fieldValueClass,
  js.JsObject? timestampClass,
]) {
  fieldValueClass ??= _getFieldValueClass(firestoreRef);
  timestampClass ??= _getTimestampClass(firestoreRef);

  if (value == null) {
    return null;
  } else if (value is String || value is num || value is bool) {
    return value;
  } else if (value == FieldValue.deleteToken) {
    return fieldValueClass?.callMethod('delete');
  } else if (value is FieldValueArrayRemove) {
    return fieldValueClass != null
        ? fieldValueClass.callMethod('arrayRemove', value.elements)
        : js.JsObject.jsify({
            '__fieldValue': 'arrayRemove',
            'elements': value.elements,
          });
  } else if (value is DateTime) {
    if (timestampClass != null) {
      return timestampClass.callMethod(
        'fromMillis',
        [value.millisecondsSinceEpoch],
      );
    }
    final dateObj =
        js.JsObject(js.context['Date'], [value.toUtc().toIso8601String()]);
    return dateObj;
  } else if (value is JsDocumentReference) {
    return value.rawJsRef;
  } else if (value is js.JsObject) {
    return value;
  } else if (value is Map<String, dynamic>) {
    return _convertMapForJs(value, firestoreRef);
  } else if (value is Map) {
    return _convertMapForJs(
      value.map((k, v) => MapEntry(k.toString(), v)),
      firestoreRef,
    );
  } else if (value is Iterable) {
    return js.JsArray.from(
      value.map(
        (item) => _convertValueForJs(
          item,
          firestoreRef,
          fieldValueClass,
          timestampClass,
        ),
      ),
    );
  } else {
    return value;
  }
}

dynamic _convertMapForJs(Map<String, dynamic> map, dynamic firestoreRef) {
  final fieldValueClass = _getFieldValueClass(firestoreRef);
  final timestampClass = _getTimestampClass(firestoreRef);
  final jsObj = js.JsObject(js.context['Object']);

  for (final entry in map.entries) {
    jsObj[entry.key] = _convertValueForJs(
      entry.value,
      firestoreRef,
      fieldValueClass,
      timestampClass,
    );
  }
  return jsObj;
}
