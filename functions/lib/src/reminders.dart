import 'package:core/core.dart';
import 'interop/firebase_admin.dart';
import 'interop/node_interop.dart';

class LocalTimeInfo {
  final int hour;
  final String dateKey;

  const LocalTimeInfo({required this.hour, required this.dateKey});

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'dateKey': dateKey,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTimeInfo &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          dateKey == other.dateKey;

  @override
  int get hashCode => Object.hash(hour, dateKey);

  @override
  String toString() => 'LocalTimeInfo(hour: $hour, dateKey: $dateKey)';
}

class DailyRemindersResult {
  final int chartsChecked;
  final int remindersSent;
  final int tokensNotified;

  const DailyRemindersResult({
    required this.chartsChecked,
    required this.remindersSent,
    required this.tokensNotified,
  });

  Map<String, dynamic> toJson() => {
        'chartsChecked': chartsChecked,
        'remindersSent': remindersSent,
        'tokensNotified': tokensNotified,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRemindersResult &&
          runtimeType == other.runtimeType &&
          chartsChecked == other.chartsChecked &&
          remindersSent == other.remindersSent &&
          tokensNotified == other.tokensNotified;

  @override
  int get hashCode => Object.hash(chartsChecked, remindersSent, tokensNotified);

  @override
  String toString() =>
      'DailyRemindersResult(chartsChecked: $chartsChecked, remindersSent: $remindersSent, tokensNotified: $tokensNotified)';
}

class CollaboratorNotificationResult {
  final int notificationsDispatched;
  final int tokensNotified;

  const CollaboratorNotificationResult({
    required this.notificationsDispatched,
    required this.tokensNotified,
  });

  Map<String, dynamic> toJson() => {
        'notificationsDispatched': notificationsDispatched,
        'tokensNotified': tokensNotified,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaboratorNotificationResult &&
          runtimeType == other.runtimeType &&
          notificationsDispatched == other.notificationsDispatched &&
          tokensNotified == other.tokensNotified;

  @override
  int get hashCode => Object.hash(notificationsDispatched, tokensNotified);

  @override
  String toString() =>
      'CollaboratorNotificationResult(notificationsDispatched: $notificationsDispatched, tokensNotified: $tokensNotified)';
}

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

List<String> _extractStringList(dynamic rawList) {
  if (rawList is! List) return <String>[];
  return rawList.whereType<String>().where((item) => item.isNotEmpty).toList();
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

  final userIds = _extractStringList(chart['userIds']);
  if (userIds.isEmpty) {
    return (reminderSent: false, tokensNotified: 0);
  }

  // Collect all unique FCM tokens for all collaborators on this chart
  final tokensByUserId = <String, List<String>>{};
  final uniqueTokensSet = <String>{};

  for (final userId in userIds) {
    final userData = userCache[userId];
    if (userData != null) {
      final tokens = _extractStringList(userData['fcmTokens']);
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
  final response = await messaging.sendEachForMulticast({
    'tokens': allTokens,
    'notification': {
      'title': reminderMessage.title,
      'body': reminderMessage.body,
    },
    'data': {
      'chartId': chartId,
      'date': dateKey,
      'type': 'daily_reminder',
    },
    'android': {
      'priority': 'high',
      'notification': {
        'channelId': 'daily_logging_reminders',
        'priority': 'high',
        'defaultSound': true,
      },
    },
    'apns': {
      'payload': {
        'aps': {
          'alert': {
            'title': reminderMessage.title,
            'body': reminderMessage.body,
          },
          'sound': 'default',
          'badge': 1,
        },
      },
    },
  });

  final tokensNotified = response.successCount;
  final reminderSent = tokensNotified > 0;

  // Prune stale / unregistered tokens atomically
  if (response.failureCount > 0) {
    final invalidTokens = <String>{};
    for (var i = 0; i < response.responses.length; i++) {
      final sendResponse = response.responses[i];
      if (!sendResponse.success && sendResponse.errorCode != null) {
        final errorCode = sendResponse.errorCode;
        if (errorCode == 'messaging/invalid-registration-token' ||
            errorCode == 'messaging/registration-token-not-registered') {
          if (i < allTokens.length) {
            invalidTokens.add(allTokens[i]);
          }
        }
      }
    }

    if (invalidTokens.isNotEmpty) {
      for (final entry in tokensByUserId.entries) {
        final userId = entry.key;
        final tokens = entry.value;
        final invalidTokensForUser =
            tokens.where(invalidTokens.contains).toList();
        if (invalidTokensForUser.isNotEmpty) {
          await db.collection('users').doc(userId).update({
            'fcmTokens': FieldValue.arrayRemove(invalidTokensForUser),
          });

          final cached = userCache[userId];
          if (cached != null) {
            cached['fcmTokens'] = tokens
                .where((token) => !invalidTokens.contains(token))
                .toList();
          }
        }
      }
    }
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
      final userIds = _extractStringList(chart['userIds']);
      if (userIds.isNotEmpty) {
        usersNeedingTimezone.add(userIds.first);
      }
    }
  }

  // Batch fetch users in chunks of 500
  final timezoneCache = <String, String>{};
  if (usersNeedingTimezone.isNotEmpty) {
    final userIds = usersNeedingTimezone.toList();
    const chunkSize = 500;
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final end =
          (i + chunkSize < userIds.length) ? i + chunkSize : userIds.length;
      final chunkUserIds = userIds.sublist(i, end);
      final userRefs = chunkUserIds
          .map((userId) => db.collection('users').doc(userId))
          .toList();
      try {
        final userDocs = await db.getAll(userRefs);
        for (final userDoc in userDocs) {
          if (userDoc.exists) {
            final userData = userDoc.data();
            final rawTz = userData?['timezone'];
            if (rawTz is String && rawTz.trim().isNotEmpty) {
              timezoneCache[userDoc.id] = rawTz.trim();
            }
          }
        }
      } catch (_) {
        // Graceful fallback if batch fetch fails
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
      final userIds = _extractStringList(chart['userIds']);
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
    final userIds = _extractStringList(item.chart['userIds']);
    distinctUserIds.addAll(userIds);
  }

  final userCache = <String, Map<String, dynamic>>{};
  if (distinctUserIds.isNotEmpty) {
    final userIds = distinctUserIds.toList();
    const chunkSize = 500;
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final end =
          (i + chunkSize < userIds.length) ? i + chunkSize : userIds.length;
      final chunkUserIds = userIds.sublist(i, end);
      final userRefs = chunkUserIds
          .map((userId) => db.collection('users').doc(userId))
          .toList();
      final userDocs = await db.getAll(userRefs);
      for (final userDoc in userDocs) {
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            userCache[userDoc.id] = Map<String, dynamic>.from(data);
          }
        }
      }
    }
  }

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

/// Dispatches FCM push notifications to partner/collaborator devices when a new
/// observation is logged on a fertile or Peak-count day.
Future<CollaboratorNotificationResult> processCollaboratorFertilityNotification(
  FirestoreDatabase database,
  MessagingService messaging,
  String chartIdentifier,
  Map<String, dynamic>? previousCycleData,
  Map<String, dynamic>? currentCycleData,
) async {
  if (currentCycleData == null || currentCycleData['dailyEntries'] is! Map) {
    return const CollaboratorNotificationResult(
      notificationsDispatched: 0,
      tokensNotified: 0,
    );
  }

  final previousEntries =
      (previousCycleData?['dailyEntries'] as Map?) ?? const {};
  final currentEntries = currentCycleData['dailyEntries'] as Map;

  // Find a date entry where a new observation was added
  String? modifiedDateKey;
  Map<String, dynamic>? modifiedDailyEntry;
  String? authorUserIdentifier;

  for (final entry in currentEntries.entries) {
    final dateKey = entry.key.toString();
    final rawCurrentEntry = entry.value;
    if (rawCurrentEntry is! Map) continue;
    final currentEntry = Map<String, dynamic>.from(rawCurrentEntry);

    final currentObservations = currentEntry['observations'] is List
        ? (currentEntry['observations'] as List)
        : const [];
    if (currentObservations.isEmpty) {
      continue;
    }

    final rawPreviousEntry = previousEntries[dateKey];
    final previousObservations =
        (rawPreviousEntry is Map && rawPreviousEntry['observations'] is List)
            ? (rawPreviousEntry['observations'] as List)
            : const [];

    if (currentObservations.length > previousObservations.length) {
      modifiedDateKey = dateKey;
      modifiedDailyEntry = currentEntry;
      final previousIds = <String>{};
      for (final obs in previousObservations) {
        if (obs is Map && obs['id'] is String) {
          previousIds.add(obs['id'] as String);
        }
      }

      Map? newlyAddedObservation;
      for (final obs in currentObservations) {
        if (obs is Map) {
          final id = obs['id'];
          if (id is String && id.isNotEmpty && !previousIds.contains(id)) {
            newlyAddedObservation = obs;
            break;
          }
        }
      }
      if (newlyAddedObservation == null) {
        final lastObs = currentObservations.last;
        if (lastObs is Map) {
          newlyAddedObservation = lastObs;
        }
      }
      final rawAuthor = newlyAddedObservation?['userId'];
      if (rawAuthor is String) {
        authorUserIdentifier = rawAuthor;
      }
      break;
    }
  }

  if (modifiedDateKey == null || modifiedDailyEntry == null) {
    return const CollaboratorNotificationResult(
      notificationsDispatched: 0,
      tokensNotified: 0,
    );
  }

  final stampType = modifiedDailyEntry['stampType']?.toString() ?? '';
  final rawPeakDayLabel = modifiedDailyEntry['peakDayLabel'];
  final peakDayLabel = rawPeakDayLabel is String ? rawPeakDayLabel : null;
  final isFertileStamp = StampType.isFertileStampValue(stampType);
  final hasPeakLabel = peakDayLabel != null && peakDayLabel.trim().isNotEmpty;
  final isPeakDayFlag = modifiedDailyEntry['isPeakDay'] == true;

  if (!isFertileStamp && !hasPeakLabel && !isPeakDayFlag) {
    return const CollaboratorNotificationResult(
      notificationsDispatched: 0,
      tokensNotified: 0,
    );
  }

  final chartSnapshot =
      await database.collection('charts').doc(chartIdentifier).get();
  if (!chartSnapshot.exists) {
    return const CollaboratorNotificationResult(
      notificationsDispatched: 0,
      tokensNotified: 0,
    );
  }

  final chartData = chartSnapshot.data() ?? <String, dynamic>{};
  final rawPrefs = chartData['notificationPreferences'];
  final preferences = NotificationPreferences.fromMap(
    rawPrefs is Map ? Map<String, dynamic>.from(rawPrefs) : null,
  );

  if (!preferences.fertilePatternAlerts &&
      !preferences.partnerSupportReminders) {
    return const CollaboratorNotificationResult(
      notificationsDispatched: 0,
      tokensNotified: 0,
    );
  }

  final collaboratorUserIdentifiers = _extractStringList(chartData['userIds'])
      .where((userId) => userId != authorUserIdentifier)
      .toList();
  if (collaboratorUserIdentifiers.isEmpty) {
    return const CollaboratorNotificationResult(
      notificationsDispatched: 0,
      tokensNotified: 0,
    );
  }

  var notificationsDispatched = 0;
  var tokensNotified = 0;

  for (final collaboratorIdentifier in collaboratorUserIdentifiers) {
    final userSnapshot =
        await database.collection('users').doc(collaboratorIdentifier).get();
    if (!userSnapshot.exists) {
      continue;
    }

    final userData = userSnapshot.data() ?? <String, dynamic>{};
    final recipientTokens =
        _extractStringList(userData['fcmTokens']).toSet().toList();
    if (recipientTokens.isEmpty) {
      continue;
    }

    final recipientRole = UserRole.fromString(userData['role'] as String?);
    final message = CycleNotificationFormatter.collaboratorFertilityPushMessage(
      recipientRole: recipientRole,
      preferences: preferences,
      peakDayLabel: peakDayLabel,
    );

    final multicastResponse = await messaging.sendEachForMulticast({
      'tokens': recipientTokens,
      'notification': {
        'title': message.title,
        'body': message.body,
      },
      'data': {
        'chartId': chartIdentifier,
        'date': modifiedDateKey,
        'type': 'collaborator_fertility_alert',
      },
      'android': {
        'priority': 'high',
        'notification': {
          'channelId': 'fertility_alerts',
          'priority': 'high',
          'defaultSound': true,
        },
      },
      'apns': {
        'payload': {
          'aps': {
            'alert': {
              'title': message.title,
              'body': message.body,
            },
            'sound': 'default',
          },
        },
      },
    });

    if (multicastResponse.successCount > 0) {
      notificationsDispatched++;
      tokensNotified += multicastResponse.successCount;
    }

    if (multicastResponse.failureCount > 0 &&
        multicastResponse.responses.isNotEmpty) {
      final invalidRecipientTokens = <String>[];
      for (var i = 0; i < multicastResponse.responses.length; i++) {
        final sendResponse = multicastResponse.responses[i];
        if (!sendResponse.success && sendResponse.errorCode != null) {
          final errorCode = sendResponse.errorCode;
          if (errorCode == 'messaging/invalid-registration-token' ||
              errorCode == 'messaging/registration-token-not-registered') {
            if (i < recipientTokens.length) {
              invalidRecipientTokens.add(recipientTokens[i]);
            }
          }
        }
      }

      if (invalidRecipientTokens.isNotEmpty) {
        await database.collection('users').doc(collaboratorIdentifier).update({
          'fcmTokens': FieldValue.arrayRemove(invalidRecipientTokens),
        });
      }
    }
  }

  return CollaboratorNotificationResult(
    notificationsDispatched: notificationsDispatched,
    tokensNotified: tokensNotified,
  );
}
