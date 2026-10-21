import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/daily_entry.dart';
import '../../models/notification_preferences.dart';
import '../../models/user_role.dart';
import '../creighton_logic.dart';
import '../services.dart';

class NotificationDispatchContext {
  final UserRole userRole;
  final NotificationPreferences preferences;
  final String? roleToCache;
  final NotificationPreferences preferencesToCache;

  const NotificationDispatchContext({
    required this.userRole,
    required this.preferences,
    required this.roleToCache,
    required this.preferencesToCache,
  });
}

class ObservationRoleContext {
  final UserRole userRole;
  final String? roleToCache;

  const ObservationRoleContext({
    required this.userRole,
    required this.roleToCache,
  });
}

/// Shared pure/static helpers for [FirebaseDatabaseService] and
/// [InMemoryDatabaseService] (batch chunking, auth-gated streams, access-lost
/// error classification, and notification context/dispatch).
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
  ) {
    if (chartData == null) return const NotificationPreferences();
    final raw = chartData['notificationPreferences'];
    if (raw != null) {
      return NotificationPreferences.fromMap(Map<String, dynamic>.from(raw));
    }
    final reminder = (chartData['reminderEnabled'] as bool?) ?? true;
    return NotificationPreferences(dailyLoggingReminder: reminder);
  }

  static Future<NotificationDispatchContext> resolveNotificationContext({
    required String uid,
    required String chartId,
    required String? cachedRole,
    required NotificationPreferences? cachedPreferences,
    required Future<Map<String, dynamic>?> Function(String uid) getUserData,
    required Future<Map<String, dynamic>?> Function(String chartId)
    getChartData,
  }) async {
    if (cachedRole != null && cachedPreferences != null) {
      return NotificationDispatchContext(
        userRole: UserRole.fromString(cachedRole),
        preferences: cachedPreferences,
        roleToCache: cachedRole,
        preferencesToCache: cachedPreferences,
      );
    }

    if (cachedRole != null) {
      final chartData = await getChartData(chartId);
      final preferences = parseChartNotificationPreferences(chartData);
      return NotificationDispatchContext(
        userRole: UserRole.fromString(cachedRole),
        preferences: preferences,
        roleToCache: cachedRole,
        preferencesToCache: preferences,
      );
    }

    if (cachedPreferences != null) {
      final userData = await getUserData(uid);
      final userRoleStr = (userData?['role'] as String?) ?? 'wife';
      return NotificationDispatchContext(
        userRole: UserRole.fromString(userRoleStr),
        preferences: cachedPreferences,
        roleToCache: userRoleStr,
        preferencesToCache: cachedPreferences,
      );
    }

    final results = await Future.wait([
      getUserData(uid),
      getChartData(chartId),
    ]);
    final userData = results[0];
    final chartData = results[1];

    final userRoleStr = (userData?['role'] as String?) ?? 'wife';
    final preferences = parseChartNotificationPreferences(chartData);

    return NotificationDispatchContext(
      userRole: UserRole.fromString(userRoleStr),
      preferences: preferences,
      roleToCache: userRoleStr,
      preferencesToCache: preferences,
    );
  }

  static Future<ObservationRoleContext> resolveObservationRole({
    required String uid,
    required String? cachedRole,
    required Future<Map<String, dynamic>?> Function(String uid) getUserData,
  }) async {
    if (cachedRole != null) {
      return ObservationRoleContext(
        userRole: UserRole.fromString(cachedRole),
        roleToCache: cachedRole,
      );
    }

    UserRole userRole = UserRole.wife;
    String? roleToCache;
    try {
      final userData = await getUserData(uid);
      final userRoleString = userData?['role'] as String?;
      userRole = UserRole.fromString(userRoleString);
      if (userData != null) {
        roleToCache = userRole.code;
      }
    } catch (error) {
      Services.logger.warning(
        'Failed to fetch user role for observation: $error',
      );
    }

    return ObservationRoleContext(userRole: userRole, roleToCache: roleToCache);
  }

  static Future<void> dispatchLocalObservationNotifications({
    required DailyEntry resolvedDaily,
    required List<String> bipCodes,
    required UserRole userRole,
    required NotificationPreferences preferences,
  }) async {
    final isFertile = CreightonLogic.isFertileMucusPattern(
      entry: resolvedDaily,
      bipCodes: bipCodes,
    );
    final peakLabel = resolvedDaily.peakDayLabel;

    if (preferences.fertilePatternAlerts && isFertile) {
      await Services.notifications.notifyFertilePattern(role: userRole);
    }
    if (preferences.fertilePatternAlerts && peakLabel != null) {
      await Services.notifications.notifyPeakDay(
        role: userRole,
        peakLabel: peakLabel,
      );
    }
    if (preferences.partnerSupportReminders &&
        (isFertile || peakLabel != null || resolvedDaily.isPeakDay)) {
      await Services.notifications.notifyKindnessSupport(role: userRole);
    }
  }
}
