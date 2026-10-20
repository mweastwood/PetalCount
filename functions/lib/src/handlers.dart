import 'interop/firebase_admin.dart';
import 'interop/firebase_functions.dart';
import 'interop/node_interop.dart';
import 'reminders.dart';

typedef ProcessDailyRemindersFn = Future<DailyRemindersResult> Function(
  FirestoreDatabase db,
  MessagingService messaging, {
  DateTime? now,
  int? targetHour,
  String? forceChartId,
});

typedef ProcessCollaboratorFertilityNotificationFn
    = Future<CollaboratorNotificationResult> Function(
  FirestoreDatabase database,
  MessagingService messaging,
  String chartIdentifier,
  Map<String, dynamic>? previousCycleData,
  Map<String, dynamic>? currentCycleData,
);

/// Handler for the `checkDailyObservationsAndNotify` scheduled Cloud Function.
Future<void> handleCheckDailyObservationsAndNotify({
  FirestoreDatabase? db,
  MessagingService? messaging,
  ProcessDailyRemindersFn remindersRunner = processDailyReminders,
}) async {
  logInfo('Executing checkDailyObservationsAndNotify scheduled cron job...');
  try {
    final effectiveDb = db ?? getFirebaseAdminDb();
    final effectiveMessaging = messaging ?? getFirebaseAdminMessaging();
    final result = await remindersRunner(effectiveDb, effectiveMessaging);
    logInfo(
      'Completed daily reminder run: ${result.chartsChecked} charts checked, ${result.remindersSent} reminders dispatched, ${result.tokensNotified} devices notified.',
    );
  } catch (error) {
    logError('Error executing checkDailyObservationsAndNotify:', error);
  }
}

/// Handler for the `triggerDailyRemindersManually` HTTP Cloud Function.
Future<void> handleTriggerDailyRemindersManually(
  HttpRequest request,
  HttpResponse response, {
  FirestoreDatabase? db,
  MessagingService? messaging,
  AuthService? auth,
  ProcessDailyRemindersFn remindersRunner = processDailyReminders,
}) async {
  final isTestOrEmulator =
      getEnv('NODE_ENV') == 'test' || getEnv('FUNCTIONS_EMULATOR') == 'true';

  if (!isTestOrEmulator) {
    final rawAuthHeader =
        request.headers['authorization'] ?? request.headers['Authorization'];
    final authorizationHeader = rawAuthHeader is String ? rawAuthHeader : '';

    final rawSecretHeader =
        request.headers['x-admin-secret'] ?? request.headers['X-Admin-Secret'];
    final adminSecretHeader = rawSecretHeader is String ? rawSecretHeader : '';

    final configuredSecret = getEnv('REMINDER_TRIGGER_SECRET') ?? '';

    var isAuthorized =
        configuredSecret.isNotEmpty && adminSecretHeader == configuredSecret;

    if (!isAuthorized && authorizationHeader.startsWith('Bearer ')) {
      final idToken = authorizationHeader.substring('Bearer '.length).trim();
      try {
        final effectiveAuth = auth ?? getFirebaseAdminAuth();
        await effectiveAuth.verifyIdToken(idToken);
        isAuthorized = true;
      } catch (_) {
        isAuthorized = false;
      }
    }

    if (!isAuthorized) {
      response.status(401).json({
        'success': false,
        'error': 'Unauthorized request',
      });
      return;
    }
  }

  final rawChartId = request.query['chartId'];
  final chartId = rawChartId is String ? rawChartId : null;
  final rawTargetHour = request.query['targetHour'];
  final parsedTargetHour =
      rawTargetHour != null ? int.tryParse(rawTargetHour.toString()) : null;

  try {
    final effectiveDb = db ?? getFirebaseAdminDb();
    final effectiveMessaging = messaging ?? getFirebaseAdminMessaging();
    final result = await remindersRunner(
      effectiveDb,
      effectiveMessaging,
      forceChartId: chartId,
      targetHour: parsedTargetHour,
    );
    response.status(200).json({
      'success': true,
      ...result.toJson(),
    });
  } catch (error) {
    String errorMessage;
    if (error is Exception) {
      final raw = error.toString();
      errorMessage = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length)
          : raw;
    } else if (error is Error) {
      errorMessage = error.toString();
    } else {
      // Check if JS Error object with .message or fallback to String
      errorMessage = _extractErrorMessage(error);
    }
    logError('Error triggering reminders manually:', error);
    response.status(500).json({
      'success': false,
      'error': errorMessage,
    });
  }
}

String _extractErrorMessage(dynamic error) {
  if (error == null) return 'Unknown error';
  final str = error.toString();
  if (str.startsWith('Error: ')) {
    return str.substring('Error: '.length);
  }
  return str;
}

/// Handler for the `onCycleWriteNotifyCollaborators` Firestore trigger.
Future<void> handleOnCycleWriteNotifyCollaborators(
  FirestoreEvent event, {
  FirestoreDatabase? db,
  MessagingService? messaging,
  ProcessCollaboratorFertilityNotificationFn collaboratorRunner =
      processCollaboratorFertilityNotification,
}) async {
  final chartId = event.params['chartId'];
  final change = event.data;
  if (chartId == null || chartId.isEmpty || change == null) {
    return;
  }

  final previousCycleData = change.before.exists ? change.before.data() : null;
  final currentCycleData = change.after.exists ? change.after.data() : null;

  try {
    final effectiveDb = db ?? getFirebaseAdminDb();
    final effectiveMessaging = messaging ?? getFirebaseAdminMessaging();
    await collaboratorRunner(
      effectiveDb,
      effectiveMessaging,
      chartId,
      previousCycleData,
      currentCycleData,
    );
  } catch (error) {
    logError('Error in onCycleWriteNotifyCollaborators:', error);
  }
}
