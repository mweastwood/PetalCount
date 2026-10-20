import 'dart:convert';
import 'dart:js' as js;
import 'package:functions/src/handlers.dart';
import 'package:functions/src/interop/firebase_admin.dart';
import 'package:functions/src/interop/firebase_functions.dart';
import 'package:functions/src/interop/node_interop.dart';
import 'package:functions/src/reminders.dart';

DateTime? _parseJsDate(dynamic rawNow) {
  if (rawNow == null) return null;
  if (rawNow is DateTime) return rawNow;
  if (rawNow is num) {
    return DateTime.fromMillisecondsSinceEpoch(rawNow.toInt(), isUtc: true);
  }
  if (rawNow is String) {
    return DateTime.tryParse(rawNow);
  }
  if (rawNow is js.JsObject) {
    try {
      final ms = rawNow.callMethod('getTime') as num?;
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true);
      }
    } catch (_) {}
  }
  try {
    final jsonStr =
        js.context['JSON'].callMethod('stringify', [rawNow]) as String?;
    if (jsonStr != null &&
        jsonStr.length >= 2 &&
        jsonStr.startsWith('"') &&
        jsonStr.endsWith('"')) {
      return DateTime.tryParse(jsonStr.substring(1, jsonStr.length - 1));
    }
  } catch (_) {}
  return null;
}

Map<String, dynamic>? _parseJsMap(dynamic rawObj) {
  if (rawObj == null) return null;
  if (rawObj is Map<String, dynamic>) return rawObj;
  if (rawObj is Map) return Map<String, dynamic>.from(rawObj);
  try {
    final jsonStr =
        js.context['JSON'].callMethod('stringify', [rawObj]) as String?;
    if (jsonStr != null) {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
  } catch (_) {}
  return null;
}

void main() {
  initializeFirebaseAdmin();

  // 1. Scheduled Cloud Function: checkDailyObservationsAndNotify
  final checkDailyObservationsAndNotifyFn = onSchedule(
    {
      'schedule': '0 * * * *',
      'timeZone': 'UTC',
      'memory': '256MiB',
      'maxInstances': 1,
    },
    (event) async {
      await handleCheckDailyObservationsAndNotify();
    },
  );
  exportFunction(
    'checkDailyObservationsAndNotify',
    checkDailyObservationsAndNotifyFn,
  );

  // 2. HTTP Cloud Function: triggerDailyRemindersManually
  final triggerDailyRemindersManuallyFn = onRequest(
    {
      'memory': '256MiB',
    },
    (req, res) async {
      await handleTriggerDailyRemindersManually(req, res);
    },
  );
  exportFunction(
    'triggerDailyRemindersManually',
    triggerDailyRemindersManuallyFn,
  );

  // 3. Firestore Trigger: onCycleWriteNotifyCollaborators
  final onCycleWriteNotifyCollaboratorsFn = onDocumentWritten(
    'charts/{chartId}/cycles/{cycleId}',
    (event) async {
      await handleOnCycleWriteNotifyCollaborators(event);
    },
  );
  exportFunction(
    'onCycleWriteNotifyCollaborators',
    onCycleWriteNotifyCollaboratorsFn,
  );

  // 4. Direct helper exports for testing & interop verification parity
  exportFunction(
    'getLocalTimeInfo',
    js.allowInterop(([dynamic rawNow, String? timeZone]) {
      final now = _parseJsDate(rawNow);
      final info = getLocalTimeInfo(
        now,
        timeZone ?? 'America/Los_Angeles',
      );
      return js.JsObject.jsify(info.toJson());
    }),
  );

  exportFunction(
    'checkChartHasObservationForDate',
    js.allowInterop((dynamic jsDb, String chartId, String dateKey) {
      final db = getFirebaseAdminDb(jsDb);
      return futureToJsPromise(
        checkChartHasObservationForDate(db, chartId, dateKey),
      );
    }),
  );

  exportFunction(
    'processDailyReminders',
    js.allowInterop(([dynamic jsDb, dynamic jsMessaging, dynamic rawOptions]) {
      final db = getFirebaseAdminDb(jsDb);
      final messaging = getFirebaseAdminMessaging(jsMessaging);
      DateTime? now;
      int? targetHour;
      String? forceChartId;
      if (rawOptions != null) {
        final dynamic rawNow =
            rawOptions is js.JsObject ? rawOptions['now'] : null;
        now = _parseJsDate(rawNow);
        final optsMap = _parseJsMap(rawOptions);
        if (optsMap != null) {
          now ??= _parseJsDate(optsMap['now']);
          if (optsMap['targetHour'] is num) {
            targetHour = (optsMap['targetHour'] as num).toInt();
          }
          if (optsMap.containsKey('forceChartId') &&
              optsMap['forceChartId'] is String) {
            forceChartId = optsMap['forceChartId'] as String;
          }
        }
      }
      return futureToJsPromise(
        processDailyReminders(
          db,
          messaging,
          now: now,
          targetHour: targetHour,
          forceChartId: forceChartId,
        ).then((res) => res.toJson()),
      );
    }),
  );

  exportFunction(
    'processCollaboratorFertilityNotification',
    js.allowInterop((
      dynamic jsDb,
      dynamic jsMessaging,
      String chartId, [
      dynamic rawPrevCycle,
      dynamic rawCurrCycle,
    ]) {
      final db = getFirebaseAdminDb(jsDb);
      final messaging = getFirebaseAdminMessaging(jsMessaging);
      final prevCycle = _parseJsMap(rawPrevCycle);
      final currCycle = _parseJsMap(rawCurrCycle);
      return futureToJsPromise(
        processCollaboratorFertilityNotification(
          db,
          messaging,
          chartId,
          prevCycle,
          currCycle,
        ).then((res) => res.toJson()),
      );
    }),
  );

  exportFunction(
    'getFirebaseAdminDb',
    js.allowInterop(([dynamic jsDb]) {
      final db = getFirebaseAdminDb(jsDb);
      return db.rawDb;
    }),
  );
}
