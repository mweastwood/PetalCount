import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../models/cycle.dart';
import '../../models/daily_entry.dart';
import '../../models/observation.dart';
import '../creighton_logic.dart';
import 'database_service_interface.dart';

// Local mock user object matching Firebase structure
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool isAnonymous;
  MockUser({required this.uid, this.email, this.isAnonymous = false});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InMemoryDatabaseService implements DatabaseService {
  final _authController = StreamController<User?>.broadcast();
  final _chartsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  User? _currentUser;
  String? _chartId;

  // Fake Cloud database in-memory
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _charts = {};
  final Map<String, Map<String, Map<String, dynamic>>> _cycles =
      {}; // chartId -> { cycleId -> cycleData }
  final List<Map<String, dynamic>> _invitations = [];

  InMemoryDatabaseService() {
    // Start with a mock user logged in by default for instant local preview/usability
    _currentUser = MockUser(uid: 'husband_uid', email: 'husband@example.com');
    _users['husband_uid'] = {
      'uid': 'husband_uid',
      'email': 'husband@example.com',
      'chartId': 'mock_shared_chart',
    };
    _chartId = 'mock_shared_chart';

    _charts['mock_shared_chart'] = {
      'id': 'mock_shared_chart',
      'userIds': ['husband_uid', 'wife_uid'],
      'emails': ['husband@example.com', 'wife@example.com'],
    };

    // Prepopulate with a mock cycle so the app opens with data immediately
    final mockCycleStart = DateTime(2026, 6, 1);
    final mockCycle = Cycle(
      id: mockCycleStart.toIso8601String().substring(0, 10),
      startDate: mockCycleStart,
      bipCodes: const ['6C'],
      dailyEntries: {},
    );

    _cycles['mock_shared_chart'] = {mockCycle.id: mockCycle.toMap()};

    // Add some mock daily observations to represent a standard cycle
    _prepopulateMockData(mockCycle.id, mockCycleStart);

    _authController.stream.listen((user) {
      _emitCycles();
    });
    _authController.add(_currentUser);
  }

  void _prepopulateMockData(String cycleId, DateTime start) {
    // Days 1-5: Menstruation
    for (int d = 0; d < 5; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.heavy,
        'R',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        'Period start',
      );
    }
    // Days 6-10: Dry days
    for (int d = 5; d < 10; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        '',
      );
    }
    // Days 11-13: BIP / Yellow stamp mucus (constant cloudy sticky mucus)
    for (int d = 10; d < 13; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.damp,
        Stretch.sticky,
        [MucusColor.cloudy],
        [],
        0,
        [],
        'Continuous BIP mucus',
      );
    }
    // Days 14-17: Build up (White baby stamps, stretching, lubricative)
    _addMockObs(
      cycleId,
      start.add(const Duration(days: 13)),
      Bleeding.none,
      '',
      Sensation.damp,
      Stretch.tacky,
      [MucusColor.cloudy],
      [],
      2,
      ['Ovulation pain'],
      'Crampy feeling',
    );
    _addMockObs(
      cycleId,
      start.add(const Duration(days: 14)),
      Bleeding.none,
      '',
      Sensation.shiny,
      Stretch.stretchy,
      [MucusColor.clear],
      [],
      0,
      [],
      'Stretching 1 inch',
    );
    _addMockObs(
      cycleId,
      start.add(const Duration(days: 15)),
      Bleeding.none,
      '',
      Sensation.wet,
      Stretch.stretchy,
      [MucusColor.clear],
      [Consistency.lubricative],
      0,
      [],
      'Very lubricative',
    ); // Peak Day
    // Days 18-20: Post-peak dry (Green baby stamps)
    for (int d = 16; d < 19; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        '',
      );
    }
    // Days 21-28: Dry post-ovulatory (Green stamps)
    for (int d = 19; d < 28; d++) {
      _addMockObs(
        cycleId,
        start.add(Duration(days: d)),
        Bleeding.none,
        '',
        Sensation.dry,
        Stretch.none,
        [],
        [],
        0,
        [],
        '',
      );
    }
  }

  void _addMockObs(
    String cycleId,
    DateTime date,
    Bleeding bleeding,
    String bleedingColor,
    Sensation sensation,
    Stretch stretch,
    List<MucusColor> colors,
    List<Consistency> consistencies,
    double painLevel,
    List<String> painTypes,
    String comment,
  ) {
    final cycleData = _cycles['mock_shared_chart']![cycleId]!;
    final cycle = Cycle.fromMap(cycleData);
    final dateKey = date.toIso8601String().substring(0, 10);

    final obs = Observation(
      id: dateKey + DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: date,
      sensation: sensation,
      stretch: stretch,
      colors: colors,
      consistencies: consistencies,
      bleeding: bleeding,
      bleedingColor: bleedingColor,
      painLevel: painLevel,
      painTypes: painTypes,
      comment: comment,
      userId: 'wife_uid',
    );

    final currentEntries = Map<String, DailyEntry>.from(cycle.dailyEntries);
    final existingEntry = currentEntries[dateKey];
    List<Observation> observations = existingEntry != null
        ? (List<Observation>.from(existingEntry.observations)..add(obs))
        : [obs];

    final resolved = CreightonLogic.resolveDailyEntry(
      date: date,
      observations: observations,
    );
    currentEntries[dateKey] = resolved;

    final updated = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: cycle.bipCodes,
    );

    _cycles['mock_shared_chart']![cycleId] = cycle
        .copyWith(dailyEntries: updated)
        .toMap();
  }

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
        'chartId': 'mock_shared_chart',
      };
    }

    _currentUser = MockUser(uid: uid, email: email);
    _chartId = _users[uid]!['chartId'];
    _authController.add(_currentUser);
    _emitCharts();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _chartId = null;
    _authController.add(null);
    _emitCharts();
  }

  @override
  Future<void> createChart() async {
    if (_currentUser == null) return;

    final chartId = 'chart_${DateTime.now().millisecondsSinceEpoch}';
    _charts[chartId] = {
      'id': chartId,
      'userIds': [_currentUser!.uid],
      'emails': [_currentUser!.email],
    };

    _users[_currentUser!.uid]!['chartId'] = chartId;
    _chartId = chartId;
    _cycles[chartId] = {};
    _authController.add(_currentUser); // Trigger refresh
    _emitCharts();
  }

  @override
  Future<void> invitePartner(String partnerEmail) async {
    final user = _currentUser;
    final chartId = _chartId;
    if (user == null || chartId == null) return;

    final cleanEmail = partnerEmail.trim().toLowerCase();
    _invitations.add({
      'invitationId': cleanEmail,
      'senderUid': user.uid,
      'senderEmail': user.email,
      'chartId': chartId,
      'status': 'pending',
    });
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
  }

  void _emitCharts() {
    final user = _currentUser;
    if (user == null) {
      _chartsController.add([]);
      return;
    }
    final list = _charts.values
        .where((chart) => (chart['userIds'] as List).contains(user.uid))
        .toList();
    _chartsController.add(list);
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
  }

  @override
  Future<void> deleteChart(String chartId) async {
    if (_currentUser == null) return;

    _charts.remove(chartId);
    _cycles.remove(chartId);

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
      emails.remove(_currentUser!.email ?? '');

      if (userIds.isEmpty) {
        _charts.remove(chartId);
        _cycles.remove(chartId);
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
  }

  // Stream emulation
  final _cyclesController = StreamController<List<Cycle>>.broadcast();

  void _emitCycles() {
    final chartId = _chartId;
    if (chartId == null) {
      _cyclesController.add([]);
      return;
    }

    final chartCyclesData = _cycles[chartId] ?? {};
    final list = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    _cyclesController.add(list);
  }

  @override
  Stream<List<Cycle>> streamCycles() {
    return _buildCyclesStream();
  }

  Stream<List<Cycle>> _buildCyclesStream() async* {
    final chartId = _chartId;
    if (chartId != null) {
      final chartCyclesData = _cycles[chartId] ?? {};
      final list = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      yield list;
    } else {
      yield [];
    }
    yield* _cyclesController.stream;
  }

  void _reallocateAndRecalculate(String chartId) {
    final chartCyclesData = _cycles[chartId];
    if (chartCyclesData == null || chartCyclesData.isEmpty) return;

    final cycles = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
    final updatedCycles = CreightonLogic.reallocateAndRecalculateCycles(cycles);

    for (final cycle in updatedCycles) {
      _cycles[chartId]![cycle.id] = cycle.toMap();
    }

    _emitCycles();
  }

  @override
  Future<void> startNewCycle(DateTime startDate, List<String> bipCodes) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final dateStr = startDate.toIso8601String().substring(0, 10);
    final cycle = Cycle(
      id: dateStr,
      startDate: startDate,
      bipCodes: bipCodes,
      dailyEntries: {},
    );

    _cycles[chartId] ??= {};
    _cycles[chartId]![dateStr] = cycle.toMap();
    _reallocateAndRecalculate(chartId);
  }

  @override
  Future<void> updateCycleStartDate(
    String cycleId,
    DateTime newStartDate,
  ) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final cycleData = _cycles[chartId]?[cycleId];
    if (cycleData == null) return;

    final oldCycle = Cycle.fromMap(cycleData);
    _cycles[chartId]!.remove(cycleId);

    final newDateStr = newStartDate.toIso8601String().substring(0, 10);
    final updatedCycle = Cycle(
      id: newDateStr,
      startDate: newStartDate,
      endDate: oldCycle.endDate,
      bipCodes: oldCycle.bipCodes,
      dailyEntries: oldCycle.dailyEntries,
    );

    _cycles[chartId]![newDateStr] = updatedCycle.toMap();
    _reallocateAndRecalculate(chartId);
  }

  @override
  Future<void> mergeCycleWithPrevious(String cycleId) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final chartCyclesData = _cycles[chartId];
    if (chartCyclesData == null) return;

    final cycles = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
    cycles.sort((a, b) => a.startDate.compareTo(b.startDate));
    final targetIndex = cycles.indexWhere((c) => c.id == cycleId);
    if (targetIndex <= 0) return;

    final targetCycle = cycles[targetIndex];
    final prevCycle = cycles[targetIndex - 1];

    final mergedEntries = Map<String, DailyEntry>.from(prevCycle.dailyEntries)
      ..addAll(targetCycle.dailyEntries);

    final updatedPrevCycle = prevCycle.copyWith(dailyEntries: mergedEntries);
    _cycles[chartId]![prevCycle.id] = updatedPrevCycle.toMap();

    _cycles[chartId]!.remove(cycleId);
    _reallocateAndRecalculate(chartId);
  }

  @override
  Future<void> deleteCycle(String cycleId) async {
    final chartId = _chartId;
    if (chartId == null) return;

    _cycles[chartId]?.remove(cycleId);
    _emitCycles();
  }

  @override
  Future<void> updateBipCodes(String cycleId, List<String> bipCodes) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final cycleData = _cycles[chartId]?[cycleId];
    if (cycleData == null) return;

    final cycle = Cycle.fromMap(cycleData);
    final updated = CreightonLogic.recalculateCycle(
      entries: cycle.dailyEntries.values.toList(),
      bipCodes: bipCodes,
    );

    _cycles[chartId]![cycleId] = cycle
        .copyWith(bipCodes: bipCodes, dailyEntries: updated)
        .toMap();

    _emitCycles();
  }

  @override
  Future<void> saveObservation({
    String? cycleId,
    required DateTime date,
    required Sensation sensation,
    required Stretch stretch,
    required List<MucusColor> colors,
    required List<Consistency> consistencies,
    required Bleeding bleeding,
    required String bleedingColor,
    required double painLevel,
    required List<String> painTypes,
    required String comment,
    bool? isVdrsExplicit,
  }) async {
    final chartId = _chartId;
    final user = _currentUser;
    if (chartId == null || user == null) return;

    _cycles[chartId] ??= {};
    final chartCyclesData = _cycles[chartId]!;
    final cycles = chartCyclesData.values.map((d) => Cycle.fromMap(d)).toList();
    cycles.sort((a, b) => a.startDate.compareTo(b.startDate));

    final isHeavyOrModerate =
        bleeding == Bleeding.heavy || bleeding == Bleeding.moderate;

    if (cycles.isEmpty) {
      final dateStr = date.toIso8601String().substring(0, 10);
      final newCycle = Cycle(
        id: dateStr,
        startDate: date,
        bipCodes: const ['6C'],
        dailyEntries: {},
      );
      _cycles[chartId]![dateStr] = newCycle.toMap();
      cycles.add(newCycle);
    } else if (isHeavyOrModerate) {
      final eligible = cycles
          .where((c) => c.startDate.compareTo(date) <= 0)
          .toList();
      if (eligible.isNotEmpty) {
        final latest = eligible.last;
        final autoStart = CreightonLogic.evaluateAutoCycleStart(latest, date);
        if (autoStart != null) {
          final dateStr = autoStart.toIso8601String().substring(0, 10);
          if (!_cycles[chartId]!.containsKey(dateStr)) {
            final newCycle = Cycle(
              id: dateStr,
              startDate: autoStart,
              bipCodes: latest.bipCodes,
              dailyEntries: {},
            );
            _cycles[chartId]![dateStr] = newCycle.toMap();
            _reallocateAndRecalculate(chartId);
          }
        }
      }
    }

    // Refresh sorted cycles list after potential cycle creation
    final updatedCycles = _cycles[chartId]!.values
        .map((d) => Cycle.fromMap(d))
        .toList();
    updatedCycles.sort((a, b) => a.startDate.compareTo(b.startDate));

    final eligible = updatedCycles
        .where((c) => c.startDate.compareTo(date) <= 0)
        .toList();
    final targetCycle = eligible.isNotEmpty
        ? eligible.last
        : updatedCycles.first;
    final targetCycleId = targetCycle.id;

    final dateKey = date.toIso8601String().substring(0, 10);

    final newObs = Observation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      sensation: sensation,
      stretch: stretch,
      colors: colors,
      consistencies: consistencies,
      bleeding: bleeding,
      bleedingColor: bleedingColor,
      painLevel: painLevel,
      painTypes: painTypes,
      comment: comment,
      userId: user.uid,
      isVdrsExplicit: isVdrsExplicit,
    );

    final currentEntries = Map<String, DailyEntry>.from(
      targetCycle.dailyEntries,
    );
    final existingEntry = currentEntries[dateKey];
    List<Observation> observations = existingEntry != null
        ? (List<Observation>.from(existingEntry.observations)..add(newObs))
        : [newObs];

    final resolved = CreightonLogic.resolveDailyEntry(
      date: date,
      observations: observations,
    );
    currentEntries[dateKey] = resolved;

    final updated = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: targetCycle.bipCodes,
    );

    _cycles[chartId]![targetCycleId] = targetCycle
        .copyWith(dailyEntries: updated)
        .toMap();
    _emitCycles();
  }

  @override
  Future<void> deleteObservation({
    required String cycleId,
    required DateTime date,
    required String observationId,
  }) async {
    final chartId = _chartId;
    if (chartId == null) return;

    final cycleData = _cycles[chartId]?[cycleId];
    if (cycleData == null) return;

    final cycle = Cycle.fromMap(cycleData);
    final dateKey = date.toIso8601String().substring(0, 10);

    final currentEntries = Map<String, DailyEntry>.from(cycle.dailyEntries);
    final existingEntry = currentEntries[dateKey];
    if (existingEntry == null) return;

    final observations = existingEntry.observations
        .where((o) => o.id != observationId)
        .toList();

    if (observations.isEmpty) {
      currentEntries.remove(dateKey);
    } else {
      final resolved = CreightonLogic.resolveDailyEntry(
        date: date,
        observations: observations,
      );
      currentEntries[dateKey] = resolved;
    }

    final updated = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: cycle.bipCodes,
    );

    _cycles[chartId]![cycleId] = cycle.copyWith(dailyEntries: updated).toMap();
    _emitCycles();
  }
}
