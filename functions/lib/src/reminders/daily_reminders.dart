import 'package:core/core.dart';

import '../interop/firebase_admin.dart';
import '../interop/node_interop.dart';
import 'fcm_multicast_helper.dart';
import 'reminder_models.dart';

/// Returns the current local hour (0-23) and formatted date key (YYYY-MM-DD)
/// for a specific IANA timezone string. Defaults to 'America/Los_Angeles'.
LocalTimeInfo getLocalTimeInfo([
  DateTime? now,
  String timeZone = 'America/Los_Angeles',
]) {
  final effectiveNow = now ?? DateTime.now();
  try {
    final formatted = formatLocalTimeInZone(effectiveNow, timeZone);
    return LocalTimeInfo(hour: formatted.hour, dateKey: formatted.dateKey);
  } catch (_) {
    // Fallback to America/Los_Angeles if invalid timezone string is provided
    final fallback = formatLocalTimeInZone(effectiveNow, 'America/Los_Angeles');
    return LocalTimeInfo(hour: fallback.hour, dateKey: fallback.dateKey);
  }
}

/// Checks if a chart has any observations logged for the specified dateKey.
/// Reads directly from the Cycle document's dailyEntries map, with a fallback
/// to the legacy dailyEntries subcollection only when the cycle document does
/// not contain a dailyEntries map.
Future<bool> checkChartHasObservationForDate(
  FirestoreDatabase db,
  String chartId,
  String dateKey,
) async {
  final chartRef = db.collection('charts').doc(chartId);

  // 1. Find the cycle that contains or starts on/before dateKey
  final eligibleCyclesSnapshot = await chartRef
      .collection('cycles')
      .where('startDate', '<=', dateKey)
      .orderBy('startDate', 'desc')
      .limit(1)
      .get();

  if (eligibleCyclesSnapshot.empty) {
    return false;
  }

  final targetCycleDoc = eligibleCyclesSnapshot.docs.first;
  final cycleData = targetCycleDoc.data();

  // Primary source of truth: top-level dailyEntries map on cycle document
  if (cycleData != null && cycleData['dailyEntries'] is Map) {
    final dailyEntries = cycleData['dailyEntries'] as Map;
    final entry = dailyEntries[dateKey];
    if (entry is Map) {
      final observations = entry['observations'];
      if (observations is List && observations.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  // Legacy fallback: check dailyEntries subcollection only when dailyEntries map is absent
  final cycleRef = targetCycleDoc.ref;
  if (cycleRef != null) {
    final dailyEntryDoc =
        await cycleRef.collection('dailyEntries').doc(dateKey).get();

    if (dailyEntryDoc.exists) {
      final data = dailyEntryDoc.data();
      final observations = data?['observations'];
      if (observations is List && observations.isNotEmpty) {
        return true;
      }
    }
  }

  return false;
}

class _EligibleChart {
  final Map<String, dynamic> chart;
  final String chartId;
  final String dateKey;

  const _EligibleChart({
    required this.chart,
    required this.chartId,
    required this.dateKey,
  });
}

/// Processes reminder notifications for a single eligible chart.
Future<({bool reminderSent, int tokensNotified})> _processSingleChartReminder(
  FirestoreDatabase db,
  MessagingService messaging,
  _EligibleChart eligibleChart,
  Map<String, Map<String, dynamic>> userCache,
) async {
  final chart = eligibleChart.chart;
  final chartId = eligibleChart.chartId;
  final dateKey = eligibleChart.dateKey;

  final hasObservation = await checkChartHasObservationForDate(
    db,
    chartId,
    dateKey,
  );

  if (hasObservation) {
    // An observation has already been logged for today by user or partner
    return (reminderSent: false, tokensNotified: 0);
  }

  final userIds = extractStringList(chart['userIds']);
  if (userIds.isEmpty) {
    return (reminderSent: false, tokensNotified: 0);
  }

  // Collect all unique FCM tokens for all collaborators on this chart
  final tokensByUserId = <String, List<String>>{};
  final uniqueTokensSet = <String>{};

  for (final userId in userIds) {
    final userData = userCache[userId];
    if (userData != null) {
      final tokens = extractStringList(userData['fcmTokens']);
      if (tokens.isNotEmpty) {
        tokensByUserId[userId] = tokens;
        uniqueTokensSet.addAll(tokens);
      }
    }
  }

  final allTokens = uniqueTokensSet.toList();
  if (allTokens.isEmpty) {
    return (reminderSent: false, tokensNotified: 0);
  }

  final reminderMessage = CycleNotificationFormatter.dailyReminderPushMessage();

  // Dispatch Multicast Push Notification via Firebase Cloud Messaging
  final response = await messaging.sendEachForMulticast(
    buildFcmMulticastPayload(
      tokens: allTokens,
      title: reminderMessage.title,
      body: reminderMessage.body,
      data: {
        'chartId': chartId,
        'date': dateKey,
        'type': 'daily_reminder',
      },
      androidChannelId: 'daily_logging_reminders',
      apnsBadge: 1,
    ),
  );

  final tokensNotified = response.successCount;
  final reminderSent = tokensNotified > 0;

  // Prune stale / unregistered tokens atomically
  final invalidTokens = collectInvalidFcmTokens(response, allTokens);
  if (invalidTokens.isNotEmpty) {
    await pruneInvalidUserFcmTokens(
      db,
      tokensByUserId,
      invalidTokens,
      userCache: userCache,
    );
  }

  return (reminderSent: reminderSent, tokensNotified: tokensNotified);
}

/// Process all active charts and send 9:00 PM reminder notifications if no observations logged.
Future<DailyRemindersResult> processDailyReminders(
  FirestoreDatabase db,
  MessagingService messaging, {
  DateTime? now,
  int? targetHour,
  String? forceChartId,
}) async {
  final effectiveNow = now ?? DateTime.now();
  final effectiveTargetHour = targetHour ?? 21; // 9:00 PM (21:00)
  final trimmedForceChartId = forceChartId?.trim();
  final hasForceChartId =
      trimmedForceChartId != null && trimmedForceChartId.isNotEmpty;

  List<DocumentSnapshot> chartDocs;
  if (forceChartId != null) {
    if (!hasForceChartId) {
      return const DailyRemindersResult(
        chartsChecked: 0,
        remindersSent: 0,
        tokensNotified: 0,
      );
    }
    final chartDoc =
        await db.collection('charts').doc(trimmedForceChartId).get();
    if (!chartDoc.exists) {
      return const DailyRemindersResult(
        chartsChecked: 0,
        remindersSent: 0,
        tokensNotified: 0,
      );
    }
    chartDocs = [chartDoc];
  } else {
    final chartsSnapshot = await db.collection('charts').get();
    if (chartsSnapshot.empty) {
      return const DailyRemindersResult(
        chartsChecked: 0,
        remindersSent: 0,
        tokensNotified: 0,
      );
    }
    chartDocs = chartsSnapshot.docs;
  }

  // Collect distinct primary user IDs needing timezone lookup
  final usersNeedingTimezone = <String>{};
  for (final chartDoc in chartDocs) {
    final chart = chartDoc.data() ?? <String, dynamic>{};
    final chartTimezone = chart['timezone'] as String?;
    final reminderEnabled = chart['reminderEnabled'];
    if ((hasForceChartId || reminderEnabled != false) &&
        (chartTimezone == null || chartTimezone.isEmpty)) {
      final userIds = extractStringList(chart['userIds']);
      if (userIds.isNotEmpty) {
        usersNeedingTimezone.add(userIds.first);
      }
    }
  }

  // Batch fetch users in chunks of 500
  final timezoneCache = <String, String>{};
  if (usersNeedingTimezone.isNotEmpty) {
    final fetchedTimezoneUsers = await fetchUsersInBatches(
      db,
      usersNeedingTimezone,
      swallowChunkErrors: true,
    );
    for (final entry in fetchedTimezoneUsers.entries) {
      final rawTz = entry.value['timezone'];
      if (rawTz is String && rawTz.trim().isNotEmpty) {
        timezoneCache[entry.key] = rawTz.trim();
      }
    }
  }

  final eligibleCharts = <_EligibleChart>[];
  final backfillFutures = <Future<void>>[];

  for (final chartDoc in chartDocs) {
    final chart = Map<String, dynamic>.from(
      chartDoc.data() ?? <String, dynamic>{},
    );
    final chartId =
        chartDoc.id.isNotEmpty ? chartDoc.id : (chart['id'] as String? ?? '');
    if (chartId.isEmpty) {
      continue;
    }

    // Skip charts that disabled reminders (unless explicitly forced)
    if (!hasForceChartId && chart['reminderEnabled'] == false) {
      continue;
    }

    var timezone = chart['timezone'] as String?;
    if (timezone == null || timezone.isEmpty) {
      final userIds = extractStringList(chart['userIds']);
      final primaryUserId = userIds.isNotEmpty ? userIds.first : null;
      if (primaryUserId != null && timezoneCache.containsKey(primaryUserId)) {
        timezone = timezoneCache[primaryUserId];
        final docRef = chartDoc.ref;
        if (docRef != null && timezone != null) {
          backfillFutures.add(
            docRef.set({'timezone': timezone}, merge: true).catchError((_) {
              // Graceful fallback if individual backfill write fails
            }),
          );
        }
      }
    }

    if (timezone == null || timezone.isEmpty) {
      timezone = 'America/Los_Angeles';
    }
    chart['timezone'] = timezone;
    final localTime = getLocalTimeInfo(effectiveNow, timezone);

    // Only process charts that are currently in their 9:00 PM hour (unless forced)
    if (!hasForceChartId && localTime.hour != effectiveTargetHour) {
      continue;
    }

    eligibleCharts.add(
      _EligibleChart(
        chart: chart,
        chartId: chartId,
        dateKey: localTime.dateKey,
      ),
    );
  }

  if (backfillFutures.isNotEmpty) {
    await Future.wait(backfillFutures);
  }

  if (eligibleCharts.isEmpty) {
    return const DailyRemindersResult(
      chartsChecked: 0,
      remindersSent: 0,
      tokensNotified: 0,
    );
  }

  // Aggregate all unique userIds across all eligible charts
  final distinctUserIds = <String>{};
  for (final item in eligibleCharts) {
    final userIds = extractStringList(item.chart['userIds']);
    distinctUserIds.addAll(userIds);
  }

  final userCache = await fetchUsersInBatches(db, distinctUserIds);

  final results = await Future.wait(
    eligibleCharts.map(
      (item) => _processSingleChartReminder(db, messaging, item, userCache),
    ),
  );

  var remindersSent = 0;
  var tokensNotified = 0;
  for (final result in results) {
    if (result.reminderSent) {
      remindersSent++;
    }
    tokensNotified += result.tokensNotified;
  }

  return DailyRemindersResult(
    chartsChecked: eligibleCharts.length,
    remindersSent: remindersSent,
    tokensNotified: tokensNotified,
  );
}
