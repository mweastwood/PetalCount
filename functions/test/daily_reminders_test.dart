import 'package:functions/src/interop/firebase_admin.dart';
import 'package:functions/src/reminders.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('getLocalTimeInfo', () {
    test(
      'computes correct hour and dateKey for America/Los_Angeles (PDT / UTC-7)',
      () {
        // 2026-08-21 04:30:00 UTC is 2026-08-20 21:30:00 PDT
        final utcDate = DateTime.utc(2026, 8, 21, 4, 30, 0);
        final info = getLocalTimeInfo(utcDate, 'America/Los_Angeles');

        expect(info.hour, equals(21));
        expect(info.dateKey, equals('2026-08-20'));
      },
    );

    test(
      'computes correct hour and dateKey for America/New_York (EDT / UTC-4)',
      () {
        // 2026-08-21 01:15:00 UTC is 2026-08-20 21:15:00 EDT
        final utcDate = DateTime.utc(2026, 8, 21, 1, 15, 0);
        final info = getLocalTimeInfo(utcDate, 'America/New_York');

        expect(info.hour, equals(21));
        expect(info.dateKey, equals('2026-08-20'));
      },
    );

    test('falls back gracefully when given an invalid timezone name', () {
      final utcDate = DateTime.utc(2026, 8, 21, 4, 0, 0);
      final info = getLocalTimeInfo(utcDate, 'Invalid/Timezone_Name');

      expect(info.hour, greaterThanOrEqualTo(0));
      expect(info.hour, lessThan(24));
      expect(info.dateKey, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

      final laInfo = getLocalTimeInfo(utcDate, 'America/Los_Angeles');
      expect(info, equals(laInfo));
    });
  });

  group('checkChartHasObservationForDate', () {
    test(
      'returns true when an observation exists in the dailyEntries subcollection',
      () async {
        final mockDb = MockFirestoreDatabase();
        final cycleRef = mockDb.collection('charts/chart_123/cycles').doc('c1');
        cycleRef.docData = <String, dynamic>{};
        final dailyRef = cycleRef.collection('dailyEntries').doc('2026-08-20');
        dailyRef.docData = {
          'date': '2026-08-20',
          'observations': [
            {'id': 'obs_1', 'sensation': 'dry'},
          ],
        };

        final result = await checkChartHasObservationForDate(
          mockDb,
          'chart_123',
          '2026-08-20',
        );
        expect(result, isTrue);
      },
    );

    test(
      'returns false immediately when eligibleCyclesSnap is empty without querying allCycles fallback',
      () async {
        final mockDb = MockFirestoreDatabase();
        final cyclesCol = mockDb.collection('charts/chart_fallback/cycles');
        final limitCalls = <int>[];
        cyclesCol.onLimit = (count) => limitCalls.add(count);
        cyclesCol.cannedDocs = [];

        final result = await checkChartHasObservationForDate(
          mockDb,
          'chart_fallback',
          '2026-08-20',
        );
        expect(result, isFalse);
        expect(limitCalls, equals([1]));
      },
    );

    test(
      'returns true when top-level dailyEntries map on cycle document contains observation',
      () async {
        final mockDb = MockFirestoreDatabase();
        final cycleRef = mockDb.collection('charts/chart_map/cycles').doc('c1');
        cycleRef.docData = {
          'dailyEntries': {
            '2026-08-20': {
              'observations': [
                {'id': 'obs_map', 'sensation': 'damp'},
              ],
            },
          },
        };

        final result = await checkChartHasObservationForDate(
          mockDb,
          'chart_map',
          '2026-08-20',
        );
        expect(result, isTrue);
      },
    );

    test(
      'returns false when no observations are recorded for dateKey',
      () async {
        final mockDb = MockFirestoreDatabase();
        final cycleRef = mockDb.collection('charts/chart_123/cycles').doc('c1');
        cycleRef.docData = {'dailyEntries': <String, dynamic>{}};

        final result = await checkChartHasObservationForDate(
          mockDb,
          'chart_123',
          '2026-08-20',
        );
        expect(result, isFalse);
      },
    );
  });

  group('processDailyReminders', () {
    test(
      'dispatches FCM reminders when 9:00 PM and nothing logged today',
      () async {
        final now = DateTime.utc(2026, 8, 21, 4, 0, 0); // 9:00 PM PDT on Aug 20
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_1').docData = {
          'id': 'chart_1',
          'userIds': ['user_husband', 'user_wife'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };
        mockDb.collection('charts/chart_1/cycles').doc('c1').docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_husband').docData = {
          'uid': 'user_husband',
          'fcmTokens': ['token_husband_device_1'],
        };
        mockDb.collection('users').doc('user_wife').docData = {
          'uid': 'user_wife',
          'fcmTokens': ['token_wife_device_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(2));

        expect(mockMessaging.sentMessages.length, equals(1));
        final sent = mockMessaging.sentMessages.first;
        expect(
          sent['tokens'],
          equals(['token_husband_device_1', 'token_wife_device_1']),
        );
        expect(
          sent['notification'],
          equals({
            'title': 'Daily Observation Reminder',
            'body':
                "Don't forget to log your Creighton observations for today!",
          }),
        );
      },
    );

    test(
      'processes chart regardless of local hour when forceChartId is provided',
      () async {
        // 10:00 AM UTC -> 3:00 AM PDT (hour 3, not targetHour 21)
        final now = DateTime.utc(2026, 8, 21, 10, 0, 0);
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_forced').docData = {
          'id': 'chart_forced',
          'userIds': ['user_1'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };
        mockDb.collection('charts/chart_forced/cycles').doc('c1').docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_1').docData = {
          'uid': 'user_1',
          'fcmTokens': ['token_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
          forceChartId: 'chart_forced',
        );

        expect(
          mockDb.collection('charts').docCalls,
          contains('chart_forced'),
        );
        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(1));
      },
    );

    test(
      'processes chart when forceChartId is provided even if chart data has no internal id field',
      () async {
        final now = DateTime.utc(2026, 8, 21, 10, 0, 0);
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_without_id_field').docData = {
          // Notice: 'id' field is omitted from document data dictionary
          'userIds': ['user_1'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };
        mockDb
            .collection('charts/chart_without_id_field/cycles')
            .doc('c1')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_1').docData = {
          'uid': 'user_1',
          'fcmTokens': ['token_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
          forceChartId: 'chart_without_id_field',
        );

        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(1));
      },
    );

    test(
      'returns zero counts when forceChartId document does not exist',
      () async {
        final mockDb = MockFirestoreDatabase();
        mockDb.collection('charts').doc('nonexistent_chart').isExisting = false;

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          forceChartId: 'nonexistent_chart',
        );

        expect(result.chartsChecked, equals(0));
        expect(result.remindersSent, equals(0));
        expect(result.tokensNotified, equals(0));
        expect(mockMessaging.sentMessages, isEmpty);
      },
    );

    test(
      'returns zero counts when forceChartId is empty string or whitespace without querying all charts',
      () async {
        final mockDb = MockFirestoreDatabase();
        final mockMessaging = MockMessagingService();

        final resultEmpty = await processDailyReminders(
          mockDb,
          mockMessaging,
          forceChartId: '',
        );
        expect(resultEmpty.chartsChecked, equals(0));
        expect(resultEmpty.remindersSent, equals(0));
        expect(resultEmpty.tokensNotified, equals(0));
        expect(mockDb.collection('charts').getCalls, equals(0));
        expect(mockDb.collection('charts').docCalls, isEmpty);

        final resultWhitespace = await processDailyReminders(
          mockDb,
          mockMessaging,
          forceChartId: '   ',
        );
        expect(resultWhitespace.chartsChecked, equals(0));
        expect(resultWhitespace.remindersSent, equals(0));
        expect(resultWhitespace.tokensNotified, equals(0));
        expect(mockDb.collection('charts').getCalls, equals(0));
        expect(mockDb.collection('charts').docCalls, isEmpty);
        expect(mockMessaging.sentMessages, isEmpty);
      },
    );

    test(
      'trims whitespace from forceChartId before looking up document',
      () async {
        final now = DateTime.utc(2026, 8, 21, 10, 0, 0);
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_forced').docData = {
          'id': 'chart_forced',
          'userIds': ['user_1'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };
        mockDb.collection('charts/chart_forced/cycles').doc('c1').docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_1').docData = {
          'uid': 'user_1',
          'fcmTokens': ['token_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
          forceChartId: '  chart_forced  ',
        );

        expect(
          mockDb.collection('charts').docCalls,
          contains('chart_forced'),
        );
        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(1));
      },
    );

    test('skips chart if reminderEnabled is false', () async {
      final now = DateTime.utc(2026, 8, 21, 4, 0, 0);
      final mockDb = MockFirestoreDatabase();

      mockDb.collection('charts').doc('chart_disabled').docData = {
        'id': 'chart_disabled',
        'userIds': ['user_1'],
        'reminderEnabled': false,
        'timezone': 'America/Los_Angeles',
      };

      final mockMessaging = MockMessagingService();
      final result = await processDailyReminders(
        mockDb,
        mockMessaging,
        now: now,
      );

      expect(result.chartsChecked, equals(0));
      expect(result.remindersSent, equals(0));
      expect(mockMessaging.sentMessages, isEmpty);
    });

    test(
      'skips chart silently when all users have no FCM tokens',
      () async {
        final now = DateTime.utc(2026, 8, 21, 4, 0, 0);
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_empty_tokens').docData = {
          'id': 'chart_empty_tokens',
          'userIds': ['user_no_token', 'user_empty_array'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };
        mockDb
            .collection('charts/chart_empty_tokens/cycles')
            .doc('c1')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_no_token').docData = {
          'uid': 'user_no_token',
          'fcmTokens': null,
        };
        mockDb.collection('users').doc('user_empty_array').docData = {
          'uid': 'user_empty_array',
          'fcmTokens': ['', ''],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(0));
        expect(result.tokensNotified, equals(0));
        expect(mockMessaging.sentMessages, isEmpty);
      },
    );

    test(
      'handles non-existent user documents and prunes invalid fcmTokens cleanly',
      () async {
        final now = DateTime.utc(2026, 8, 21, 4, 0, 0);
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_with_missing_user').docData = {
          'id': 'chart_with_missing_user',
          'userIds': ['user_valid', 'user_missing'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };
        mockDb
            .collection('charts/chart_with_missing_user/cycles')
            .doc('c1')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };

        final validUserRef = mockDb.collection('users').doc('user_valid');
        validUserRef.docData = {
          'uid': 'user_valid',
          'fcmTokens': [
            'valid_token_1',
            'invalid_token_expired',
            'invalid_token_bad_format',
          ],
        };
        mockDb.collection('users').doc('user_missing').isExisting = false;

        final mockMessaging = MockMessagingService(
          onSendEachForMulticast: (_) async => const BatchResponse(
            successCount: 1,
            failureCount: 2,
            responses: [
              SendResponse(success: true),
              SendResponse(
                success: false,
                errorCode: 'messaging/registration-token-not-registered',
              ),
              SendResponse(
                success: false,
                errorCode: 'messaging/invalid-registration-token',
              ),
            ],
          ),
        );

        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(1));
        expect(mockDb.getAllCalls, isNotEmpty);

        expect(validUserRef.updateCalls.length, equals(1));
        expect(
          validUserRef.updateCalls.first,
          equals({
            'fcmTokens': FieldValue.arrayRemove([
              'invalid_token_expired',
              'invalid_token_bad_format',
            ]),
          }),
        );
      },
    );

    test(
      'returns early with zeroes when charts collection is empty without calling getAll',
      () async {
        final mockDb = MockFirestoreDatabase();
        final mockMessaging = MockMessagingService();

        final result = await processDailyReminders(mockDb, mockMessaging);

        expect(
          result,
          equals(
            const DailyRemindersResult(
              chartsChecked: 0,
              remindersSent: 0,
              tokensNotified: 0,
            ),
          ),
        );
        expect(mockDb.getAllCalls, isEmpty);
        expect(mockMessaging.sentMessages, isEmpty);
      },
    );

    test(
      'processes multiple eligible charts concurrently with deduplicated batch user fetch and aggregates metrics',
      () async {
        final now = DateTime.utc(2026, 8, 21, 4, 0, 0); // 9:00 PM PDT on Aug 20
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_1').docData = {
          'id': 'chart_1',
          'userIds': ['user_shared', 'user_1'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };
        mockDb.collection('charts').doc('chart_2').docData = {
          'id': 'chart_2',
          'userIds': ['user_shared', 'user_2'],
          'reminderEnabled': true,
          'timezone': 'America/Los_Angeles',
        };

        // Chart 1 has no observation logged; Chart 2 has an observation logged
        mockDb.collection('charts/chart_1/cycles').doc('c1').docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('charts/chart_2/cycles').doc('c2').docData = {
          'dailyEntries': {
            '2026-08-20': {
              'observations': [
                {'id': 'obs_today'},
              ],
            },
          },
        };

        mockDb.collection('users').doc('user_shared').docData = {
          'uid': 'user_shared',
          'fcmTokens': ['token_shared_1'],
        };
        mockDb.collection('users').doc('user_1').docData = {
          'uid': 'user_1',
          'fcmTokens': ['token_user1_1'],
        };
        mockDb.collection('users').doc('user_2').docData = {
          'uid': 'user_2',
          'fcmTokens': ['token_user2_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(result.chartsChecked, equals(2));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(2));

        expect(mockDb.getAllCalls.length, equals(1));
        final fetchedUserIds =
            mockDb.getAllCalls.first.map((r) => r.id).toList()..sort();
        expect(
          fetchedUserIds,
          equals(['user_1', 'user_2', 'user_shared']),
        );

        expect(mockMessaging.sentMessages.length, equals(1));
        expect(
          mockMessaging.sentMessages.first['tokens'],
          equals(['token_shared_1', 'token_user1_1']),
        );
        expect(
          (mockMessaging.sentMessages.first['data'] as Map)['chartId'],
          equals('chart_1'),
        );
      },
    );

    test(
      'ignores non-eligible charts without fetching user docs or checking observations',
      () async {
        final now = DateTime.utc(2026, 8, 21, 4, 0, 0); // 9:00 PM PDT on Aug 20
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_disabled').docData = {
          'id': 'chart_disabled',
          'userIds': ['user_disabled'],
          'reminderEnabled': false,
          'timezone': 'America/Los_Angeles',
        };
        mockDb.collection('charts').doc('chart_wrong_hour').docData = {
          'id': 'chart_wrong_hour',
          'userIds': ['user_wrong_hour'],
          'reminderEnabled': true,
          'timezone': 'Europe/London', // 5:00 AM local time, not 21:00
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(
          result,
          equals(
            const DailyRemindersResult(
              chartsChecked: 0,
              remindersSent: 0,
              tokensNotified: 0,
            ),
          ),
        );
        expect(mockDb.getAllCalls, isEmpty);
        expect(mockMessaging.sentMessages, isEmpty);
      },
    );

    test(
      'respects explicit chart.timezone for non-Pacific timezones (e.g. America/New_York at 21:00 EDT)',
      () async {
        // 2026-08-21 01:00:00 UTC is 2026-08-20 21:00:00 EDT (and 18:00:00 PDT)
        final now = DateTime.utc(2026, 8, 21, 1, 0, 0);
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_ny').docData = {
          'id': 'chart_ny',
          'userIds': ['user_ny'],
          'reminderEnabled': true,
          'timezone': 'America/New_York',
        };
        mockDb.collection('charts/chart_ny/cycles').doc('c1').docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_ny').docData = {
          'uid': 'user_ny',
          'timezone': 'America/New_York',
          'fcmTokens': ['token_ny_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(1));
        expect(
          mockMessaging.sentMessages.first['tokens'],
          equals(['token_ny_1']),
        );
        expect(
          (mockMessaging.sentMessages.first['data'] as Map)['date'],
          equals('2026-08-20'),
        );
      },
    );

    test(
      'falls back to userData.timezone when chart.timezone is undefined and backfills the chart doc',
      () async {
        // 2026-08-21 01:00:00 UTC is 2026-08-20 21:00:00 EDT
        final now = DateTime.utc(2026, 8, 21, 1, 0, 0);
        final mockDb = MockFirestoreDatabase();

        final chartRef =
            mockDb.collection('charts').doc('chart_needs_backfill');
        chartRef.docData = {
          'id': 'chart_needs_backfill',
          'userIds': ['user_owner'],
          'reminderEnabled': true,
        };
        mockDb
            .collection('charts/chart_needs_backfill/cycles')
            .doc('c1')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_owner').docData = {
          'uid': 'user_owner',
          'timezone': 'America/New_York',
          'fcmTokens': ['token_owner_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(chartRef.setCalls.length, equals(1));
        expect(
          chartRef.setCalls.first.data,
          equals({'timezone': 'America/New_York'}),
        );
        expect(chartRef.setCalls.first.merge, isTrue);
        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(1));
      },
    );

    test(
      'falls back to default America/Los_Angeles when both chart.timezone and user timezone are absent',
      () async {
        final nowNot9PM = DateTime.utc(2026, 8, 21, 1, 0, 0); // 18:00 PDT
        final now9PMPacific = DateTime.utc(2026, 8, 21, 4, 0, 0); // 21:00 PDT
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_no_tz').docData = {
          'id': 'chart_no_tz',
          'userIds': ['user_no_tz'],
          'reminderEnabled': true,
        };
        mockDb.collection('charts/chart_no_tz/cycles').doc('c1').docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_no_tz').docData = {
          'uid': 'user_no_tz',
          'fcmTokens': ['token_no_tz_1'],
        };

        final mockMessaging = MockMessagingService();

        final resultNot9PM = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: nowNot9PM,
        );
        expect(resultNot9PM.chartsChecked, equals(0));
        expect(resultNot9PM.remindersSent, equals(0));

        final result9PM = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now9PMPacific,
        );
        expect(result9PM.chartsChecked, equals(1));
        expect(result9PM.remindersSent, equals(1));
      },
    );

    test(
      'batches timezone lookups and deduplicates user references across multiple charts missing timezone',
      () async {
        final now = DateTime.utc(2026, 8, 21, 1, 0, 0); // 21:00 EDT
        final mockDb = MockFirestoreDatabase();

        final chartRef1 = mockDb.collection('charts').doc('chart_missing_tz_1');
        chartRef1.docData = {
          'id': 'chart_missing_tz_1',
          'userIds': ['user_shared_primary', 'user_collaborator_1'],
          'reminderEnabled': true,
        };
        final chartRef2 = mockDb.collection('charts').doc('chart_missing_tz_2');
        chartRef2.docData = {
          'id': 'chart_missing_tz_2',
          'userIds': ['user_shared_primary', 'user_collaborator_2'],
          'reminderEnabled': true,
        };
        final chartRefDisabled =
            mockDb.collection('charts').doc('chart_disabled_missing_tz');
        chartRefDisabled.docData = {
          'id': 'chart_disabled_missing_tz',
          'userIds': ['user_disabled_only'],
          'reminderEnabled': false,
        };

        mockDb
            .collection('charts/chart_missing_tz_1/cycles')
            .doc('c1')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb
            .collection('charts/chart_missing_tz_2/cycles')
            .doc('c2')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };

        mockDb.collection('users').doc('user_shared_primary').docData = {
          'uid': 'user_shared_primary',
          'timezone': 'America/New_York',
          'fcmTokens': ['token_shared_1'],
        };
        mockDb.collection('users').doc('user_collaborator_1').docData = {
          'uid': 'user_collaborator_1',
          'fcmTokens': ['token_collab_1'],
        };
        mockDb.collection('users').doc('user_collaborator_2').docData = {
          'uid': 'user_collaborator_2',
          'fcmTokens': ['token_collab_2'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
        );

        expect(result.chartsChecked, equals(2));
        expect(result.remindersSent, equals(2));

        // First getAll: deduplicated timezone lookup for ['user_shared_primary']
        expect(mockDb.getAllCalls.length, equals(2));
        expect(mockDb.getAllCalls.first.length, equals(1));
        expect(
          mockDb.getAllCalls.first.first.id,
          equals('user_shared_primary'),
        );

        expect(chartRef1.setCalls.length, equals(1));
        expect(
          chartRef1.setCalls.first.data,
          equals({'timezone': 'America/New_York'}),
        );
        expect(chartRef1.setCalls.first.merge, isTrue);

        expect(chartRef2.setCalls.length, equals(1));
        expect(
          chartRef2.setCalls.first.data,
          equals({'timezone': 'America/New_York'}),
        );
        expect(chartRef2.setCalls.first.merge, isTrue);
      },
    );

    test(
      'resiliently falls back to America/Los_Angeles when db.getAll fails during timezone lookup',
      () async {
        final now9PMPacific = DateTime.utc(2026, 8, 21, 4, 0, 0);
        final mockDb = MockFirestoreDatabase();

        final chartRef = mockDb.collection('charts').doc('chart_getAll_fails');
        chartRef.docData = {
          'id': 'chart_getAll_fails',
          'userIds': ['user_error_tz'],
          'reminderEnabled': true,
        };
        mockDb
            .collection('charts/chart_getAll_fails/cycles')
            .doc('c1')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };
        final userRef = mockDb.collection('users').doc('user_error_tz');
        userRef.docData = {
          'uid': 'user_error_tz',
          'fcmTokens': ['token_1'],
        };

        var firstGetAll = true;
        mockDb.onGetAll = (refs) async {
          if (firstGetAll) {
            firstGetAll = false;
            throw Exception('Firestore batch read error');
          }
          return Future.wait(refs.map((r) => r.get()));
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now9PMPacific,
        );

        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(chartRef.setCalls, isEmpty);
      },
    );

    test('handles individual backfill write failures gracefully', () async {
      final now = DateTime.utc(2026, 8, 21, 1, 0, 0); // 21:00 EDT
      final mockDb = MockFirestoreDatabase();

      final chartRef = mockDb.collection('charts').doc('chart_backfill_fails');
      chartRef.docData = {
        'id': 'chart_backfill_fails',
        'userIds': ['user_backfill_fails'],
        'reminderEnabled': true,
      };
      chartRef.onSet = (data, {required merge}) async {
        throw Exception('Backfill write permission denied');
      };

      mockDb
          .collection('charts/chart_backfill_fails/cycles')
          .doc('c1')
          .docData = {
        'dailyEntries': <String, dynamic>{},
      };
      mockDb.collection('users').doc('user_backfill_fails').docData = {
        'uid': 'user_backfill_fails',
        'timezone': 'America/New_York',
        'fcmTokens': ['token_backfill'],
      };

      final mockMessaging = MockMessagingService();
      final result = await processDailyReminders(
        mockDb,
        mockMessaging,
        now: now,
      );

      expect(result.chartsChecked, equals(1));
      expect(result.remindersSent, equals(1));
      expect(chartRef.setCalls.length, equals(1));
      expect(
        chartRef.setCalls.first.data,
        equals({'timezone': 'America/New_York'}),
      );
      expect(chartRef.setCalls.first.merge, isTrue);
    });

    test(
      'processes a forced chart via forceChartId even when reminderEnabled is false',
      () async {
        final now = DateTime.utc(2026, 8, 21, 14, 0, 0);
        final mockDb = MockFirestoreDatabase();

        mockDb.collection('charts').doc('chart_forced_disabled').docData = {
          'id': 'chart_forced_disabled',
          'userIds': ['user_forced'],
          'reminderEnabled': false,
          'timezone': 'America/Los_Angeles',
        };
        mockDb
            .collection('charts/chart_forced_disabled/cycles')
            .doc('c1')
            .docData = {
          'dailyEntries': <String, dynamic>{},
        };
        mockDb.collection('users').doc('user_forced').docData = {
          'uid': 'user_forced',
          'fcmTokens': ['token_forced_1'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processDailyReminders(
          mockDb,
          mockMessaging,
          now: now,
          forceChartId: 'chart_forced_disabled',
        );

        expect(result.chartsChecked, equals(1));
        expect(result.remindersSent, equals(1));
        expect(result.tokensNotified, equals(1));
      },
    );
  });
}
