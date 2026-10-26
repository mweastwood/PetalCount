import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'abstract_admin.dart';
import 'js_bridge_helpers.dart';

class JsAuthService implements AuthService {
  final dynamic _auth;

  JsAuthService(this._auth);

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken) async {
    final promise = _auth is js.JsObject
        ? _auth.callMethod('verifyIdToken', [idToken])
        : js_util.callMethod(_auth, 'verifyIdToken', [idToken]);
    final decoded = await safePromiseToFuture(promise);
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
      await safePromiseToFuture(promise);
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
    final jsMessage = convertMapForJs(message, null);
    final promise = _messaging is js.JsObject
        ? _messaging.callMethod('sendEachForMulticast', [jsMessage])
        : js_util.callMethod(
            _messaging,
            'sendEachForMulticast',
            [unwrapJsObject(jsMessage)],
          );
    final rawResp = await safePromiseToFuture(promise);

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
