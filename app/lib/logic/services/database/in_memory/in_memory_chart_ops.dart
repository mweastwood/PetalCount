part of '../in_memory_database_service.dart';

mixin _InMemoryChartOps on _InMemoryDatabaseServiceBase {
  @override
  Future<void> createChart() async {
    if (_currentUser == null) return;

    final chartId = 'chart_${DateTime.now().millisecondsSinceEpoch}';
    _charts[chartId] = {
      'id': chartId,
      'userIds': [_currentUser!.uid],
      'emails': [_currentUser!.email],
      'reminderEnabled': true,
      if (_userTimezone != null && _userTimezone!.isNotEmpty)
        'timezone': _userTimezone,
    };

    _users[_currentUser!.uid]!['chartId'] = chartId;
    _chartId = chartId;
    _cycles[chartId] = {};
    _supplements[chartId] = {
      for (final item in SupplementPresets.defaultList) item.id: item,
    };
    _authController.add(_currentUser); // Trigger refresh
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @override
  Future<void> invitePartner(String partnerEmail) async {
    final user = _currentUser;
    final chartId = _chartId;
    if (user == null || chartId == null) return;

    final cleanEmail = partnerEmail.trim().toLowerCase();
    final existingIndex = _invitations.indexWhere(
      (invitation) =>
          invitation['invitationId'] == cleanEmail &&
          invitation['chartId'] == chartId,
    );
    final invitationRecord = <String, dynamic>{
      'invitationId': cleanEmail,
      'senderUid': user.uid,
      'senderEmail': user.email,
      'chartId': chartId,
      'status': 'pending',
    };
    if (existingIndex != -1) {
      _invitations[existingIndex] = invitationRecord;
    } else {
      _invitations.add(invitationRecord);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final user = _currentUser;
    if (user == null || user.email == null) return [];

    final cleanEmail = user.email!.trim().toLowerCase();
    return _invitations
        .where(
          (inv) =>
              inv['invitationId'] == cleanEmail && inv['status'] == 'pending',
        )
        .toList();
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    final user = _currentUser;
    if (user == null) return;

    final invIndex = _invitations.indexWhere(
      (inv) =>
          (inv['invitationId'] == invitationId ||
              inv['chartId'] == invitationId) &&
          inv['status'] == 'pending',
    );
    if (invIndex == -1) return;

    final inv = _invitations[invIndex];
    inv['status'] = 'accepted';

    final chartId = inv['chartId'] as String;

    _charts[chartId]?['userIds']?.add(user.uid);
    _charts[chartId]?['emails']?.add(user.email);

    _users[user.uid]!['chartId'] = chartId;
    _chartId = chartId;

    _authController.add(_currentUser);
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    final invIndex = _invitations.indexWhere(
      (inv) =>
          (inv['invitationId'] == invitationId ||
              inv['chartId'] == invitationId) &&
          inv['status'] == 'pending',
    );
    if (invIndex != -1) {
      _invitations[invIndex]['status'] = 'declined';
    }
  }

  @override
  Future<void> unlinkChart() async {
    if (_currentUser == null) return;
    _currentUser = MockUser(uid: _currentUser!.uid, email: _currentUser!.email);
    _users[_currentUser!.uid]?['chartId'] = null;
    _chartId = null;
    _authController.add(_currentUser);
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @visibleForTesting
  void setMockChartCollaborators(
    String chartId,
    List<String> userIds, {
    List<String>? emails,
  }) {
    if (_charts.containsKey(chartId)) {
      _charts[chartId]!['userIds'] = List<String>.from(userIds);
      if (emails != null) {
        _charts[chartId]!['emails'] = List<String>.from(emails);
      }
      _emitCharts();
    }
  }

  @visibleForTesting
  void isolateSoleCollaboratorChart([String chartId = 'mock_shared_chart']) {
    final uid = _currentUser?.uid ?? 'husband_uid';
    final email = _currentUser?.email ?? 'husband@example.com';
    setMockChartCollaborators(chartId, [uid], emails: [email]);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamAvailableCharts() {
    final user = _currentUser;
    if (user == null) return Stream.value([]);

    Future.microtask(() => _emitCharts());

    return _chartsController.stream;
  }

  @override
  Future<void> setActiveChart(String chartId) async {
    if (_currentUser == null) return;
    _users[_currentUser!.uid]?['chartId'] = chartId;
    _chartId = chartId;
    _authController.add(_currentUser);
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @override
  Future<void> deleteChart(String chartId) async {
    if (_currentUser == null) return;

    _charts.remove(chartId);
    _cycles.remove(chartId);
    _supplements.remove(chartId);
    _supplementLogs.remove(chartId);

    for (final userVal in _users.values) {
      if (userVal['chartId'] == chartId) {
        userVal['chartId'] = null;
      }
    }

    if (_chartId == chartId) {
      _chartId = null;
    }

    _authController.add(_currentUser);
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @override
  Future<void> leaveChart(String chartId) async {
    if (_currentUser == null) return;

    final chart = _charts[chartId];
    if (chart != null) {
      final userIds = List<String>.from(chart['userIds'] ?? []);
      final emails = List<String>.from(chart['emails'] ?? []);

      if (userIds.length <= 1) {
        throw Exception(
          "Cannot leave a chart when you are the sole collaborator. Please delete the chart instead.",
        );
      }

      userIds.remove(_currentUser!.uid);
      final normalizedUserEmail = (_currentUser!.email ?? '')
          .trim()
          .toLowerCase();
      emails.removeWhere(
        (emailEntry) => emailEntry.trim().toLowerCase() == normalizedUserEmail,
      );

      if (userIds.isEmpty) {
        _charts.remove(chartId);
        _cycles.remove(chartId);
        _supplements.remove(chartId);
        _supplementLogs.remove(chartId);
      } else {
        chart['userIds'] = userIds;
        chart['emails'] = emails;
      }
    }

    if (_chartId == chartId) {
      _users[_currentUser!.uid]?['chartId'] = null;
      _chartId = null;
    }

    _authController.add(_currentUser);
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @override
  Future<void> updateChartReminderSettings(String chartId, bool enabled) async {
    if (_charts.containsKey(chartId)) {
      _charts[chartId]!['reminderEnabled'] = enabled;
      final rawPrefs = _charts[chartId]!['notificationPreferences'];
      final prefs = NotificationPreferences.fromMap(
        rawPrefs != null ? Map<String, dynamic>.from(rawPrefs) : null,
      ).copyWith(dailyLoggingReminder: enabled);
      _charts[chartId]!['notificationPreferences'] = prefs.toMap();
      _emitCharts();
    }
  }

  @override
  Stream<bool> streamChartReminderEnabled(String chartId) {
    return streamAvailableCharts().map((charts) {
      final chart = charts.firstWhere(
        (c) => c['id'] == chartId,
        orElse: () => <String, dynamic>{},
      );
      return (chart['reminderEnabled'] as bool?) ?? true;
    });
  }

  @override
  Future<void> updateNotificationPreferences(
    String chartId,
    NotificationPreferences preferences,
  ) async {
    if (_charts.containsKey(chartId)) {
      _charts[chartId]!['notificationPreferences'] = preferences.toMap();
      _charts[chartId]!['reminderEnabled'] = preferences.dailyLoggingReminder;
      _emitCharts();
    }
  }

  @override
  Stream<NotificationPreferences> streamNotificationPreferences(
    String chartId,
  ) {
    return streamAvailableCharts().map((charts) {
      final chart = charts.firstWhere(
        (c) => c['id'] == chartId,
        orElse: () => <String, dynamic>{},
      );
      return FirebaseDatabaseHelpers.parseChartNotificationPreferences(
        chart.isEmpty ? null : chart,
      );
    });
  }

  @override
  NotificationPreferences? getLatestNotificationPreferences(String chartId) {
    final chart = _charts[chartId];
    if (chart == null) return null;
    return FirebaseDatabaseHelpers.parseChartNotificationPreferences(chart);
  }

  @override
  NotificationPreferences? get latestNotificationPreferences =>
      _chartId != null ? getLatestNotificationPreferences(_chartId!) : null;
}
