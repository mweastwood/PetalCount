import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'abstract_admin.dart';

/// Interface for JS wrapper objects that hold an underlying raw JS reference.
abstract class RawJsReferenceHolder {
  dynamic get rawJsRef;
}

js.JsObject? _adminInstance;
js.JsObject? _appModuleInstance;
js.JsObject? _firestoreModuleInstance;
js.JsObject? _authModuleInstance;
js.JsObject? _messagingModuleInstance;

js.JsObject requireModule(String moduleName) {
  final require = js.context['require'];
  if (require == null) {
    throw StateError("Node 'require' is not available in current environment");
  }
  return js.context.callMethod('require', [moduleName]) as js.JsObject;
}

js.JsObject get adminModule =>
    _adminInstance ??= requireModule('firebase-admin');

js.JsObject get appModule {
  if (_appModuleInstance == null) {
    try {
      _appModuleInstance = requireModule('firebase-admin/app');
    } catch (_) {
      _appModuleInstance = adminModule;
    }
  }
  return _appModuleInstance!;
}

js.JsObject get firestoreModule {
  if (_firestoreModuleInstance == null) {
    try {
      _firestoreModuleInstance = requireModule('firebase-admin/firestore');
    } catch (_) {
      final fs = adminModule['firestore'];
      if (fs is js.JsObject) {
        _firestoreModuleInstance = fs;
      } else {
        _firestoreModuleInstance = adminModule;
      }
    }
  }
  return _firestoreModuleInstance!;
}

js.JsObject get authModule {
  if (_authModuleInstance == null) {
    try {
      _authModuleInstance = requireModule('firebase-admin/auth');
    } catch (_) {
      final auth = adminModule['auth'];
      if (auth is js.JsObject) {
        _authModuleInstance = auth;
      } else {
        _authModuleInstance = adminModule;
      }
    }
  }
  return _authModuleInstance!;
}

js.JsObject get messagingModule {
  if (_messagingModuleInstance == null) {
    try {
      _messagingModuleInstance = requireModule('firebase-admin/messaging');
    } catch (_) {
      final msg = adminModule['messaging'];
      if (msg is js.JsObject) {
        _messagingModuleInstance = msg;
      } else {
        _messagingModuleInstance = adminModule;
      }
    }
  }
  return _messagingModuleInstance!;
}

void ensureJsBridge() {
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

dynamic unwrapJsObject(dynamic obj) {
  if (obj is! js.JsObject) return obj;

  if (js_util.hasProperty(obj, '_jsObject')) {
    final raw = js_util.getProperty(obj, '_jsObject');
    if (raw != null) return raw;
  }

  ensureJsBridge();
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

Future<T> safePromiseToFuture<T>(dynamic jsPromiseOrObject) {
  if (jsPromiseOrObject is Future<T>) return jsPromiseOrObject;
  if (jsPromiseOrObject is Future) return jsPromiseOrObject.then((v) => v as T);

  final unwrapped = unwrapJsObject(jsPromiseOrObject);

  if (!_isThenable(unwrapped)) {
    throw StateError(
      'Expected a JavaScript Promise/thenable but received object without a "then" method: $unwrapped',
    );
  }

  return js_util.promiseToFuture<T>(unwrapped);
}

Map<String, dynamic>? jsObjectToDartMap(dynamic rawData) {
  if (rawData == null) return null;
  if (rawData is Map<String, dynamic>) return rawData;
  if (rawData is Map) return Map<String, dynamic>.from(rawData);
  final unwrapped = unwrapJsObject(rawData);
  ensureJsBridge();
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

js.JsObject? getFieldValueClass(dynamic firestoreRef) {
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
    final module = firestoreModule;
    if (module.hasProperty('FieldValue')) {
      final fv = module['FieldValue'];
      if (fv is js.JsObject) return fv;
    }
  } catch (_) {}
  return null;
}

js.JsObject? getTimestampClass(dynamic firestoreRef) {
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
    final module = firestoreModule;
    if (module.hasProperty('Timestamp')) {
      final ts = module['Timestamp'];
      if (ts is js.JsObject) return ts;
    }
  } catch (_) {}
  return null;
}

dynamic convertValueForJs(
  dynamic value,
  dynamic firestoreRef, [
  js.JsObject? fieldValueClass,
  js.JsObject? timestampClass,
]) {
  fieldValueClass ??= getFieldValueClass(firestoreRef);
  timestampClass ??= getTimestampClass(firestoreRef);

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
  } else if (value is RawJsReferenceHolder) {
    return value.rawJsRef;
  } else if (value is js.JsObject) {
    return value;
  } else if (value is Map<String, dynamic>) {
    return convertMapForJs(value, firestoreRef);
  } else if (value is Map) {
    return convertMapForJs(
      value.map((k, v) => MapEntry(k.toString(), v)),
      firestoreRef,
    );
  } else if (value is Iterable) {
    return js.JsArray.from(
      value.map(
        (item) => convertValueForJs(
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

dynamic convertMapForJs(Map<String, dynamic> map, dynamic firestoreRef) {
  final fieldValueClass = getFieldValueClass(firestoreRef);
  final timestampClass = getTimestampClass(firestoreRef);
  final jsObj = js.JsObject(js.context['Object']);

  for (final entry in map.entries) {
    jsObj[entry.key] = convertValueForJs(
      entry.value,
      firestoreRef,
      fieldValueClass,
      timestampClass,
    );
  }
  return jsObj;
}
