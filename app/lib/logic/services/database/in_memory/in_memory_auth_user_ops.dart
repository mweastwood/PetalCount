part of '../in_memory_database_service.dart';

mixin _InMemoryAuthUserOps on _InMemoryDatabaseServiceBase {
  @override
  User? get currentUser => _currentUser;

  @override
  String? get currentChartId => _chartId;

  @override
  Stream<User?> get authStateChanges => _buildAuthStream();

  Stream<User?> _buildAuthStream() async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    const email = 'google_user@example.com';
    const uid = 'mock_uid_google_user';

    if (!_users.containsKey(uid)) {
      _users[uid] = {
        'uid': uid,
        'email': email,
        'role': 'wife',
        'chartId': 'mock_shared_chart',
      };
    }

    final sharedChart = _charts['mock_shared_chart'];
    if (sharedChart != null) {
      final userIds = List<String>.from(sharedChart['userIds'] ?? []);
      if (!userIds.contains(uid)) {
        userIds.add(uid);
        sharedChart['userIds'] = userIds;
      }
      final emails = List<String>.from(sharedChart['emails'] ?? []);
      if (!emails.contains(email)) {
        emails.add(email);
        sharedChart['emails'] = emails;
      }
    }

    _currentUser = MockUser(uid: uid, email: email);
    _chartId = _users[uid]!['chartId'] as String?;
    _authController.add(_currentUser);
    _roleController.add(_users[uid]!['role'] as String? ?? 'wife');
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _chartId = null;
    _authController.add(null);
    _roleController.add(null);
    _emitCharts();
    _emitCycles();
    _emitSupplements();
    _emitSupplementLogs();
  }

  @override
  Future<void> updateUserRole(String role) async {
    final user = _currentUser;
    if (user == null) return;
    _users[user.uid] ??= {'uid': user.uid, 'email': user.email};
    _users[user.uid]!['role'] = role;
    _roleController.add(role);
  }

  @override
  Stream<String?> streamUserRole() => _buildUserRoleStream();

  Stream<String?> _buildUserRoleStream() async* {
    final user = _currentUser;
    if (user != null) {
      yield _users[user.uid]?['role'] as String? ??
          (user.uid == 'husband_uid' ? 'husband' : 'wife');
    } else {
      yield null;
    }
    yield* _roleController.stream;
  }

  List<String> get fcmTokens => List.unmodifiable(_fcmTokens);
  String? get userTimezone => _userTimezone;

  @override
  Future<void> saveFcmToken(String token) async {
    if (token.isNotEmpty && !_fcmTokens.contains(token)) {
      _fcmTokens.add(token);
    }
  }

  @override
  Future<void> removeFcmToken(String token) async {
    _fcmTokens.remove(token);
  }

  @override
  Future<void> updateUserTimezone(String timezone) async {
    _userTimezone = timezone;
    final chartId = currentChartId;
    if (chartId != null && _charts.containsKey(chartId)) {
      _charts[chartId]!['timezone'] = timezone;
      _emitCharts();
    }
  }
}
