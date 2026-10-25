part of '../in_memory_database_service.dart';

mixin _InMemorySupplementOps on _InMemoryDatabaseServiceBase {
  @override
  Stream<List<SupplementItem>> streamSupplements() {
    late StreamController<List<SupplementItem>> c;
    StreamSubscription<List<SupplementItem>>? sub;
    c = StreamController<List<SupplementItem>>.broadcast(
      onListen: () {
        final chartId = _chartId;
        if (chartId != null) {
          c.add((_supplements[chartId] ?? {}).values.toList());
        } else {
          c.add(const []);
        }
        sub = _supplementsController.stream.listen(
          (data) {
            if (!c.isClosed) c.add(data);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!c.isClosed) c.addError(error, stackTrace);
          },
        );
      },
      onCancel: () {
        sub?.cancel();
        sub = null;
      },
    );
    return c.stream;
  }

  @visibleForTesting
  void emitSupplementsError(Object error, [StackTrace? stackTrace]) {
    _supplementsController.addError(error, stackTrace);
  }

  @override
  Future<void> saveSupplement(SupplementItem item) async {
    final chartId = _chartId;
    if (chartId == null) return;
    _supplements.putIfAbsent(chartId, () => {});
    _supplements[chartId]![item.id] = item;
    _emitSupplements();
  }

  @override
  Future<void> deleteSupplement(String supplementId) async {
    final chartId = _chartId;
    if (chartId == null) return;
    _supplements[chartId]?.remove(supplementId);
    _emitSupplements();
  }

  @override
  Stream<Map<String, DailySupplementLog>> streamDailySupplementLogs() {
    late StreamController<Map<String, DailySupplementLog>> c;
    StreamSubscription<Map<String, DailySupplementLog>>? sub;
    c = StreamController<Map<String, DailySupplementLog>>.broadcast(
      onListen: () {
        final chartId = _chartId;
        if (chartId != null) {
          c.add(Map.unmodifiable(_supplementLogs[chartId] ?? {}));
        } else {
          c.add(const {});
        }
        sub = _supplementLogsController.stream.listen(
          (data) {
            if (!c.isClosed) c.add(data);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!c.isClosed) c.addError(error, stackTrace);
          },
        );
      },
      onCancel: () {
        sub?.cancel();
        sub = null;
      },
    );
    return c.stream;
  }

  @visibleForTesting
  void emitDailySupplementLogsError(Object error, [StackTrace? stackTrace]) {
    _supplementLogsController.addError(error, stackTrace);
  }

  @override
  Future<void> logSupplementDose({
    required DateTime date,
    required String supplementId,
    required SupplementTimeOfDay timeOfDay,
    required bool taken,
  }) async {
    final chartId = _chartId;
    if (chartId == null) return;
    final dateKey = date.dateKey;
    _supplementLogs.putIfAbsent(chartId, () => {});
    final currentLog =
        _supplementLogs[chartId]![dateKey] ??
        DailySupplementLog(date: date, takenDoses: {});
    final updatedLog = currentLog.withToggled(supplementId, timeOfDay, taken);
    _supplementLogs[chartId]![dateKey] = updatedLog;
    _emitSupplementLogs();
  }
}
