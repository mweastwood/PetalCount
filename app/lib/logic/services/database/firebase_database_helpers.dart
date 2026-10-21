import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/daily_entry.dart';
import '../../models/notification_preferences.dart';
import '../../models/user_role.dart';
import 'database_helpers.dart';

/// Shared pure/static helpers for [FirebaseDatabaseService] (batch chunking,
/// auth-gated streams, and access-lost error classification), plus forwards
/// to [DatabaseHelpers] for notification context/dispatch.
class FirebaseDatabaseHelpers {
  const FirebaseDatabaseHelpers._();

  static bool isAccessLostError(dynamic e) {
    bool matches(String s) {
      final n = s.toLowerCase().replaceAll('_', '-');
      return n == 'permission-denied' || n == 'not-found';
    }

    if (e is FirebaseException) {
      return matches(e.code);
    }
    try {
      final dynamic code = (e as dynamic).code;
      if (code is String && matches(code)) {
        return true;
      }
    } catch (_) {}
    final message = e.toString().toLowerCase().replaceAll('_', '-');
    if (message.contains('permission-denied') ||
        message.contains('not-found')) {
      return true;
    }
    return false;
  }

  static Future<void> commitBatchedOperations<T>({
    required List<void Function(T batch)> operations,
    required T Function() batchFactory,
    required Future<void> Function(T batch) commitBatch,
    int batchLimit = 450,
  }) async {
    if (operations.isEmpty) return;

    for (var i = 0; i < operations.length; i += batchLimit) {
      final end = (i + batchLimit < operations.length)
          ? i + batchLimit
          : operations.length;
      final chunk = operations.sublist(i, end);
      final batch = batchFactory();
      for (final op in chunk) {
        op(batch);
      }
      await commitBatch(batch);
    }
  }

  static Stream<T> buildGatedStreamHelper<T>({
    required String? Function() getKey,
    required Stream<dynamic> authStateChanges,
    required T emptyValue,
    required Stream<T> Function(String key) subscribe,
    String? debugLabel,
    Future<void> Function(String key)? onAccessLost,
  }) {
    late StreamController<T> controller;
    StreamSubscription<dynamic>? authSub;
    StreamSubscription<T>? dataSub;
    bool emittedEmptyOnError = false;

    void updateListener() {
      final key = getKey();
      dataSub?.cancel();
      if (key == null) {
        dataSub = null;
        if (!emittedEmptyOnError) {
          controller.add(emptyValue);
        }
        emittedEmptyOnError = false;
        return;
      }
      emittedEmptyOnError = false;
      dataSub = subscribe(key).listen(
        (data) {
          emittedEmptyOnError = false;
          controller.add(data);
        },
        onError: (e) {
          if (debugLabel != null) {
            debugPrint('Error streaming $debugLabel: $e');
          }
          if (isAccessLostError(e)) {
            emittedEmptyOnError = true;
            onAccessLost?.call(key);
          }
          controller.add(emptyValue);
        },
      );
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        updateListener();
        authSub = authStateChanges.listen((_) => updateListener());
      },
      onCancel: () {
        emittedEmptyOnError = false;
        dataSub?.cancel();
        dataSub = null;
        authSub?.cancel();
        authSub = null;
      },
    );

    return controller.stream;
  }

  static Stream<T> buildUserGatedStreamHelper<T>({
    required String? Function() getCurrentUserId,
    required Stream<dynamic> authStateChanges,
    required T emptyValue,
    required Stream<T> Function(String uid) subscribe,
    String? debugLabel,
    Future<void> Function(String uid)? onAccessLost,
  }) {
    return buildGatedStreamHelper<T>(
      getKey: getCurrentUserId,
      authStateChanges: authStateChanges,
      emptyValue: emptyValue,
      subscribe: subscribe,
      debugLabel: debugLabel,
      onAccessLost: onAccessLost,
    );
  }

  static Stream<T> buildAuthGatedStreamHelper<T>({
    required String? Function() getCurrentChartId,
    required Stream<dynamic> authStateChanges,
    required T emptyValue,
    required Stream<T> Function(String chartId) subscribe,
    String? debugLabel,
    Future<void> Function(String chartId)? onAccessLost,
  }) {
    return buildGatedStreamHelper<T>(
      getKey: getCurrentChartId,
      authStateChanges: authStateChanges,
      emptyValue: emptyValue,
      subscribe: subscribe,
      debugLabel: debugLabel,
      onAccessLost: onAccessLost,
    );
  }

  static NotificationPreferences parseChartNotificationPreferences(
    Map<String, dynamic>? chartData,
  ) => DatabaseHelpers.parseChartNotificationPreferences(chartData);

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

  static Future<ObservationRoleContext> resolveObservationRole({
    required String uid,
    required String? cachedRole,
    required Future<Map<String, dynamic>?> Function(String uid) getUserData,
  }) => DatabaseHelpers.resolveObservationRole(
    uid: uid,
    cachedRole: cachedRole,
    getUserData: getUserData,
  );

  static Future<void> dispatchLocalObservationNotifications({
    required DailyEntry resolvedDaily,
    required List<String> bipCodes,
    required UserRole userRole,
    required NotificationPreferences preferences,
  }) => DatabaseHelpers.dispatchLocalObservationNotifications(
    resolvedDaily: resolvedDaily,
    bipCodes: bipCodes,
    userRole: userRole,
    preferences: preferences,
  );
}
