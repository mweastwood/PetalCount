import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cycle.dart';
import '../models/observation.dart';
import '../models/daily_entry.dart';
import 'creighton_logic.dart';

abstract class DatabaseService {
  User? get currentUser;
  String? get currentChartId;
  Stream<User?> get authStateChanges;

  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();

  Future<void> createChart();
  Future<void> invitePartner(String partnerEmail);
  Future<List<Map<String, dynamic>>> getPendingInvitations();
  Future<void> acceptInvitation(String invitationId);
  Future<void> declineInvitation(String invitationId);

  Stream<List<Cycle>> streamCycles();
  Future<void> startNewCycle(DateTime startDate, List<String> bipCodes);
  Future<void> deleteCycle(String cycleId);
  Future<void> updateBipCodes(String cycleId, List<String> bipCodes);

  Future<void> saveObservation({
    required String cycleId,
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
  });

  Future<void> deleteObservation({
    required String cycleId,
    required DateTime date,
    required String observationId,
  });
}

class FirebaseDatabaseService implements DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _cachedChartId;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  String? get currentChartId => _cachedChartId;

  @override
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user != null) {
          _cachedChartId = await _fetchChartId(user.uid);
        } else {
          _cachedChartId = null;
        }
        return user;
      });

  Future<String?> _fetchChartId(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['chartId'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching chartId: $e');
    }
    return null;
  }

  @override
  Future<void> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      _cachedChartId = await _fetchChartId(credential.user!.uid);
    }
  }

  @override
  Future<void> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      // Create user record
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'chartId': null,
      });
      _cachedChartId = null;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _cachedChartId = null;
  }

  @override
  Future<void> createChart() async {
    final user = currentUser;
    if (user == null) return;

    final chartRef = _db.collection('charts').doc();
    final chartId = chartRef.id;

    await chartRef.set({
      'id': chartId,
      'userIds': [user.uid],
      'emails': [user.email],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(user.uid).update({'chartId': chartId});

    _cachedChartId = chartId;
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

  @override
  Future<void> acceptInvitation(String invitationId) async {
    final user = currentUser;
    if (user == null) return;

    final docRef = _db.collection('invitations').doc(invitationId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Invitation not found");

    final data = doc.data()!;
    final chartId = data['chartId'] as String;

    // Join the chart
    final chartRef = _db.collection('charts').doc(chartId);
    await chartRef.update({
      'userIds': FieldValue.arrayUnion([user.uid]),
      'emails': FieldValue.arrayUnion([user.email]),
    });

    // Update user profile
    await _db.collection('users').doc(user.uid).update({'chartId': chartId});

    // Update invitation status
    await docRef.update({'status': 'accepted'});

    _cachedChartId = chartId;
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    await _db.collection('invitations').doc(invitationId).update({
      'status': 'declined',
    });
  }

  @override
  Stream<List<Cycle>> streamCycles() {
    final chartId = currentChartId;
    if (chartId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .snapshots()
        .map((snap) {
          final cycles = snap.docs
              .map((doc) => Cycle.fromMap(doc.data()))
              .toList();
          cycles.sort(
            (a, b) => b.startDate.compareTo(a.startDate),
          ); // descending order
          return cycles;
        });
  }

  @override
  Future<void> startNewCycle(DateTime startDate, List<String> bipCodes) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    // Format ID using starting date
    final dateStr = startDate.toIso8601String().substring(0, 10);
    final cycleRef = _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(dateStr);

    final newCycle = Cycle(
      id: dateStr,
      startDate: startDate,
      bipCodes: bipCodes,
      dailyEntries: {},
    );

    await cycleRef.set(newCycle.toMap());
  }

  @override
  Future<void> deleteCycle(String cycleId) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(cycleId)
        .delete();
  }

  @override
  Future<void> updateBipCodes(String cycleId, List<String> bipCodes) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final cycleRef = _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(cycleId);

    final doc = await cycleRef.get();
    if (!doc.exists) return;

    final cycle = Cycle.fromMap(doc.data()!);
    final updatedEntries = CreightonLogic.recalculateCycle(
      entries: cycle.dailyEntries.values.toList(),
      bipCodes: bipCodes,
    );

    await cycleRef.update({
      'bipCodes': bipCodes,
      'dailyEntries': updatedEntries.map((k, v) => MapEntry(k, v.toMap())),
    });
  }

  @override
  Future<void> saveObservation({
    required String cycleId,
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
  }) async {
    final chartId = currentChartId;
    final user = currentUser;
    if (chartId == null || user == null) return;

    final cycleRef = _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(cycleId);

    final doc = await cycleRef.get();
    if (!doc.exists) return;

    final cycle = Cycle.fromMap(doc.data()!);
    final dateKey = date.toIso8601String().substring(0, 10);

    // Create new observation
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
    );

    // Fetch existing entries
    final currentEntries = Map<String, DailyEntry>.from(cycle.dailyEntries);
    final existingEntry = currentEntries[dateKey];

    List<Observation> observations = [];
    if (existingEntry != null) {
      observations = List<Observation>.from(existingEntry.observations)
        ..add(newObs);
    } else {
      observations = [newObs];
    }

    // Resolve daily entry
    final resolvedDaily = CreightonLogic.resolveDailyEntry(
      date: date,
      observations: observations,
    );

    currentEntries[dateKey] = resolvedDaily;

    // Recalculate entire cycle stamps
    final updatedEntries = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: cycle.bipCodes,
    );

    await cycleRef.update({
      'dailyEntries': updatedEntries.map((k, v) => MapEntry(k, v.toMap())),
    });
  }

  @override
  Future<void> deleteObservation({
    required String cycleId,
    required DateTime date,
    required String observationId,
  }) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final cycleRef = _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(cycleId);

    final doc = await cycleRef.get();
    if (!doc.exists) return;

    final cycle = Cycle.fromMap(doc.data()!);
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
      final resolvedDaily = CreightonLogic.resolveDailyEntry(
        date: date,
        observations: observations,
      );
      currentEntries[dateKey] = resolvedDaily;
    }

    // Recalculate stamps
    final updatedEntries = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: cycle.bipCodes,
    );

    await cycleRef.update({
      'dailyEntries': updatedEntries.map((k, v) => MapEntry(k, v.toMap())),
    });
  }
}

// Local mock user object matching Firebase structure
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  MockUser({required this.uid, this.email});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InMemoryDatabaseService implements DatabaseService {
  final _authController = StreamController<User?>.broadcast();
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
    final mockCycleStart = DateTime.now().subtract(const Duration(days: 28));
    final mockCycle = Cycle(
      id: mockCycleStart.toIso8601String().substring(0, 10),
      startDate: mockCycleStart,
      bipCodes: const ['6-C'],
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
  Future<void> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    String uid = '';

    // Find or create user
    _users.forEach((key, value) {
      if (value['email'] == cleanEmail) uid = key;
    });

    if (uid.isEmpty) {
      uid = 'mock_uid_${cleanEmail.split('@')[0]}';
      _users[uid] = {
        'uid': uid,
        'email': cleanEmail,
        'chartId': 'mock_shared_chart',
      };
    }

    _currentUser = MockUser(uid: uid, email: cleanEmail);
    _chartId = _users[uid]!['chartId'];
    _authController.add(_currentUser);
  }

  @override
  Future<void> signUp(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final uid = 'mock_uid_${cleanEmail.split('@')[0]}';

    _users[uid] = {'uid': uid, 'email': cleanEmail, 'chartId': null};

    _currentUser = MockUser(uid: uid, email: cleanEmail);
    _chartId = null;
    _authController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _chartId = null;
    _authController.add(null);
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
          inv['invitationId'] == invitationId && inv['status'] == 'pending',
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
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    final invIndex = _invitations.indexWhere(
      (inv) =>
          inv['invitationId'] == invitationId && inv['status'] == 'pending',
    );
    if (invIndex != -1) {
      _invitations[invIndex]['status'] = 'declined';
    }
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
    _emitCycles();
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
    required String cycleId,
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
  }) async {
    final chartId = _chartId;
    final user = _currentUser;
    if (chartId == null || user == null) return;

    final cycleData = _cycles[chartId]?[cycleId];
    if (cycleData == null) return;

    final cycle = Cycle.fromMap(cycleData);
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
    );

    final currentEntries = Map<String, DailyEntry>.from(cycle.dailyEntries);
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
      bipCodes: cycle.bipCodes,
    );

    _cycles[chartId]![cycleId] = cycle.copyWith(dailyEntries: updated).toMap();
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
