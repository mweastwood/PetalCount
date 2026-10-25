import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app_config.dart';
import '../services.dart';
import 'database_helpers.dart';
import 'database_service_interface.dart';
import 'firebase_database_helpers.dart';

export 'database_helpers.dart'
    show NotificationDispatchContext, ObservationRoleContext;

part 'firebase/firebase_auth_user_ops.dart';
part 'firebase/firebase_chart_ops.dart';
part 'firebase/firebase_cycle_ops.dart';
part 'firebase/firebase_supplement_ops.dart';

abstract class _FirebaseDatabaseServiceBase implements DatabaseService {
  final FirebaseAuth? _authInstance;
  final FirebaseFirestore? _dbInstance;
  final GoogleSignIn? _googleSignInInstance;
  bool _googleSignInInitialized = false;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbInstance ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn =>
      _googleSignInInstance ?? GoogleSignIn.instance;

  String? _cachedChartId;
  String? _cachedRole;
  final Map<String, NotificationPreferences> _cachedPreferencesByChart = {};
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();

  _FirebaseDatabaseServiceBase({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? googleSignIn,
  }) : _authInstance = auth,
       _dbInstance = db,
       _googleSignInInstance = googleSignIn;

  Future<void> _handleChartAccessLost(String chartId) async {
    final user = currentUser;
    if (user != null && _cachedChartId == chartId) {
      _cachedChartId = null;
      _cachedPreferencesByChart.remove(chartId);
      try {
        await _db.collection('users').doc(user.uid).set({
          'chartId': null,
        }, SetOptions(merge: true));
      } catch (_) {}
      _authController.add(user);
    }
  }

  Future<void> _cleanupStaleChartReference(String uid, String chartId) async {
    if (_cachedChartId == chartId) {
      _cachedChartId = null;
    }
    _cachedPreferencesByChart.remove(chartId);
    try {
      await _db.collection('users').doc(uid).set({
        'chartId': null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error clearing stale chartId in Firestore: $e');
    }
  }

  Future<String?> _fetchChartId(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      final chartId = doc.data()?['chartId'] as String?;
      if (chartId == null || chartId.isEmpty) {
        return null;
      }

      try {
        final chartDoc = await _db.collection('charts').doc(chartId).get();
        if (!chartDoc.exists) {
          await _cleanupStaleChartReference(uid, chartId);
          return null;
        }

        final userIds = (chartDoc.data()?['userIds'] as List?)?.cast<dynamic>();
        if (userIds == null || !userIds.contains(uid)) {
          await _cleanupStaleChartReference(uid, chartId);
          return null;
        }

        return chartId;
      } catch (e) {
        debugPrint('Error verifying chart $chartId for user $uid: $e');
        if (FirebaseDatabaseHelpers.isAccessLostError(e)) {
          await _cleanupStaleChartReference(uid, chartId);
          return null;
        }
        // For transient/network errors, preserve the user's chartId in Firestore
        return chartId;
      }
    } catch (e) {
      debugPrint('Error fetching chartId: $e');
    }
    return null;
  }

  Future<void> _commitBatchedWrites(
    List<void Function(WriteBatch batch)> operations, {
    int batchLimit = 450,
  }) async {
    return FirebaseDatabaseHelpers.commitBatchedOperations<WriteBatch>(
      operations: operations,
      batchFactory: () => _db.batch(),
      commitBatch: (batch) => batch.commit(),
      batchLimit: batchLimit,
    );
  }

  Future<void> _deleteDocumentsInBatches(
    List<DocumentReference> docRefs,
  ) async {
    if (docRefs.isEmpty) return;
    final operations = docRefs
        .map(
          (ref) =>
              (WriteBatch batch) => batch.delete(ref),
        )
        .toList();
    await _commitBatchedWrites(operations);
  }

  Stream<T> _buildUserGatedStream<T>({
    required T emptyValue,
    required Stream<T> Function(String uid) subscribe,
    String? debugLabel,
  }) {
    return FirebaseDatabaseHelpers.buildUserGatedStreamHelper<T>(
      getCurrentUserId: () => currentUser?.uid,
      authStateChanges: authStateChanges,
      emptyValue: emptyValue,
      subscribe: subscribe,
      debugLabel: debugLabel,
    );
  }

  Stream<T> _buildAuthGatedStream<T>({
    required T emptyValue,
    required Stream<T> Function(String chartId) subscribe,
    String? debugLabel,
  }) {
    return FirebaseDatabaseHelpers.buildAuthGatedStreamHelper<T>(
      getCurrentChartId: () => currentChartId,
      authStateChanges: authStateChanges,
      emptyValue: emptyValue,
      subscribe: subscribe,
      debugLabel: debugLabel,
      onAccessLost: _handleChartAccessLost,
    );
  }
}

class FirebaseDatabaseService extends _FirebaseDatabaseServiceBase
    with
        _FirebaseAuthUserOps,
        _FirebaseChartOps,
        _FirebaseCycleOps,
        _FirebaseSupplementOps {
  FirebaseDatabaseService({super.auth, super.db, super.googleSignIn}) {
    try {
      _auth.authStateChanges().listen((user) async {
        if (user != null) {
          _cachedChartId = await _fetchChartId(user.uid);
        } else {
          _cachedChartId = null;
          _cachedRole = null;
          _cachedPreferencesByChart.clear();
        }
        _authController.add(user);
      });
    } catch (_) {}
  }

  @visibleForTesting
  set cachedChartId(String? id) => _cachedChartId = id;

  @visibleForTesting
  String? get cachedRole => _cachedRole;

  @visibleForTesting
  set cachedRole(String? role) => _cachedRole = role;

  @visibleForTesting
  Future<void> reallocateAndRecalculate(String chartId) =>
      _reallocateAndRecalculate(chartId);

  @visibleForTesting
  Future<String?> fetchChartId(String uid) => _fetchChartId(uid);

  @visibleForTesting
  Future<void> handleChartAccessLost(String chartId) =>
      _handleChartAccessLost(chartId);

  @visibleForTesting
  static bool isAccessLostError(dynamic e) =>
      FirebaseDatabaseHelpers.isAccessLostError(e);

  @visibleForTesting
  static Future<void> commitBatchedOperations<T>({
    required List<void Function(T batch)> operations,
    required T Function() batchFactory,
    required Future<void> Function(T batch) commitBatch,
    int batchLimit = 450,
  }) => FirebaseDatabaseHelpers.commitBatchedOperations<T>(
    operations: operations,
    batchFactory: batchFactory,
    commitBatch: commitBatch,
    batchLimit: batchLimit,
  );

  @visibleForTesting
  static Stream<T> buildGatedStreamHelper<T>({
    required String? Function() getKey,
    required Stream<dynamic> authStateChanges,
    required T emptyValue,
    required Stream<T> Function(String key) subscribe,
    String? debugLabel,
    Future<void> Function(String key)? onAccessLost,
  }) => FirebaseDatabaseHelpers.buildGatedStreamHelper<T>(
    getKey: getKey,
    authStateChanges: authStateChanges,
    emptyValue: emptyValue,
    subscribe: subscribe,
    debugLabel: debugLabel,
    onAccessLost: onAccessLost,
  );

  @visibleForTesting
  static Stream<T> buildUserGatedStreamHelper<T>({
    required String? Function() getCurrentUserId,
    required Stream<dynamic> authStateChanges,
    required T emptyValue,
    required Stream<T> Function(String uid) subscribe,
    String? debugLabel,
    Future<void> Function(String uid)? onAccessLost,
  }) => FirebaseDatabaseHelpers.buildUserGatedStreamHelper<T>(
    getCurrentUserId: getCurrentUserId,
    authStateChanges: authStateChanges,
    emptyValue: emptyValue,
    subscribe: subscribe,
    debugLabel: debugLabel,
    onAccessLost: onAccessLost,
  );

  @visibleForTesting
  static Stream<T> buildAuthGatedStreamHelper<T>({
    required String? Function() getCurrentChartId,
    required Stream<dynamic> authStateChanges,
    required T emptyValue,
    required Stream<T> Function(String chartId) subscribe,
    String? debugLabel,
    Future<void> Function(String chartId)? onAccessLost,
  }) => FirebaseDatabaseHelpers.buildAuthGatedStreamHelper<T>(
    getCurrentChartId: getCurrentChartId,
    authStateChanges: authStateChanges,
    emptyValue: emptyValue,
    subscribe: subscribe,
    debugLabel: debugLabel,
    onAccessLost: onAccessLost,
  );

  @visibleForTesting
  static Future<NotificationDispatchContext> resolveNotificationContext({
    required String uid,
    required String chartId,
    required String? cachedRole,
    required NotificationPreferences? cachedPreferences,
    required Future<Map<String, dynamic>?> Function(String uid) getUserData,
    required Future<Map<String, dynamic>?> Function(String chartId)
    getChartData,
  }) => DatabaseHelpers.resolveNotificationContext(
    uid: uid,
    chartId: chartId,
    cachedRole: cachedRole,
    cachedPreferences: cachedPreferences,
    getUserData: getUserData,
    getChartData: getChartData,
  );

  @visibleForTesting
  static Future<ObservationRoleContext> resolveObservationRole({
    required String uid,
    required String? cachedRole,
    required Future<Map<String, dynamic>?> Function(String uid) getUserData,
  }) => DatabaseHelpers.resolveObservationRole(
    uid: uid,
    cachedRole: cachedRole,
    getUserData: getUserData,
  );
}
