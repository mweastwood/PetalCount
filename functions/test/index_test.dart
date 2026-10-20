import 'package:functions/src/handlers.dart';
import 'package:functions/src/interop/firebase_admin.dart';
import 'package:functions/src/interop/firebase_functions.dart';
import 'package:functions/src/interop/node_interop.dart';
import 'package:functions/src/reminders.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Cloud Function Handlers (functions/lib/src/handlers.dart)', () {
    late MockFirestoreDatabase mockDb;
    late MockMessagingService mockMessaging;
    late MockAuthService mockAuth;
    late List<String> infoLogs;
    late List<(String, dynamic)> errorLogs;

    setUp(() {
      mockDb = MockFirestoreDatabase();
      mockMessaging = MockMessagingService();
      mockAuth = MockAuthService();
      infoLogs = [];
      errorLogs = [];
      onLogInfo = (msg) => infoLogs.add(msg);
      onLogError = (msg, err) => errorLogs.add((msg, err));
      setTestEnvOverride('NODE_ENV', 'test');
      setTestEnvOverride('FUNCTIONS_EMULATOR', null);
      setTestEnvOverride('REMINDER_TRIGGER_SECRET', null);
    });

    tearDown(() {
      onLogInfo = null;
      onLogError = null;
      clearTestEnvOverrides();
    });

    group('checkDailyObservationsAndNotify (Scheduled Handler)', () {
      test(
        'executes scheduled job successfully and logs completion metrics',
        () async {
          var callCount = 0;
          await handleCheckDailyObservationsAndNotify(
            db: mockDb,
            messaging: mockMessaging,
            remindersRunner: (db, messaging,
                {now, targetHour, forceChartId}) async {
              callCount++;
              return const DailyRemindersResult(
                chartsChecked: 5,
                remindersSent: 2,
                tokensNotified: 3,
              );
            },
          );

          expect(
            infoLogs,
            contains(
              'Executing checkDailyObservationsAndNotify scheduled cron job...',
            ),
          );
          expect(callCount, equals(1));
          expect(
            infoLogs,
            contains(
              'Completed daily reminder run: 5 charts checked, 2 reminders dispatched, 3 devices notified.',
            ),
          );
          expect(errorLogs, isEmpty);
        },
      );

      test(
        'catches and logs errors gracefully when reminder processing rejects',
        () async {
          final testError = Exception('Firestore unavailable');
          var callCount = 0;

          await handleCheckDailyObservationsAndNotify(
            db: mockDb,
            messaging: mockMessaging,
            remindersRunner: (db, messaging,
                {now, targetHour, forceChartId}) async {
              callCount++;
              throw testError;
            },
          );

          expect(
            infoLogs,
            contains(
              'Executing checkDailyObservationsAndNotify scheduled cron job...',
            ),
          );
          expect(callCount, equals(1));
          expect(errorLogs.length, equals(1));
          expect(
            errorLogs.first.$1,
            equals('Error executing checkDailyObservationsAndNotify:'),
          );
          expect(errorLogs.first.$2, same(testError));
        },
      );
    });

    group('triggerDailyRemindersManually (HTTP Handler)', () {
      test(
        'handles request with chartId and targetHour query parameters and returns 200',
        () async {
          final req = TestHttpRequest(
            query: {
              'chartId': 'chart_abc_123',
              'targetHour': '20',
            },
          );
          final res = TestHttpResponse();

          String? capturedForceChartId;
          int? capturedTargetHour;

          await handleTriggerDailyRemindersManually(
            req,
            res,
            db: mockDb,
            messaging: mockMessaging,
            auth: mockAuth,
            remindersRunner: (db, messaging,
                {now, targetHour, forceChartId}) async {
              capturedForceChartId = forceChartId;
              capturedTargetHour = targetHour;
              return const DailyRemindersResult(
                chartsChecked: 1,
                remindersSent: 1,
                tokensNotified: 2,
              );
            },
          );

          expect(capturedForceChartId, equals('chart_abc_123'));
          expect(capturedTargetHour, equals(20));
          expect(res.statusCode, equals(200));
          expect(
            res.responseData,
            equals({
              'success': true,
              'chartsChecked': 1,
              'remindersSent': 1,
              'tokensNotified': 2,
            }),
          );
          expect(errorLogs, isEmpty);
        },
      );

      test('handles request without query parameters and returns 200',
          () async {
        final req = TestHttpRequest(query: {});
        final res = TestHttpResponse();

        String? capturedForceChartId = 'sentinel';
        int? capturedTargetHour = -1;

        await handleTriggerDailyRemindersManually(
          req,
          res,
          db: mockDb,
          messaging: mockMessaging,
          auth: mockAuth,
          remindersRunner: (db, messaging,
              {now, targetHour, forceChartId}) async {
            capturedForceChartId = forceChartId;
            capturedTargetHour = targetHour;
            return const DailyRemindersResult(
              chartsChecked: 3,
              remindersSent: 0,
              tokensNotified: 0,
            );
          },
        );

        expect(capturedForceChartId, isNull);
        expect(capturedTargetHour, isNull);
        expect(res.statusCode, equals(200));
        expect(
          res.responseData,
          equals({
            'success': true,
            'chartsChecked': 3,
            'remindersSent': 0,
            'tokensNotified': 0,
          }),
        );
      });

      test(
        'returns HTTP 500 when processDailyReminders throws an Exception',
        () async {
          final req = TestHttpRequest(query: {});
          final res = TestHttpResponse();
          final error = Exception('Database connection failed');

          await handleTriggerDailyRemindersManually(
            req,
            res,
            db: mockDb,
            messaging: mockMessaging,
            auth: mockAuth,
            remindersRunner: (db, messaging,
                {now, targetHour, forceChartId}) async {
              throw error;
            },
          );

          expect(errorLogs.length, equals(1));
          expect(
            errorLogs.first.$1,
            equals('Error triggering reminders manually:'),
          );
          expect(errorLogs.first.$2, same(error));
          expect(res.statusCode, equals(500));
          expect(
            res.responseData,
            equals({
              'success': false,
              'error': 'Database connection failed',
            }),
          );
        },
      );

      test(
        'returns HTTP 500 when processDailyReminders throws a non-Error string rejection',
        () async {
          final req = TestHttpRequest(query: {});
          final res = TestHttpResponse();

          await handleTriggerDailyRemindersManually(
            req,
            res,
            db: mockDb,
            messaging: mockMessaging,
            auth: mockAuth,
            remindersRunner: (db, messaging,
                {now, targetHour, forceChartId}) async {
              // ignore: only_throw_errors
              throw 'Unexpected string failure';
            },
          );

          expect(errorLogs.length, equals(1));
          expect(
            errorLogs.first.$1,
            equals('Error triggering reminders manually:'),
          );
          expect(errorLogs.first.$2, equals('Unexpected string failure'));
          expect(res.statusCode, equals(500));
          expect(
            res.responseData,
            equals({
              'success': false,
              'error': 'Unexpected string failure',
            }),
          );
        },
      );

      group('when outside test/emulator environments', () {
        setUp(() {
          setTestEnvOverride('NODE_ENV', 'production');
          setTestEnvOverride('FUNCTIONS_EMULATOR', null);
          setTestEnvOverride(
            'REMINDER_TRIGGER_SECRET',
            'super_secret_admin_token',
          );
        });

        test(
          'returns HTTP 401 when neither x-admin-secret nor Bearer token is provided',
          () async {
            final req = TestHttpRequest(headers: {}, query: {});
            final res = TestHttpResponse();
            var called = false;

            await handleTriggerDailyRemindersManually(
              req,
              res,
              db: mockDb,
              messaging: mockMessaging,
              auth: mockAuth,
              remindersRunner: (db, messaging,
                  {now, targetHour, forceChartId}) async {
                called = true;
                return const DailyRemindersResult(
                  chartsChecked: 0,
                  remindersSent: 0,
                  tokensNotified: 0,
                );
              },
            );

            expect(res.statusCode, equals(401));
            expect(
              res.responseData,
              equals({
                'success': false,
                'error': 'Unauthorized request',
              }),
            );
            expect(called, isFalse);
          },
        );

        test(
          'allows request when valid x-admin-secret header matches REMINDER_TRIGGER_SECRET',
          () async {
            final req = TestHttpRequest(
              headers: {'x-admin-secret': 'super_secret_admin_token'},
              query: {},
            );
            final res = TestHttpResponse();
            var callCount = 0;

            await handleTriggerDailyRemindersManually(
              req,
              res,
              db: mockDb,
              messaging: mockMessaging,
              auth: mockAuth,
              remindersRunner: (db, messaging,
                  {now, targetHour, forceChartId}) async {
                callCount++;
                return const DailyRemindersResult(
                  chartsChecked: 1,
                  remindersSent: 1,
                  tokensNotified: 1,
                );
              },
            );

            expect(res.statusCode, equals(200));
            expect(callCount, equals(1));
          },
        );

        test(
          'allows request when valid Bearer Firebase ID token is verified',
          () async {
            mockAuth.onVerifyIdToken = (token) async => const DecodedIdToken(
                  uid: 'admin_uid',
                );
            final req = TestHttpRequest(
              headers: {'authorization': 'Bearer valid_firebase_id_token'},
              query: {},
            );
            final res = TestHttpResponse();
            var callCount = 0;

            await handleTriggerDailyRemindersManually(
              req,
              res,
              db: mockDb,
              messaging: mockMessaging,
              auth: mockAuth,
              remindersRunner: (db, messaging,
                  {now, targetHour, forceChartId}) async {
                callCount++;
                return const DailyRemindersResult(
                  chartsChecked: 1,
                  remindersSent: 0,
                  tokensNotified: 0,
                );
              },
            );

            expect(
              mockAuth.verifiedTokens,
              contains('valid_firebase_id_token'),
            );
            expect(res.statusCode, equals(200));
            expect(callCount, equals(1));
          },
        );
      });
    });

    group('onCycleWriteNotifyCollaborators (Firestore Handler)', () {
      test(
        'invokes processCollaboratorFertilityNotification with before and after cycle data',
        () async {
          String? capturedChartId;
          Map<String, dynamic>? capturedPrev;
          Map<String, dynamic>? capturedCurr;

          final event = FirestoreEvent(
            params: {'chartId': 'chart_123', 'cycleId': 'cycle_1'},
            data: FirestoreChange(
              before: MockDocumentSnapshot(
                'cycle_1',
                {'id': 'cycle_1', 'dailyEntries': {}},
                true,
              ),
              after: MockDocumentSnapshot(
                'cycle_1',
                {
                  'id': 'cycle_1',
                  'dailyEntries': {
                    '2026-06-15': {'stampType': 'peak'},
                  },
                },
                true,
              ),
            ),
          );

          await handleOnCycleWriteNotifyCollaborators(
            event,
            db: mockDb,
            messaging: mockMessaging,
            collaboratorRunner: (db, msg, chartId, prev, curr) async {
              capturedChartId = chartId;
              capturedPrev = prev;
              capturedCurr = curr;
              return const CollaboratorNotificationResult(
                notificationsDispatched: 1,
                tokensNotified: 1,
              );
            },
          );

          expect(capturedChartId, equals('chart_123'));
          expect(capturedPrev, equals({'id': 'cycle_1', 'dailyEntries': {}}));
          expect(
            capturedCurr?['dailyEntries'],
            equals({
              '2026-06-15': {'stampType': 'peak'},
            }),
          );
          expect(errorLogs, isEmpty);
        },
      );
    });
  });
}
