part of '../firebase_database_service.dart';

mixin _FirebaseCycleOps on _FirebaseDatabaseServiceBase {
  @override
  Stream<List<Cycle>> streamCycles() {
    return _buildAuthGatedStream<List<Cycle>>(
      emptyValue: const [],
      debugLabel: 'cycles',
      subscribe: (chartId) => _db
          .collection('charts')
          .doc(chartId)
          .collection('cycles')
          .snapshots()
          .map((snap) {
            final cycles = snap.docs
                .map((doc) => Cycle.fromMap(doc.data()))
                .toList();
            cycles.sort((a, b) => b.startDate.compareTo(a.startDate));
            return cycles;
          }),
    );
  }

  Future<void> _applyCycleMutationPlan(
    String chartId,
    CycleMutationPlan mutationPlan,
  ) async {
    final cyclesCollection = _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles');

    final operations = <void Function(WriteBatch batch)>[];

    for (final cycleIdentifier in mutationPlan.cycleIdentifiersToDelete) {
      final cycleReference = cyclesCollection.doc(cycleIdentifier);
      final legacyDailySnapshot = await cycleReference
          .collection('dailyEntries')
          .get();
      for (final legacyDailyDocument in legacyDailySnapshot.docs) {
        operations.add((batch) => batch.delete(legacyDailyDocument.reference));
      }
      operations.add((batch) => batch.delete(cycleReference));
    }

    for (final cycle in mutationPlan.cyclesToUpsert) {
      final cycleReference = cyclesCollection.doc(cycle.id);
      final legacyDailySnapshot = await cycleReference
          .collection('dailyEntries')
          .get();
      for (final legacyDailyDocument in legacyDailySnapshot.docs) {
        operations.add((batch) => batch.delete(legacyDailyDocument.reference));
      }
      operations.add((batch) {
        batch.set(cycleReference, cycle.toMap());
      });
    }

    await _commitBatchedWrites(operations);
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
    await _applyCycleMutationPlan(
      chartId,
      CycleMutationPlan(cyclesToUpsert: updatedCycles),
    );
  }

  @override
  Future<void> startNewCycle(DateTime startDate, List<String> bipCodes) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final cyclesSnapshot = await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .get();
    final existingCycles = cyclesSnapshot.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();

    final mutationPlan = CycleCoordinator.planStartNewCycle(
      existingCycles: existingCycles,
      startDate: startDate,
      basicInfertilePatternCodes: bipCodes,
    );

    await _applyCycleMutationPlan(chartId, mutationPlan);
  }

  @override
  Future<void> deleteCycle(String cycleId) async {
    final chartId = currentChartId;
    if (chartId == null) return;

    final cyclesSnapshot = await _db
        .collection('charts')
        .doc(chartId)
        .collection('cycles')
        .get();
    final existingCycles = cyclesSnapshot.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();

    final mutationPlan = CycleCoordinator.planDeleteCycle(
      existingCycles: existingCycles,
      cycleIdentifier: cycleId,
    );

    await _applyCycleMutationPlan(chartId, mutationPlan);
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

    final existingCycles = cyclesSnapshot.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();

    final mutationPlan = CycleCoordinator.planUpdateCycleStartDate(
      existingCycles: existingCycles,
      cycleIdentifier: cycleId,
      newStartDate: newStartDate,
    );
    if (mutationPlan.cyclesToUpsert.isEmpty &&
        mutationPlan.cycleIdentifiersToDelete.isEmpty) {
      return;
    }

    await _applyCycleMutationPlan(chartId, mutationPlan);
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

    final existingCycles = cyclesSnapshot.docs
        .map((doc) => Cycle.fromMap(doc.data()))
        .toList();

    final mutationPlan = CycleCoordinator.planMergeCycleWithPrevious(
      existingCycles: existingCycles,
      cycleIdentifier: cycleId,
    );
    if (mutationPlan.cyclesToUpsert.isEmpty &&
        mutationPlan.cycleIdentifiersToDelete.isEmpty) {
      return;
    }

    await _applyCycleMutationPlan(chartId, mutationPlan);
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

    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(cycleRef);
      if (!doc.exists || doc.data() == null) return;

      final cycle = Cycle.fromMap(doc.data()!);
      final updatedCycle =
          CycleCoordinator.recalculateCycleWithBasicInfertilePattern(
            targetCycle: cycle,
            basicInfertilePatternCodes: bipCodes,
          );

      transaction.set(cycleRef, updatedCycle.toMap());
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
    Frequency frequency = Frequency.none,
    bool intercourse = false,
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
      final dateString = date.dateKey;
      final cyclesCollection = _db
          .collection('charts')
          .doc(chartId)
          .collection('cycles');

      final isHeavyOrModerate =
          bleeding == Bleeding.heavy || bleeding == Bleeding.moderate;

      String targetCycleId;

      final eligibleCyclesSnapshot = await cyclesCollection
          .where('startDate', isLessThanOrEqualTo: dateString)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (eligibleCyclesSnapshot.docs.isEmpty) {
        final anyCycleSnapshot = await cyclesCollection
            .orderBy('startDate')
            .limit(1)
            .get();
        final earliestCycle = anyCycleSnapshot.docs.isNotEmpty
            ? Cycle.fromMap(anyCycleSnapshot.docs.first.data())
            : null;
        final inheritedBipCodes =
            (earliestCycle != null && earliestCycle.bipCodes.isNotEmpty)
            ? earliestCycle.bipCodes
            : const <String>['6C'];
        if (anyCycleSnapshot.docs.isNotEmpty) {
          await startNewCycle(date, inheritedBipCodes);
        } else {
          final newCycle = Cycle(
            id: dateString,
            startDate: date,
            bipCodes: inheritedBipCodes,
            dailyEntries: const {},
          );
          await cyclesCollection.doc(dateString).set(newCycle.toMap());
        }
        targetCycleId = dateString;
      } else {
        final latest = Cycle.fromMap(eligibleCyclesSnapshot.docs.first.data());
        if (isHeavyOrModerate) {
          final autoStart = CreightonLogic.evaluateAutoCycleStart(latest, date);
          if (autoStart != null) {
            final autoStartKey = autoStart.dateKey;
            final existingDoc = await cyclesCollection.doc(autoStartKey).get();
            if (!existingDoc.exists) {
              await startNewCycle(autoStart, latest.bipCodes);
            }
            targetCycleId = autoStartKey;
          } else {
            targetCycleId = latest.id;
          }
        } else {
          targetCycleId = latest.id;
        }
      }

      final dateKey = dateString;

      final roleContext = await FirebaseDatabaseHelpers.resolveObservationRole(
        uid: user.uid,
        cachedRole: _cachedRole,
        getUserData: (uid) async {
          final userDoc = await _db.collection('users').doc(uid).get();
          return userDoc.data();
        },
      );
      final userRole = roleContext.userRole;
      if (roleContext.roleToCache != null) {
        _cachedRole = roleContext.roleToCache;
      }

      final createdObservation = Observation(
        id: CycleCoordinator.generateObservationIdentifier(),
        timestamp: date,
        sensation: sensation,
        stretch: stretch,
        colors: colors,
        consistencies: consistencies,
        bleeding: bleeding,
        bleedingColor: bleedingColor,
        frequency: frequency,
        intercourse: intercourse,
        painLevel: painLevel,
        painTypes: painTypes,
        comment: comment,
        userId: user.uid,
        userRole: userRole.code,
        isVdrsExplicit: isVdrsExplicit,
      );

      final cycleRef = cyclesCollection.doc(targetCycleId);
      late ObservationSaveResult saveResult;

      await _db.runTransaction((transaction) async {
        final cycleSnapshot = await transaction.get(cycleRef);
        final Cycle currentCycle;
        if (cycleSnapshot.exists && cycleSnapshot.data() != null) {
          currentCycle = Cycle.fromMap(cycleSnapshot.data()!);
        } else {
          currentCycle = Cycle(
            id: targetCycleId,
            startDate: date,
            bipCodes: const ['6C'],
            dailyEntries: const {},
          );
        }

        saveResult = CycleCoordinator.applyObservationToCycle(
          targetCycle: currentCycle,
          observation: createdObservation,
        );

        transaction.set(cycleRef, saveResult.updatedCycle.toMap());
      });

      final resolvedDaily = saveResult.resolvedDailyEntry;

      try {
        final context =
            await FirebaseDatabaseHelpers.resolveNotificationContext(
              uid: user.uid,
              chartId: chartId,
              cachedRole: _cachedRole ?? userRole.code,
              cachedPreferences: _cachedPreferencesByChart[chartId],
              getUserData: (uid) async {
                final doc = await _db.collection('users').doc(uid).get();
                return doc.data();
              },
              getChartData: (cId) async {
                final doc = await _db.collection('charts').doc(cId).get();
                return doc.data();
              },
            );

        if (roleContext.roleToCache != null && context.roleToCache != null) {
          _cachedRole = context.roleToCache;
        }
        _cachedPreferencesByChart[chartId] = context.preferencesToCache;

        await FirebaseDatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: resolvedDaily,
          bipCodes: saveResult.updatedCycle.bipCodes,
          userRole: context.userRole,
          preferences: context.preferences,
        );
      } catch (notificationError) {
        debugPrint('Warning: Notification dispatch error: $notificationError');
      }

      Services.logger.info(
        'Observation saved successfully',
        category: 'observation',
        metadata: {
          'chartId': chartId,
          'targetCycleId': targetCycleId,
          'date': dateKey,
          'obsId': createdObservation.id,
        },
      );
    } catch (error, stackTrace) {
      Services.logger.error(
        'Failed to save observation to Firestore',
        category: 'observation',
        metadata: {
          'chartId': chartId,
          'userId': user.uid,
          'userEmail': user.email,
          'targetDate': date.toIso8601String(),
        },
        error: error,
        stackTrace: stackTrace,
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

    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(cycleRef);
      if (!doc.exists || doc.data() == null) return;

      final cycle = Cycle.fromMap(doc.data()!);
      final updatedCycle = CycleCoordinator.removeObservationFromCycle(
        targetCycle: cycle,
        date: date,
        observationIdentifier: observationId,
      );
      if (updatedCycle == null) return;

      transaction.set(cycleRef, updatedCycle.toMap());
    });
  }
}
