export 'abstract_admin.dart';
export 'js_auth_and_messaging.dart';
export 'js_bridge_helpers.dart';
export 'js_firestore.dart';

import 'abstract_admin.dart';
import 'js_auth_and_messaging.dart';
import 'js_bridge_helpers.dart';
import 'js_firestore.dart';

dynamic _dbInstance;
dynamic _authInstance;
dynamic _messagingInstance;

void initializeFirebaseAdmin() {
  final apps = (appModule.hasProperty('getApps')
          ? appModule.callMethod('getApps') as List?
          : null) ??
      appModule['apps'] as List? ??
      (adminModule.hasProperty('getApps')
          ? adminModule.callMethod('getApps') as List?
          : null) ??
      adminModule['apps'] as List?;
  if (apps == null || apps.isEmpty) {
    if (appModule.hasProperty('initializeApp')) {
      appModule.callMethod('initializeApp');
    } else if (adminModule.hasProperty('initializeApp')) {
      adminModule.callMethod('initializeApp');
    }
  }
}

FirestoreDatabase getFirebaseAdminDb([dynamic jsDb]) {
  initializeFirebaseAdmin();
  if (jsDb != null) {
    return JsFirestoreDatabase(jsDb, firestoreModule);
  }
  dynamic dbInstance;
  try {
    if (firestoreModule.hasProperty('getFirestore')) {
      dbInstance = firestoreModule.callMethod('getFirestore');
    }
  } catch (_) {}
  if (dbInstance == null) {
    if (adminModule.hasProperty('firestore')) {
      dbInstance = adminModule.callMethod('firestore');
    } else {
      throw StateError(
        'Neither getFirestore nor admin.firestore found in firebase-admin',
      );
    }
  }
  _dbInstance = dbInstance;
  return JsFirestoreDatabase(_dbInstance!, firestoreModule);
}

AuthService getFirebaseAdminAuth([dynamic jsAuth]) {
  initializeFirebaseAdmin();
  if (jsAuth != null) {
    return JsAuthService(jsAuth);
  }
  dynamic authInstance;
  try {
    if (authModule.hasProperty('getAuth')) {
      authInstance = authModule.callMethod('getAuth');
    }
  } catch (_) {}
  if (authInstance == null) {
    if (adminModule.hasProperty('auth')) {
      authInstance = adminModule.callMethod('auth');
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
    if (messagingModule.hasProperty('getMessaging')) {
      messagingInstance = messagingModule.callMethod('getMessaging');
    }
  } catch (_) {}
  if (messagingInstance == null) {
    if (adminModule.hasProperty('messaging')) {
      messagingInstance = adminModule.callMethod('messaging');
    } else {
      throw StateError(
        'Neither getMessaging nor admin.messaging found in firebase-admin',
      );
    }
  }
  _messagingInstance = messagingInstance;
  return JsMessagingService(_messagingInstance!);
}
