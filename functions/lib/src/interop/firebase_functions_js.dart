export 'firebase_functions_stub.dart';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'firebase_admin_js.dart';
import 'firebase_functions_stub.dart';

class JsHttpRequest implements HttpRequest {
  final js.JsObject rawReq;
  @override
  final String method;
  @override
  final Map<String, dynamic> headers;
  @override
  final Map<String, dynamic> query;
  @override
  final dynamic body;

  JsHttpRequest._(
    this.rawReq,
    this.method,
    this.headers,
    this.query,
    this.body,
  );

  factory JsHttpRequest(js.JsObject req) {
    final method = (req['method'] as String?) ?? 'GET';

    Map<String, dynamic> headersMap = {};
    final rawHeaders = req['headers'];
    if (rawHeaders != null) {
      try {
        final jsonHeaders =
            js.context['JSON'].callMethod('stringify', [rawHeaders]) as String?;
        if (jsonHeaders != null) {
          headersMap =
              Map<String, dynamic>.from(jsonDecode(jsonHeaders) as Map);
        }
      } catch (_) {}
    }

    Map<String, dynamic> queryMap = {};
    final rawQuery = req['query'];
    if (rawQuery != null) {
      try {
        final jsonQuery =
            js.context['JSON'].callMethod('stringify', [rawQuery]) as String?;
        if (jsonQuery != null) {
          queryMap = Map<String, dynamic>.from(jsonDecode(jsonQuery) as Map);
        }
      } catch (_) {}
    }

    dynamic bodyData;
    final rawBody = req['body'];
    if (rawBody != null) {
      if (rawBody is String) {
        try {
          bodyData = jsonDecode(rawBody);
        } catch (_) {
          bodyData = rawBody;
        }
      } else {
        try {
          final jsonBody =
              js.context['JSON'].callMethod('stringify', [rawBody]) as String?;
          if (jsonBody != null) {
            bodyData = jsonDecode(jsonBody);
          }
        } catch (_) {
          bodyData = rawBody;
        }
      }
    }

    return JsHttpRequest._(req, method, headersMap, queryMap, bodyData);
  }
}

class JsHttpResponse implements HttpResponse {
  final js.JsObject rawRes;

  JsHttpResponse(this.rawRes);

  @override
  HttpResponse status(int code) {
    final chained = rawRes.callMethod('status', [code]);
    if (chained is js.JsObject) {
      return JsHttpResponse(chained);
    }
    return this;
  }

  @override
  void json(dynamic data) {
    final jsonStr = jsonEncode(data);
    final jsObj = js.context['JSON'].callMethod('parse', [jsonStr]);
    rawRes.callMethod('json', [jsObj]);
  }

  @override
  void send(String data) {
    rawRes.callMethod('send', [data]);
  }
}

js.JsObject? _resolveCaller;
js.JsObject? _rejectCaller;

js.JsObject get _callResolver => _resolveCaller ??= js.context
    .callMethod('eval', ['(function(r, v) { r(v); })']) as js.JsObject;

js.JsObject get _callRejecter => _rejectCaller ??= js.context
    .callMethod('eval', ['(function(r, e) { r(e); })']) as js.JsObject;

dynamic futureToJsPromise(Future<dynamic> future) {
  final promiseConstructor = js.context['Promise'];
  return js.JsObject(promiseConstructor, [
    js.allowInterop((resolve, reject) {
      future.then(
        (val) {
          final jsVal =
              val is Map || val is Iterable ? js.JsObject.jsify(val) : val;
          _callResolver.callMethod('call', [null, resolve, jsVal]);
        },
        onError: (err, stack) {
          dynamic jsErr = err;
          if (err is! js.JsObject) {
            jsErr = js.JsObject(js.context['Error'], [err.toString()]);
          }
          _callRejecter.callMethod('call', [null, reject, jsErr]);
        },
      );
    }),
  ]);
}

dynamic onRequest(
  Map<String, dynamic> options,
  Future<void> Function(HttpRequest, HttpResponse) handler,
) {
  final https = js.context
      .callMethod('require', ['firebase-functions/v2/https']) as js.JsObject;
  final jsOptions = js.JsObject.jsify(options);

  final jsCallback = js.allowInterop((req, res) {
    return futureToJsPromise(
      (() async {
        final jsReq =
            req is js.JsObject ? req : js.JsObject.fromBrowserObject(req);
        final jsRes =
            res is js.JsObject ? res : js.JsObject.fromBrowserObject(res);
        final httpReq = JsHttpRequest(jsReq);
        final httpRes = JsHttpResponse(jsRes);
        await handler(httpReq, httpRes);
      })(),
    );
  });

  return https.callMethod('onRequest', [jsOptions, jsCallback]);
}

dynamic onSchedule(
  Map<String, dynamic> options,
  Future<void> Function(dynamic) handler,
) {
  final scheduler =
      js.context.callMethod('require', ['firebase-functions/v2/scheduler'])
          as js.JsObject;
  final jsOptions = js.JsObject.jsify(options);

  final jsCallback = js.allowInterop((event) {
    return futureToJsPromise(
      (() async {
        await handler(event);
      })(),
    );
  });

  return scheduler.callMethod('onSchedule', [jsOptions, jsCallback]);
}

FirestoreEvent _parseJsFirestoreEvent(dynamic rawEvent) {
  final adminRef = js.JsObject(js.context['Object']);
  final params = <String, String>{};
  if (rawEvent != null) {
    final dynamic rawParams = rawEvent is js.JsObject
        ? rawEvent['params']
        : js_util.getProperty(rawEvent, 'params');
    final paramsMap = jsObjectToDartMap(rawParams);
    if (paramsMap != null) {
      for (final entry in paramsMap.entries) {
        if (entry.value != null) {
          params[entry.key] = entry.value.toString();
        }
      }
    }
    final dynamic rawData = rawEvent is js.JsObject
        ? rawEvent['data']
        : js_util.getProperty(rawEvent, 'data');
    if (rawData != null) {
      final rawBefore = rawData is js.JsObject
          ? rawData['before']
          : js_util.getProperty(rawData, 'before');
      final rawAfter = rawData is js.JsObject
          ? rawData['after']
          : js_util.getProperty(rawData, 'after');
      final beforeSnap = JsDocumentSnapshot(rawBefore, adminRef);
      final afterSnap = JsDocumentSnapshot(rawAfter, adminRef);
      return FirestoreEvent(
        params: params,
        data: FirestoreChange(before: beforeSnap, after: afterSnap),
      );
    }
  }
  return FirestoreEvent(params: params);
}

dynamic onDocumentWritten(
  String documentPath,
  Future<void> Function(FirestoreEvent) handler,
) {
  final firestore =
      js.context.callMethod('require', ['firebase-functions/v2/firestore'])
          as js.JsObject;

  final jsCallback = js.allowInterop((rawEvent) {
    return futureToJsPromise(
      (() async {
        final event = _parseJsFirestoreEvent(rawEvent);
        await handler(event);
      })(),
    );
  });

  return firestore.callMethod(
    'onDocumentWritten',
    [documentPath, jsCallback],
  );
}
