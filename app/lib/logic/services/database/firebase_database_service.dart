import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app_config.dart';
import '../../models/cycle.dart';
import '../../models/daily_entry.dart';
import '../../models/observation.dart';
import '../../utils/date_utils.dart';
import '../creighton_logic.dart';
import '../services.dart';
import 'database_service_interface.dart';

class FirebaseDatabaseService implements DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  String? _cachedChartId;
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();

  FirebaseDatabaseService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _cachedChartId = await _fetchChartId(user.uid);
      } else {
        _cachedChartId = null;
      }
      _authController.add(user);
    });
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  String? get currentChartId => _cachedChartId;

  @override
  Stream<User?> get authStateChanges => _buildAuthStream();

  Stream<User?> _buildAuthStream() async* {
    final user = currentUser;
    if (user != null) {
      _cachedChartId ??= await _fetchChartId(user.uid);
    } else {
      _cachedChartId = null;
    }
    yield user;
    yield* _authController.stream;
  }

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
          await _googleSignIn.initialize(
            serverClientId: AppConfig.googleServerClientId,
          );
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

    DocumentSnapshot<Map<String, dynamic>>? doc;
    var docRef = _db.collection('invitations').doc(invitationId);

    try {
      final snap = await docRef.get();
      if (snap.exists) {
        doc = snap;
      }
    } catch (_) {}

    if (doc == null || !doc.exists) {
      final cleanEmail = user.email?.trim().toLowerCase() ?? '';
      final snap = await _db
          .collection('invitations')
          .where('invitationId', isEqualTo: cleanEmail)
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isNotEmpty) {
        doc = snap.docs.first;
        docRef = doc.reference;
      }
    }

    if (doc == null || !doc.exists) {
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
    await docRef.update({'status': 'accepted'});

    _cachedChartId = chartId;
    _authController.add(user);
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    final user = currentUser;
    if (user == null) return;

    DocumentSnapshot<Map<String, dynamic>>? doc;
    var docRef = _db.collection('invitations').doc(invitationId);

    try {
      final snap = await docRef.get();
      if (snap.exists) {
        doc = snap;
      }
    } catch (_) {}

    if (doc == null || !doc.exists) {
      final cleanEmail = user.email?.trim().toLowerCase() ?? '';
      final snap = await _db
          .collection('invitations')
          .where('invitationId', isEqualTo: cleanEmail)
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isNotEmpty) {
        docRef = snap.docs.first.reference;
      }
    }

    await docRef.update({'status': 'declined'});
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

  Future<void> _deleteDocumentsInBatches(
    List<DocumentReference> docRefs,
  ) async {
    if (docRefs.isEmpty) return;
    const batchSize = 500;
    for (var i = 0; i < docRefs.length; i += batchSize) {
      final chunk = docRefs.sublist(
        i,
        i + batchSize > docRefs.length ? docRefs.length : i + batchSize,
      );
      final batch = _db.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
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

    toDelete.add(_db.collection('charts').doc(chartId));

    await _deleteDocumentsInBatches(toDelete);

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
      await _deleteDocumentsInBatches(toDelete);
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
    late StreamController<List<Cycle>> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? cyclesSub;

    void listenToCycles(String chartId) {
      cyclesSub?.cancel();
      cyclesSub = _db
          .collection('charts')
          .doc(chartId)
          .collection('cycles')
          .snapshots()
          .listen(
            (snap) {
              final cycles = snap.docs
                  .map((doc) => Cycle.fromMap(doc.data()))
                  .toList();
              cycles.sort(
                (a, b) => b.startDate.compareTo(a.startDate),
              ); // descending order
              controller.add(cycles);
            },
            onError: (e) {
              debugPrint('Error streaming cycles: $e');
              controller.add([]);
            },
          );
    }

    void updateListener() {
      final chartId = currentChartId;
      if (chartId == null) {
        cyclesSub?.cancel();
        cyclesSub = null;
        controller.add([]);
      } else {
        listenToCycles(chartId);
      }
    }

    controller = StreamController<List<Cycle>>.broadcast(
      onListen: () {
        updateListener();
        authSub = authStateChanges.listen((_) {
          updateListener();
        });
      },
      onCancel: () {
        cyclesSub?.cancel();
        authSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> _reallocateAndRecalculate(String chartId) async {
    final cyclesSnapshot = await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .get();

    final cycles = cyclesSnapshot.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();
    if (cycles.isEmpty) return;

    final updatedCycles = CreightonLogic.reallocateAndRecalculateCycles(cycles);

    final batch = _db.batch();
    for (final cycle in updatedCycles) {
      final ref = _db
          .collection('charts')
          .doc(chartId)
          .collection('cycles')
          .doc(cycle.id);
      batch.update(ref, {
        'dailyEntries': cycle.dailyEntries.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
      });
      for (final entry in cycle.dailyEntries.values) {
        final subRef = ref.collection('dailyEntries').doc(entry.date.dateKey);
        batch.set(subRef, entry.toMap());
      }
    }
    await batch.commit();
  }

  @override
  Future<void> startNewCycle(DateTime startDate, List<String> bipCodes) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final dateStr = startDate.dateKey;
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
    await _reallocateAndRecalculate(chartId);
  }

  @override
  Future<void> deleteCycle(String cycleId) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final cycleRef = _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(cycleId);

    final List<DocumentReference> toDelete = [];
    final dailySnapshot = await cycleRef.collection('dailyEntries').get();
    for (final dailyDoc in dailySnapshot.docs) {
      toDelete.add(dailyDoc.reference);
    }
    toDelete.add(cycleRef);

    await _deleteDocumentsInBatches(toDelete);
  }

  @override
  Future<void> updateCycleStartDate(
    String cycleId,
    DateTime newStartDate,
  ) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final cyclesSnapshot = await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .get();

    final cycles = cyclesSnapshot.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();

    final oldCycleIndex = cycles.indexWhere((c) => c.id == cycleId);
    if (oldCycleIndex == -1) return;

    final oldCycle = cycles[oldCycleIndex];
    final newDateStr = newStartDate.dateKey;

    if (cycleId != newDateStr) {
      await _db
          .collection('charts')
          .doc(chartId)
          .collection('cycles')
          .doc(cycleId)
          .delete();
    }

    final updatedCycle = Cycle(
      id: newDateStr,
      startDate: newStartDate,
      endDate: oldCycle.endDate,
      bipCodes: oldCycle.bipCodes,
      dailyEntries: oldCycle.dailyEntries,
    );

    await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(newDateStr)
        .set(updatedCycle.toMap());

    await _reallocateAndRecalculate(chartId);
  }

  @override
  Future<void> mergeCycleWithPrevious(String cycleId) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final cyclesSnapshot = await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .get();

    final cycles = cyclesSnapshot.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();
    cycles.sort((a, b) => a.startDate.compareTo(b.startDate));

    final targetIndex = cycles.indexWhere((c) => c.id == cycleId);
    if (targetIndex <= 0) return;

    await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .doc(cycleId)
        .delete();

    await _reallocateAndRecalculate(chartId);
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

    final batch = _db.batch();
    batch.update(cycleRef, {
      'bipCodes': bipCodes,
      'dailyEntries': updatedEntries.map((k, v) => MapEntry(k, v.toMap())),
    });

    for (final entry in updatedEntries.values) {
      final subRef = cycleRef
          .collection('dailyEntries')
          .doc(entry.date.dateKey);
      batch.set(subRef, entry.toMap());
    }

    await batch.commit();
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
    if (chartId == null || user == null) {
      Services.logger.warning(
        'saveObservation invoked without active user or chart',
        category: 'observation',
        metadata: {
          'chartId': chartId,
          'userId': user?.uid,
          'date': date.toIso8601String(),
        },
      );
      return;
    }

    Services.logger.info(
      'Attempting to save observation',
      category: 'observation',
      metadata: {
        'chartId': chartId,
        'userId': user.uid,
        'date': date.toIso8601String(),
        'sensation': sensation.name,
        'stretch': stretch.name,
        'bleeding': bleeding.name,
      },
    );

    try {
      final dateStr = date.dateKey;
      final cyclesCol = _db
          .collection('charts')
          .doc(chartId)
          .collection('cycles');

      // Query specifically for the target cycle interval [startDate <= date] limit(1)
      final eligibleSnap = await cyclesCol
          .where('startDate', isLessThanOrEqualTo: dateStr)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      final isHeavyOrModerate =
          bleeding == Bleeding.heavy || bleeding == Bleeding.moderate;

      Cycle? targetCycle;

      if (eligibleSnap.docs.isEmpty) {
        final anySnap = await cyclesCol.orderBy('startDate').limit(1).get();
        if (anySnap.docs.isEmpty) {
          final newCycle = Cycle(
            id: dateStr,
            startDate: date,
            bipCodes: const ['6C'],
            dailyEntries: {},
          );
          await cyclesCol.doc(dateStr).set(newCycle.toMap());
          targetCycle = newCycle;
        } else {
          targetCycle = Cycle.fromMap(anySnap.docs.first.data());
        }
      } else {
        final latest = Cycle.fromMap(eligibleSnap.docs.first.data());
        if (isHeavyOrModerate) {
          final autoStart = CreightonLogic.evaluateAutoCycleStart(latest, date);
          if (autoStart != null) {
            final autoStartStr = autoStart.dateKey;
            final existingDoc = await cyclesCol.doc(autoStartStr).get();
            if (!existingDoc.exists) {
              final newCycle = Cycle(
                id: autoStartStr,
                startDate: autoStart,
                bipCodes: latest.bipCodes,
                dailyEntries: {},
              );
              await cyclesCol.doc(autoStartStr).set(newCycle.toMap());
              await _reallocateAndRecalculate(chartId);
              targetCycle = newCycle;
            } else {
              targetCycle = Cycle.fromMap(existingDoc.data()!);
            }
          } else {
            targetCycle = latest;
          }
        } else {
          targetCycle = latest;
        }
      }

      final targetCycleId = targetCycle.id;
      final dateKey = dateStr;

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

      final batch = _db.batch();
      final cycleRef = cyclesCol.doc(targetCycleId);
      batch.update(cycleRef, {
        'dailyEntries': updated.map((k, v) => MapEntry(k, v.toMap())),
      });

      final subRef = cycleRef.collection('dailyEntries').doc(dateKey);
      batch.set(subRef, resolved.toMap());

      await batch.commit();

      Services.logger.info(
        'Observation saved successfully',
        category: 'observation',
        metadata: {
          'chartId': chartId,
          'targetCycleId': targetCycleId,
          'date': dateKey,
          'obsId': newObs.id,
        },
      );
    } catch (e, st) {
      Services.logger.error(
        'Failed to save observation to Firestore',
        category: 'observation',
        metadata: {
          'chartId': chartId,
          'userId': user.uid,
          'userEmail': user.email,
          'targetDate': date.toIso8601String(),
        },
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
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
    final dateKey = date.dateKey;

    final currentEntries = Map<String, DailyEntry>.from(cycle.dailyEntries);
    final existingEntry = currentEntries[dateKey];
    if (existingEntry == null) return;

    final observations = existingEntry.observations
        .where((o) => o.id != observationId)
        .toList();

    final batch = _db.batch();
    final subRef = cycleRef.collection('dailyEntries').doc(dateKey);

    if (observations.isEmpty) {
      currentEntries.remove(dateKey);
      batch.delete(subRef);
    } else {
      final resolvedDaily = CreightonLogic.resolveDailyEntry(
        date: date,
        observations: observations,
      );
      currentEntries[dateKey] = resolvedDaily;
      batch.set(subRef, resolvedDaily.toMap());
    }

    // Recalculate stamps
    final updatedEntries = CreightonLogic.recalculateCycle(
      entries: currentEntries.values.toList(),
      bipCodes: cycle.bipCodes,
    );

    batch.update(cycleRef, {
      'dailyEntries': updatedEntries.map((k, v) => MapEntry(k, v.toMap())),
    });

    await batch.commit();
  }
}
