part of '../firebase_database_service.dart';

mixin _FirebaseSupplementOps on _FirebaseDatabaseServiceBase {
  @override
  Stream<List<SupplementItem>> streamSupplements() {
    return _buildAuthGatedStream<List<SupplementItem>>(
      emptyValue: const [],
      debugLabel: 'supplements',
      subscribe: (chartId) => _db
          .collection('charts')
          .doc(chartId)
          .collection('supplements')
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => SupplementItem.fromMap(doc.data()))
                .toList(),
          ),
    );
  }

  @override
  Future<void> saveSupplement(SupplementItem item) async {
    final chartId = _cachedChartId;
    if (chartId == null) return;

    await _db
        .collection('charts')
        .doc(chartId)
        .collection('supplements')
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteSupplement(String supplementId) async {
    final chartId = _cachedChartId;
    if (chartId == null) return;

    await _db
        .collection('charts')
        .doc(chartId)
        .collection('supplements')
        .doc(supplementId)
        .delete();
  }

  @override
  Stream<Map<String, DailySupplementLog>> streamDailySupplementLogs() {
    return _buildAuthGatedStream<Map<String, DailySupplementLog>>(
      emptyValue: const {},
      debugLabel: 'daily supplement logs',
      subscribe: (chartId) => _db
          .collection('charts')
          .doc(chartId)
          .collection('supplementLogs')
          .snapshots()
          .map((snap) {
            final map = <String, DailySupplementLog>{};
            for (final doc in snap.docs) {
              map[doc.id] = DailySupplementLog.fromMap(doc.data());
            }
            return map;
          }),
    );
  }

  @override
  Future<void> logSupplementDose({
    required DateTime date,
    required String supplementId,
    required SupplementTimeOfDay timeOfDay,
    required bool taken,
  }) async {
    final chartId = _cachedChartId;
    if (chartId == null) return;

    final dateKey = date.dateKey;
    final logRef = _db
        .collection('charts')
        .doc(chartId)
        .collection('supplementLogs')
        .doc(dateKey);

    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(logRef);
      DailySupplementLog log;
      if (doc.exists && doc.data() != null) {
        log = DailySupplementLog.fromMap(doc.data()!);
      } else {
        log = DailySupplementLog(date: date, takenDoses: {});
      }

      final updatedLog = log.withToggled(supplementId, timeOfDay, taken);
      transaction.set(logRef, updatedLog.toMap());
    });
  }
}
