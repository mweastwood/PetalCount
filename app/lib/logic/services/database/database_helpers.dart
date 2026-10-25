import 'package:core/core.dart';

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

/// Shared pure/static helpers for database services (notification preference
/// parsing, notification context resolution, observation role resolution, and
/// local observation notification dispatch) with no Firebase dependencies.
class DatabaseHelpers {
  const DatabaseHelpers._();

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
