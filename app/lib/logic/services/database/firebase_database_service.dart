import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../app_config.dart';
import '../../models/cycle.dart';
import '../../models/daily_entry.dart';
import '../../models/observation.dart';
import '../creighton_logic.dart';
import 'database_service_interface.dart';

class FirebaseDatabaseService implements DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  String? _cachedChartId;
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();
  late final Stream<User?> _authStateChangesStream;

  FirebaseDatabaseService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _cachedChartId = await _fetchChartId(user.uid);
      } else {
        _cachedChartId = null;
      }
      _authController.add(user);
    });

    late StreamController<User?> controller;
    StreamSubscription<User?>? sub;

    controller = StreamController<User?>(
      onListen: () {
        controller.add(currentUser);
        sub = _authController.stream.listen(controller.add);
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    _authStateChangesStream = controller.stream.asBroadcastStream();
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  String? get currentChartId => _cachedChartId;

  @override
  Stream<User?> get authStateChanges => _authStateChangesStream;

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
  Future<void> signInWithGoogle() async {
    try {
      final User? user;
      if (kIsWeb) {
        final UserCredential userCredential = await _auth.signInWithPopup(
          GoogleAuthProvider(),
        );
        user = userCredential.user;
      } else {
        if (!_googleSignInInitialized) {
          final String serverClientId =
              AppConfig.environment == AppEnvironment.prod
              ? '847947122489-kbpqd3e7m8b3aehd3ah9714rgsd10es3.apps.googleusercontent.com'
              : '688587508865-fhe9rghlo1f909rn8t7vqjvld7km36sl.apps.googleusercontent.com';
          await _googleSignIn.initialize(serverClientId: serverClientId);
          _googleSignInInitialized = true;
        }

        final GoogleSignInAccount googleUser = await _googleSignIn
            .authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        user = userCredential.user;
      }

      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'chartId': null,
          });
        }
        _cachedChartId = await _fetchChartId(user.uid);
      }
    } catch (e) {
      if (!kIsWeb &&
          e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In canceled: $e');
        throw GoogleSignInException(
          code: e.code,
          description:
              'Sign-in was canceled or failed due to configuration. If you selected '
              'an account and this happened, it is likely due to a developer configuration '
              'mismatch (e.g., missing SHA-1 signature fingerprint in the Firebase Console).',
          details: e.details,
        );
      }
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
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
    await _db.collection('users').doc(user.uid).set({
      'chartId': chartId,
      'uid': user.uid,
      'email': user.email ?? '',
    }, SetOptions(merge: true));

    // Update invitation status
    await docRef.update({'status': 'accepted'});

    _cachedChartId = chartId;
    _authController.add(user);
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    await _db.collection('invitations').doc(invitationId).update({
      'status': 'declined',
    });
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
    final user = currentUser;
    if (user == null) return Stream.value([]);
    return _db
        .collection('charts')
        .where('userIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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

  @override
  Future<void> deleteChart(String chartId) async {
    final user = currentUser;
    if (user == null) return;

    final cyclesSnapshot = await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .get();

    for (final doc in cyclesSnapshot.docs) {
      final obsSnapshot = await doc.reference.collection('observations').get();
      for (final obsDoc in obsSnapshot.docs) {
        await obsDoc.reference.delete();
      }
      await doc.reference.delete();
    }

    await _db.collection('charts').doc(chartId).delete();

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
      emails.remove(user.email ?? '');

      if (userIds.isEmpty) {
        shouldDeleteAll = true;
        transaction.delete(chartRef);
      } else {
        transaction.update(chartRef, {'userIds': userIds, 'emails': emails});
      }
    });

    if (shouldDeleteAll) {
      final cyclesSnapshot = await chartRef.collection('cycles').get();
      for (final doc in cyclesSnapshot.docs) {
        final obsSnapshot = await doc.reference
            .collection('observations')
            .get();
        for (final obsDoc in obsSnapshot.docs) {
          await obsDoc.reference.delete();
        }
        await doc.reference.delete();
      }
    }

    if (_cachedChartId == chartId) {
      await _db.collection('users').doc(user.uid).set({
        'chartId': null,
      }, SetOptions(merge: true));
      _cachedChartId = null;
      _authController.add(user);
    }
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
    final chartId = currentChartId;
    final user = currentUser;
    if (chartId == null || user == null) return;

    final cyclesSnap = await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .get();

    final cycles = cyclesSnap.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();
    cycles.sort((a, b) => a.startDate.compareTo(b.startDate));

    final isMenses =
        (bleeding == Bleeding.heavy ||
        bleeding == Bleeding.moderate ||
        bleeding == Bleeding.light ||
        bleeding == Bleeding.red);

    String targetCycleId;
    Cycle targetCycle;

    if (cycles.isEmpty) {
      final dateStr = date.toIso8601String().substring(0, 10);
      targetCycle = Cycle(
        id: dateStr,
        startDate: date,
        bipCodes: const ['6-C'],
        dailyEntries: {},
      );
      targetCycleId = dateStr;
      await _db
          .collection('charts')
          .doc(chartId)
          .collection('cycles')
          .doc(targetCycleId)
          .set(targetCycle.toMap());
    } else {
      Cycle? matchedCycle;
      if (isMenses) {
        final eligible = cycles
            .where((c) => c.startDate.compareTo(date) <= 0)
            .toList();
        if (eligible.isEmpty) {
          final dateStr = date.toIso8601String().substring(0, 10);
          matchedCycle = Cycle(
            id: dateStr,
            startDate: date,
            bipCodes: cycles.first.bipCodes,
            dailyEntries: {},
          );
          await _db
              .collection('charts')
              .doc(chartId)
              .collection('cycles')
              .doc(dateStr)
              .set(matchedCycle.toMap());
        } else {
          final latest = eligible.last;
          final daysDiff = date.difference(latest.startDate).inDays;
          if (daysDiff >= 10) {
            final dateStr = date.toIso8601String().substring(0, 10);
            matchedCycle = Cycle(
              id: dateStr,
              startDate: date,
              bipCodes: latest.bipCodes,
              dailyEntries: {},
            );
            await _db
                .collection('charts')
                .doc(chartId)
                .collection('cycles')
                .doc(dateStr)
                .set(matchedCycle.toMap());
          } else {
            matchedCycle = latest;
          }
        }
      } else {
        if (cycleId != null) {
          final found = cycles.where((c) => c.id == cycleId).firstOrNull;
          if (found != null) {
            matchedCycle = found;
          }
        }
        if (matchedCycle == null) {
          final eligible = cycles
              .where((c) => c.startDate.compareTo(date) <= 0)
              .toList();
          matchedCycle = eligible.isNotEmpty ? eligible.last : cycles.first;
        }
      }
      targetCycle = matchedCycle;
      targetCycleId = matchedCycle.id;
    }

    final cycleRef = _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(targetCycleId);

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

    List<Observation> observations = [];
    if (existingEntry != null) {
      observations = List<Observation>.from(existingEntry.observations)
        ..add(newObs);
    } else {
      observations = [newObs];
    }

    final resolvedDaily = CreightonLogic.resolveDailyEntry(
      date: date,
      observations: observations,
    );

    currentEntries[dateKey] = resolvedDaily;

    final updatedEntries = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: targetCycle.bipCodes,
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
