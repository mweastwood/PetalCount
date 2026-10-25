import '../interop/firebase_admin.dart';

/// Extracts non-empty strings from a raw dynamic list.
List<String> extractStringList(dynamic rawList) {
  if (rawList is! List) return <String>[];
  return rawList.whereType<String>().where((item) => item.isNotEmpty).toList();
}

/// Fetches user documents in chunks via [FirestoreDatabase.getAll] and returns
/// a map of `userId -> Map<String, dynamic>.from(data)` for existing documents.
Future<Map<String, Map<String, dynamic>>> fetchUsersInBatches(
  FirestoreDatabase db,
  Iterable<String> userIds, {
  int chunkSize = 500,
  bool swallowChunkErrors = false,
}) async {
  final result = <String, Map<String, dynamic>>{};
  final userIdList = userIds.toList();
  if (userIdList.isEmpty) return result;

  for (var i = 0; i < userIdList.length; i += chunkSize) {
    final end =
        (i + chunkSize < userIdList.length) ? i + chunkSize : userIdList.length;
    final chunkUserIds = userIdList.sublist(i, end);
    final userRefs = chunkUserIds
        .map((userId) => db.collection('users').doc(userId))
        .toList();
    try {
      final userDocs = await db.getAll(userRefs);
      for (var j = 0; j < userDocs.length; j++) {
        final userDoc = userDocs[j];
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            final docId = userDoc.id.isNotEmpty
                ? userDoc.id
                : (j < chunkUserIds.length ? chunkUserIds[j] : '');
            if (docId.isNotEmpty) {
              result[docId] = Map<String, dynamic>.from(data);
            }
          }
        }
      }
    } catch (_) {
      if (!swallowChunkErrors) {
        rethrow;
      }
    }
  }

  return result;
}

/// Builds a standardized Firebase Cloud Messaging multicast payload map.
Map<String, dynamic> buildFcmMulticastPayload({
  required List<String> tokens,
  required String title,
  required String body,
  required Map<String, String> data,
  required String androidChannelId,
  int? apnsBadge,
}) {
  return <String, dynamic>{
    'tokens': tokens,
    'notification': {
      'title': title,
      'body': body,
    },
    'data': data,
    'android': {
      'priority': 'high',
      'notification': {
        'channelId': androidChannelId,
        'priority': 'high',
        'defaultSound': true,
      },
    },
    'apns': {
      'payload': {
        'aps': {
          'alert': {
            'title': title,
            'body': body,
          },
          'sound': 'default',
          if (apnsBadge != null) 'badge': apnsBadge,
        },
      },
    },
  };
}

/// Collects FCM tokens from [sentTokens] whose corresponding [SendResponse]
/// failed with an invalid or unregistered token error code.
Set<String> collectInvalidFcmTokens(
  BatchResponse response,
  List<String> sentTokens,
) {
  final invalidTokens = <String>{};
  if (response.failureCount <= 0 || response.responses.isEmpty) {
    return invalidTokens;
  }

  for (var i = 0; i < response.responses.length; i++) {
    final sendResponse = response.responses[i];
    if (!sendResponse.success && sendResponse.errorCode != null) {
      final errorCode = sendResponse.errorCode;
      if (errorCode == 'messaging/invalid-registration-token' ||
          errorCode == 'messaging/registration-token-not-registered') {
        if (i < sentTokens.length) {
          invalidTokens.add(sentTokens[i]);
        }
      }
    }
  }

  return invalidTokens;
}

/// Atomically prunes [invalidTokens] from user documents in Firestore and
/// updates [userCache] if provided.
Future<void> pruneInvalidUserFcmTokens(
  FirestoreDatabase db,
  Map<String, List<String>> tokensByUserId,
  Set<String> invalidTokens, {
  Map<String, Map<String, dynamic>>? userCache,
}) async {
  if (invalidTokens.isEmpty) return;

  for (final entry in tokensByUserId.entries) {
    final userId = entry.key;
    final tokens = entry.value;
    final invalidTokensForUser = tokens.where(invalidTokens.contains).toList();
    if (invalidTokensForUser.isNotEmpty) {
      await db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove(invalidTokensForUser),
      });

      final cached = userCache?[userId];
      if (cached != null) {
        cached['fcmTokens'] =
            tokens.where((token) => !invalidTokens.contains(token)).toList();
      }
    }
  }
}
