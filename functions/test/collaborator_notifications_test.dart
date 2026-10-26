import 'package:core/core.dart';
import 'package:functions/src/interop/firebase_admin.dart';
import 'package:functions/src/reminders.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('processCollaboratorFertilityNotification', () {
    test(
      'dispatches push notification to partner when a fertile or Peak observation is added and prunes invalid tokens',
      () async {
        final previousCycle = <String, dynamic>{
          'id': '2026-06-01',
          'dailyEntries': <String, dynamic>{},
        };
        final currentCycle = <String, dynamic>{
          'id': '2026-06-01',
          'dailyEntries': {
            '2026-06-15': {
              'date': '2026-06-15',
              'stampType': 'peak',
              'peakDayLabel': 'P',
              'isPeakDay': true,
              'observations': [
                {
                  'id': 'obs_1',
                  'userId': 'user_wife',
                  'userRole': 'wife',
                },
              ],
            },
          },
        };

        final mockDb = MockFirestoreDatabase();
        mockDb.collection('charts').doc('chart_shared').docData = {
          'id': 'chart_shared',
          'userIds': ['user_wife', 'user_husband'],
          'notificationPreferences': {
            'fertilePatternAlerts': true,
            'partnerSupportReminders': true,
          },
        };

        final husbandRef = mockDb.collection('users').doc('user_husband');
        husbandRef.docData = {
          'uid': 'user_husband',
          'role': 'husband',
          'fcmTokens': ['husband_token_1', 'husband_stale_token'],
        };

        final mockMessaging = MockMessagingService(
          onSendEachForMulticast: (_) async => const BatchResponse(
            successCount: 1,
            failureCount: 1,
            responses: [
              SendResponse(success: true),
              SendResponse(
                success: false,
                errorCode: 'messaging/registration-token-not-registered',
              ),
            ],
          ),
        );

        final result = await processCollaboratorFertilityNotification(
          mockDb,
          mockMessaging,
          'chart_shared',
          previousCycle,
          currentCycle,
        );

        expect(result.notificationsDispatched, equals(1));
        expect(result.tokensNotified, equals(1));
        expect(mockMessaging.sentMessages.length, equals(1));
        expect(
          mockMessaging.sentMessages.first['tokens'],
          equals(['husband_token_1', 'husband_stale_token']),
        );
        expect(
          mockMessaging.sentMessages.first['notification'],
          equals({
            'title': 'Peak Day Identified',
            'body':
                'Partner alert: Today is marked as Peak (P) on your shared chart.',
          }),
        );
        expect(husbandRef.updateCalls.length, equals(1));
        expect(
          husbandRef.updateCalls.first,
          equals({
            'fcmTokens': FieldValue.arrayRemove(['husband_stale_token']),
          }),
        );
      },
    );

    test(
      'supports serialized package:core DailyEntry stampType (e.g. WhiteBaby) and NotificationPreferences',
      () async {
        final entry = DailyEntry(
          date: DateTime.utc(2026, 6, 16),
          resolvedVdrsCode: '10K',
          stampType: StampType.whiteBaby,
          observations: [
            Observation(
              id: 'obs_core_1',
              timestamp: DateTime.utc(2026, 6, 16, 12),
              sensation: Sensation.wet,
              stretch: Stretch.stretchy,
              consistencies: const [],
              colors: const [MucusColor.clear],
              bleeding: Bleeding.none,
              userId: 'user_wife',
              userRole: 'wife',
            ),
          ],
          painLevel: 0,
          painTypes: const [],
          comments: '',
        );

        final currentCycle = <String, dynamic>{
          'id': '2026-06-01',
          'dailyEntries': {
            '2026-06-16': entry.toMap(),
          },
        };

        final mockDb = MockFirestoreDatabase();
        mockDb.collection('charts').doc('chart_core').docData = {
          'id': 'chart_core',
          'userIds': ['user_wife', 'user_husband'],
          'notificationPreferences': const NotificationPreferences(
            fertilePatternAlerts: false,
            partnerSupportReminders: true,
          ).toMap(),
        };

        mockDb.collection('users').doc('user_husband').docData = {
          'uid': 'user_husband',
          'role': 'husband',
          'fcmTokens': ['husband_token_core'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processCollaboratorFertilityNotification(
          mockDb,
          mockMessaging,
          'chart_core',
          null,
          currentCycle,
        );

        expect(result.notificationsDispatched, equals(1));
        expect(result.tokensNotified, equals(1));
        expect(
          mockMessaging.sentMessages.first['notification'],
          equals({
            'title': 'Kindness & Support Reminder',
            'body':
                'Your chart is in a fertile phase—a thoughtful gesture or word of encouragement goes a long way today!',
          }),
        );
      },
    );

    test(
      'batch-fetches multiple collaborators via db.getAll in a single round-trip',
      () async {
        final currentCycle = <String, dynamic>{
          'id': '2026-06-01',
          'dailyEntries': {
            '2026-06-15': {
              'date': '2026-06-15',
              'stampType': 'peak',
              'peakDayLabel': 'P',
              'isPeakDay': true,
              'observations': [
                {
                  'id': 'obs_1',
                  'userId': 'user_wife',
                  'userRole': 'wife',
                },
              ],
            },
          },
        };

        final mockDb = MockFirestoreDatabase();
        mockDb.collection('charts').doc('chart_multi_collab').docData = {
          'id': 'chart_multi_collab',
          'userIds': ['user_wife', 'user_husband_1', 'user_husband_2'],
          'notificationPreferences': {
            'fertilePatternAlerts': true,
            'partnerSupportReminders': true,
          },
        };

        mockDb.collection('users').doc('user_husband_1').docData = {
          'uid': 'user_husband_1',
          'role': 'husband',
          'fcmTokens': ['token_h1'],
        };
        mockDb.collection('users').doc('user_husband_2').docData = {
          'uid': 'user_husband_2',
          'role': 'husband',
          'fcmTokens': ['token_h2'],
        };

        final mockMessaging = MockMessagingService();
        final result = await processCollaboratorFertilityNotification(
          mockDb,
          mockMessaging,
          'chart_multi_collab',
          null,
          currentCycle,
        );

        expect(result.notificationsDispatched, equals(2));
        expect(result.tokensNotified, equals(2));
        expect(mockDb.getAllCalls.length, equals(1));
        expect(
          mockDb.getAllCalls.first.map((r) => r.id).toList(),
          equals(['user_husband_1', 'user_husband_2']),
        );
      },
    );
  });
}
