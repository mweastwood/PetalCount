import 'package:core/core.dart';

import '../interop/firebase_admin.dart';
import 'fcm_multicast_helper.dart';
import 'reminder_models.dart';

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

  final collaboratorUserIdentifiers = extractStringList(chartData['userIds'])
      .where((userId) => userId != authorUserIdentifier)
      .toList();
  if (collaboratorUserIdentifiers.isEmpty) {
    return const CollaboratorNotificationResult(
      notificationsDispatched: 0,
      tokensNotified: 0,
    );
  }

  // Batch fetch all collaborator user documents in chunks via db.getAll
  final collaboratorUsers = await fetchUsersInBatches(
    database,
    collaboratorUserIdentifiers,
  );

  var notificationsDispatched = 0;
  var tokensNotified = 0;

  for (final collaboratorIdentifier in collaboratorUserIdentifiers) {
    final userData = collaboratorUsers[collaboratorIdentifier];
    if (userData == null) {
      continue;
    }

    final recipientTokens =
        extractStringList(userData['fcmTokens']).toSet().toList();
    if (recipientTokens.isEmpty) {
      continue;
    }

    final recipientRole = UserRole.fromString(userData['role'] as String?);
    final message = CycleNotificationFormatter.collaboratorFertilityPushMessage(
      recipientRole: recipientRole,
      preferences: preferences,
      peakDayLabel: peakDayLabel,
    );

    final multicastResponse = await messaging.sendEachForMulticast(
      buildFcmMulticastPayload(
        tokens: recipientTokens,
        title: message.title,
        body: message.body,
        data: {
          'chartId': chartIdentifier,
          'date': modifiedDateKey,
          'type': 'collaborator_fertility_alert',
        },
        androidChannelId: 'fertility_alerts',
      ),
    );

    if (multicastResponse.successCount > 0) {
      notificationsDispatched++;
      tokensNotified += multicastResponse.successCount;
    }

    final invalidRecipientTokens = collectInvalidFcmTokens(
      multicastResponse,
      recipientTokens,
    );
    if (invalidRecipientTokens.isNotEmpty) {
      await pruneInvalidUserFcmTokens(
        database,
        {collaboratorIdentifier: recipientTokens},
        invalidRecipientTokens,
      );
    }
  }

  return CollaboratorNotificationResult(
    notificationsDispatched: notificationsDispatched,
    tokensNotified: tokensNotified,
  );
}
