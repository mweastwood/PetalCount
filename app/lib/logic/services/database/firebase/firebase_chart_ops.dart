part of '../firebase_database_service.dart';

mixin _FirebaseChartOps on _FirebaseDatabaseServiceBase {
  @override
  Future<void> createChart() async {
    final user = currentUser;
    if (user == null) return;

    final chartRef = _db.collection('charts').doc();
    final chartId = chartRef.id;

    String? userTimezone;
    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userTimezone = userDoc.data()?['timezone'] as String?;
      }
    } catch (e) {
      Services.logger.warning(
        'Error fetching user timezone on createChart',
        category: 'chart',
        error: e,
      );
    }

    await chartRef.set({
      'id': chartId,
      'userIds': [user.uid],
      'emails': [user.email],
      'reminderEnabled': true,
      if (userTimezone != null && userTimezone.isNotEmpty)
        'timezone': userTimezone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(user.uid).set({
      'chartId': chartId,
      'uid': user.uid,
      'email': user.email ?? '',
    }, SetOptions(merge: true));

    _cachedChartId = chartId;
    _authController.add(user);
  }

  @override
  Future<void> invitePartner(String partnerEmail) async {
    final user = currentUser;
    final chartId = currentChartId;
    if (user == null || chartId == null) {
      throw Exception("No active session or chart found.");
    }

    final cleanEmail = partnerEmail.trim().toLowerCase();

    // Create an invitation in the invitations collection
    await _db.collection('invitations').doc(cleanEmail).set({
      'invitationId': cleanEmail,
      'senderUid': user.uid,
      'senderEmail': user.email,
      'chartId': chartId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final user = currentUser;
    if (user == null || user.email == null) return [];

    final cleanEmail = user.email!.trim().toLowerCase();
    final snap = await _db
        .collection('invitations')
        .where('invitationId', isEqualTo: cleanEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    return snap.docs.map((doc) => doc.data()).toList();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolvePendingInvitation(
    String invitationId,
    User user,
  ) async {
    DocumentSnapshot<Map<String, dynamic>>? doc;
    final docRef = _db.collection('invitations').doc(invitationId);

    try {
      final snap = await docRef.get();
      if (snap.exists) {
        doc = snap;
      }
    } catch (e) {
      Services.logger.debug(
        'Direct invitation doc lookup failed, falling back to email query',
        category: 'chart',
        metadata: {'invitationId': invitationId, 'error': e.toString()},
      );
    }

    if (doc == null) {
      final cleanEmail = user.email?.trim().toLowerCase() ?? '';
      final snap = await _db
          .collection('invitations')
          .where('invitationId', isEqualTo: cleanEmail)
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isNotEmpty) {
        doc = snap.docs.first;
      }
    }

    if (doc == null) {
      Services.logger.warning(
        'Invitation not found or already processed',
        category: 'chart',
        metadata: {'invitationId': invitationId, 'uid': user.uid},
      );
      return null;
    }

    return doc;
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    final user = currentUser;
    if (user == null) return;

    final doc = await _resolvePendingInvitation(invitationId, user);
    if (doc == null) {
      throw Exception("Invitation not found");
    }

    final data = doc.data()!;
    final chartId = data['chartId'] as String;

    // Join the chart
    final chartRef = _db.collection('charts').doc(chartId);
    final updates = <String, dynamic>{
      'userIds': FieldValue.arrayUnion([user.uid]),
    };
    if (user.email != null && user.email!.isNotEmpty) {
      updates['emails'] = FieldValue.arrayUnion([user.email]);
    }
    await chartRef.update(updates);

    // Update user profile
    await _db.collection('users').doc(user.uid).set({
      'chartId': chartId,
      'uid': user.uid,
      'email': user.email ?? '',
    }, SetOptions(merge: true));

    // Update invitation status
    await doc.reference.update({'status': 'accepted'});

    _cachedChartId = chartId;
    _authController.add(user);
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    final user = currentUser;
    if (user == null) return;

    final doc = await _resolvePendingInvitation(invitationId, user);
    if (doc == null) {
      return;
    }

    await doc.reference.update({'status': 'declined'});
  }

  @override
  Future<void> unlinkChart() async {
    final user = currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'chartId': null,
    }, SetOptions(merge: true));
    _cachedChartId = null;
    _authController.add(user);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamAvailableCharts() {
    return _buildUserGatedStream<List<Map<String, dynamic>>>(
      emptyValue: const [],
      debugLabel: 'availableCharts',
      subscribe: (uid) => _db
          .collection('charts')
          .where('userIds', arrayContains: uid)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList()),
    );
  }

  @override
  Future<void> setActiveChart(String chartId) async {
    final user = currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'chartId': chartId,
    }, SetOptions(merge: true));
    _cachedChartId = chartId;
    _authController.add(user);
  }

  Future<List<DocumentReference>> _collectChartSubcollectionRefs(
    DocumentReference chartRef,
  ) async {
    final results = await Future.wait([
      chartRef.collection('cycles').get(),
      chartRef.collection('supplements').get(),
      chartRef.collection('supplementLogs').get(),
    ]);

    final cyclesSnapshot = results[0];
    final supplementsSnapshot = results[1];
    final supplementLogsSnapshot = results[2];

    final List<DocumentReference> toDelete = [];

    for (final doc in cyclesSnapshot.docs) {
      final dailySnapshot = await doc.reference
          .collection('dailyEntries')
          .get();
      for (final dailyDoc in dailySnapshot.docs) {
        toDelete.add(dailyDoc.reference);
      }
      toDelete.add(doc.reference);
    }

    for (final doc in supplementsSnapshot.docs) {
      toDelete.add(doc.reference);
    }

    for (final doc in supplementLogsSnapshot.docs) {
      toDelete.add(doc.reference);
    }

    return toDelete;
  }

  @override
  Future<void> deleteChart(String chartId) async {
    final user = currentUser;
    if (user == null) return;

    final chartRef = _db.collection('charts').doc(chartId);
    final toDelete = await _collectChartSubcollectionRefs(chartRef);
    toDelete.add(chartRef);

    await _deleteDocumentsInBatches(toDelete);
    _cachedPreferencesByChart.remove(chartId);

    if (_cachedChartId == chartId) {
      await _db.collection('users').doc(user.uid).set({
        'chartId': null,
      }, SetOptions(merge: true));
      _cachedChartId = null;
      _authController.add(user);
    }
  }

  @override
  Future<void> leaveChart(String chartId) async {
    final user = currentUser;
    if (user == null) return;

    final chartRef = _db.collection('charts').doc(chartId);
    bool shouldDeleteAll = false;

    await _db.runTransaction((transaction) async {
      final chartSnap = await transaction.get(chartRef);
      if (!chartSnap.exists) return;

      final userIds = List<String>.from(chartSnap.data()?['userIds'] ?? []);
      final emails = List<String>.from(chartSnap.data()?['emails'] ?? []);

      if (userIds.length <= 1) {
        throw Exception(
          "Cannot leave a chart when you are the sole collaborator. Please delete the chart instead.",
        );
      }

      userIds.remove(user.uid);
      final normalizedUserEmail = (user.email ?? '').trim().toLowerCase();
      emails.removeWhere(
        (emailEntry) => emailEntry.trim().toLowerCase() == normalizedUserEmail,
      );

      if (userIds.isEmpty) {
        shouldDeleteAll = true;
        transaction.delete(chartRef);
      } else {
        transaction.update(chartRef, {'userIds': userIds, 'emails': emails});
      }
    });

    if (shouldDeleteAll) {
      final toDelete = await _collectChartSubcollectionRefs(chartRef);
      await _deleteDocumentsInBatches(toDelete);
    }

    _cachedPreferencesByChart.remove(chartId);

    if (_cachedChartId == chartId) {
      await _db.collection('users').doc(user.uid).set({
        'chartId': null,
      }, SetOptions(merge: true));
      _cachedChartId = null;
      _authController.add(user);
    }
  }

  @override
  Future<void> updateChartReminderSettings(String chartId, bool enabled) async {
    final cached = _cachedPreferencesByChart[chartId];
    if (cached != null) {
      _cachedPreferencesByChart[chartId] = cached.copyWith(
        dailyLoggingReminder: enabled,
      );
    }
    await _db.collection('charts').doc(chartId).set({
      'reminderEnabled': enabled,
      'notificationPreferences': {'dailyLoggingReminder': enabled},
    }, SetOptions(merge: true));
  }

  @override
  Stream<bool> streamChartReminderEnabled(String chartId) {
    return _db
        .collection('charts')
        .doc(chartId)
        .snapshots()
        .map((doc) => (doc.data()?['reminderEnabled'] as bool?) ?? true)
        .transform(
          StreamTransformer<bool, bool>.fromHandlers(
            handleError: (e, stackTrace, sink) {
              Services.logger.error(
                'Error streaming chart reminder enabled for $chartId',
                category: 'chart',
                error: e,
                stackTrace: stackTrace,
              );
              if (FirebaseDatabaseHelpers.isAccessLostError(e)) {
                _handleChartAccessLost(chartId);
              }
              sink.add(true);
            },
          ),
        );
  }

  @override
  Future<void> updateNotificationPreferences(
    String chartId,
    NotificationPreferences preferences,
  ) async {
    _cachedPreferencesByChart[chartId] = preferences;
    await _db.collection('charts').doc(chartId).set({
      'reminderEnabled': preferences.dailyLoggingReminder,
      'notificationPreferences': preferences.toMap(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<NotificationPreferences> streamNotificationPreferences(
    String chartId,
  ) {
    return _db
        .collection('charts')
        .doc(chartId)
        .snapshots()
        .map((doc) {
          final prefs = DatabaseHelpers.parseChartNotificationPreferences(
            doc.data(),
          );
          _cachedPreferencesByChart[chartId] = prefs;
          return prefs;
        })
        .transform(
          StreamTransformer<
            NotificationPreferences,
            NotificationPreferences
          >.fromHandlers(
            handleError: (e, stackTrace, sink) {
              Services.logger.error(
                'Error streaming notification preferences for $chartId',
                category: 'chart',
                error: e,
                stackTrace: stackTrace,
              );
              if (FirebaseDatabaseHelpers.isAccessLostError(e)) {
                _handleChartAccessLost(chartId);
              }
              sink.add(const NotificationPreferences());
            },
          ),
        );
  }

  @override
  NotificationPreferences? getLatestNotificationPreferences(String chartId) {
    return _cachedPreferencesByChart[chartId];
  }

  @override
  NotificationPreferences? get latestNotificationPreferences =>
      _cachedChartId != null
      ? getLatestNotificationPreferences(_cachedChartId!)
      : null;
}
