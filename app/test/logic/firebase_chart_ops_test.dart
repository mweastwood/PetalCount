import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';

import '../helpers/fake_firebase.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FakeFirebaseAuth fakeAuth;
  late FakeUser currentUser;
  late FirebaseDatabaseService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    currentUser = FakeUser(uid: 'user_123', email: 'user@example.com');
    fakeAuth = FakeFirebaseAuth(currentUser: currentUser);
    service = FirebaseDatabaseService(auth: fakeAuth, db: fakeDb);
  });

  // ===========================================================================
  // Group 1: Partner Invitation Flow
  // ===========================================================================
  group('Group 1: Partner Invitation Lifecycle', () {
    const chartId = 'chart_abc';

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {
        'id': chartId,
        'userIds': ['user_123'],
        'emails': ['user@example.com'],
      };
    });

    test(
      'invitePartner: creates document in invitations with pending status and normalized email',
      () async {
        const partnerEmail = '  Partner@Example.COM ';
        await service.invitePartner(partnerEmail);

        final expectedDoc = fakeDb.store['invitations/partner@example.com'];
        expect(expectedDoc, isNotNull);
        expect(expectedDoc!['invitationId'], equals('partner@example.com'));
        expect(expectedDoc['senderUid'], equals('user_123'));
        expect(expectedDoc['senderEmail'], equals('user@example.com'));
        expect(expectedDoc['chartId'], equals(chartId));
        expect(expectedDoc['status'], equals('pending'));
        expect(expectedDoc['createdAt'], isNotNull);
      },
    );

    test(
      'invitePartner: throws exception when active session or chart is missing',
      () async {
        service.cachedChartId = null;
        expect(
          () => service.invitePartner('partner@example.com'),
          throwsA(isA<Exception>()),
        );

        service.cachedChartId = chartId;
        fakeAuth.currentUser = null;
        expect(
          () => service.invitePartner('partner@example.com'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'getPendingInvitations: queries pending invites matching user email',
      () async {
        fakeDb.store['invitations/user@example.com'] = {
          'invitationId': 'user@example.com',
          'senderUid': 'other_uid',
          'chartId': 'other_chart',
          'status': 'pending',
        };
        fakeDb.store['invitations/someone_else@example.com'] = {
          'invitationId': 'someone_else@example.com',
          'senderUid': 'other_uid',
          'chartId': 'other_chart',
          'status': 'pending',
        };
        fakeDb.store['invitations/declined@example.com'] = {
          'invitationId': 'user@example.com',
          'senderUid': 'other_uid',
          'chartId': 'declined_chart',
          'status': 'declined',
        };

        final pending = await service.getPendingInvitations();
        expect(pending.length, equals(1));
        expect(pending.first['chartId'], equals('other_chart'));
        expect(pending.first['status'], equals('pending'));
      },
    );

    test(
      'getPendingInvitations: returns empty list if user is null or email is null',
      () async {
        fakeAuth.currentUser = null;
        expect(await service.getPendingInvitations(), isEmpty);

        fakeAuth.currentUser = FakeUser(uid: 'no_email');
        expect(await service.getPendingInvitations(), isEmpty);
      },
    );

    test(
      'acceptInvitation: updates status, appends user to chart userIds, updates profile, and emits auth',
      () async {
        const inviteeEmail = 'user@example.com';
        const targetChartId = 'invited_chart_789';

        fakeDb.store['charts/$targetChartId'] = {
          'id': targetChartId,
          'userIds': ['original_owner'],
          'emails': ['owner@example.com'],
        };
        fakeDb.store['invitations/$inviteeEmail'] = {
          'invitationId': inviteeEmail,
          'chartId': targetChartId,
          'status': 'pending',
        };

        final authStream = service.authStateChanges;
        final emittedUsers = <User?>[];
        final sub = authStream.listen(emittedUsers.add);
        addTearDown(sub.cancel);

        await service.acceptInvitation(inviteeEmail);

        // Invitation status updated
        expect(
          fakeDb.store['invitations/$inviteeEmail']!['status'],
          equals('accepted'),
        );

        // Chart collaborators updated
        final chartData = fakeDb.store['charts/$targetChartId']!;
        expect(
          chartData['userIds'],
          containsAll(['original_owner', 'user_123']),
        );
        expect(
          chartData['emails'],
          containsAll(['owner@example.com', 'user@example.com']),
        );

        // User profile linked
        final userData = fakeDb.store['users/user_123']!;
        expect(userData['chartId'], equals(targetChartId));

        // Cached chartId updated
        expect(service.currentChartId, equals(targetChartId));
        await pumpEventQueue();
        expect(emittedUsers.isNotEmpty, isTrue);
      },
    );

    test(
      'acceptInvitation: throws exception when invitation is not found',
      () async {
        expect(
          () => service.acceptInvitation('non_existent@example.com'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'declineInvitation: updates status to declined and does not modify chart',
      () async {
        const inviteeEmail = 'user@example.com';
        const targetChartId = 'invited_chart_789';

        fakeDb.store['charts/$targetChartId'] = {
          'id': targetChartId,
          'userIds': ['original_owner'],
        };
        fakeDb.store['invitations/$inviteeEmail'] = {
          'invitationId': inviteeEmail,
          'chartId': targetChartId,
          'status': 'pending',
        };

        await service.declineInvitation(inviteeEmail);

        expect(
          fakeDb.store['invitations/$inviteeEmail']!['status'],
          equals('declined'),
        );
        final chartData = fakeDb.store['charts/$targetChartId']!;
        expect(chartData['userIds'], equals(['original_owner']));
        expect(fakeDb.store['users/user_123'], isNull);
      },
    );

    test(
      'declineInvitation: returns gracefully when invitation does not exist',
      () async {
        // Should not throw
        await service.declineInvitation('unknown@example.com');
      },
    );
  });

  // ===========================================================================
  // Group 2: Chart CRUD and Membership Management
  // ===========================================================================
  group('Group 2: Chart CRUD & Membership Management', () {
    test(
      'createChart: creates chart doc with default reminderEnabled and links user without preset supplements',
      () async {
        fakeDb.store['users/user_123'] = {
          'uid': 'user_123',
          'email': 'user@example.com',
          'timezone': 'America/New_York',
        };

        await service.createChart();

        final createdChartId = service.currentChartId;
        expect(createdChartId, isNotNull);

        final chartData = fakeDb.store['charts/$createdChartId'];
        expect(chartData, isNotNull);
        expect(chartData!['id'], equals(createdChartId));
        expect(chartData['userIds'], equals(['user_123']));
        expect(chartData['emails'], equals(['user@example.com']));
        expect(chartData['reminderEnabled'], isTrue);
        expect(chartData['timezone'], equals('America/New_York'));

        // No preset supplements seeded
        final suppKeys = fakeDb.store.keys.where(
          (k) => k.startsWith('charts/$createdChartId/supplements/'),
        );
        expect(suppKeys, isEmpty);

        // User document updated
        final userDoc = fakeDb.store['users/user_123'];
        expect(userDoc!['chartId'], equals(createdChartId));
      },
    );

    test(
      'unlinkChart: unlinks chart from user doc and emits null currentChartId',
      () async {
        service.cachedChartId = 'active_chart_1';
        fakeDb.store['users/user_123'] = {'chartId': 'active_chart_1'};

        await service.unlinkChart();

        expect(service.currentChartId, isNull);
        expect(fakeDb.store['users/user_123']!['chartId'], isNull);
      },
    );

    test(
      'setActiveChart: sets active chart in user doc and emits update',
      () async {
        fakeDb.store['users/user_123'] = {'chartId': null};

        await service.setActiveChart('target_chart_456');

        expect(service.currentChartId, equals('target_chart_456'));
        expect(
          fakeDb.store['users/user_123']!['chartId'],
          equals('target_chart_456'),
        );
      },
    );

    test(
      'leaveChart: throws exception when user is sole collaborator',
      () async {
        const chartId = 'solo_chart';
        service.cachedChartId = chartId;
        fakeDb.store['charts/$chartId'] = {
          'id': chartId,
          'userIds': ['user_123'],
          'emails': ['user@example.com'],
        };

        expect(() => service.leaveChart(chartId), throwsA(isA<Exception>()));
      },
    );

    test(
      'leaveChart: removes collaborator and unlinks if active chart',
      () async {
        const chartId = 'shared_chart';
        service.cachedChartId = chartId;
        fakeDb.store['charts/$chartId'] = {
          'id': chartId,
          'userIds': ['user_123', 'partner_456'],
          'emails': ['user@example.com', 'partner@example.com'],
        };
        fakeDb.store['users/user_123'] = {'chartId': chartId};

        await service.leaveChart(chartId);

        final chartData = fakeDb.store['charts/$chartId']!;
        expect(chartData['userIds'], equals(['partner_456']));
        expect(chartData['emails'], equals(['partner@example.com']));
        expect(service.currentChartId, isNull);
        expect(fakeDb.store['users/user_123']!['chartId'], isNull);
      },
    );

    test('deleteChart: deletes chart doc and all subcollections', () async {
      const chartId = 'chart_to_delete';
      service.cachedChartId = chartId;

      fakeDb.store['charts/$chartId'] = {'id': chartId};
      fakeDb.store['charts/$chartId/cycles/2026-09-01'] = {'id': '2026-09-01'};
      fakeDb.store['charts/$chartId/cycles/2026-09-01/dailyEntries/2026-09-01'] =
          {'date': '2026-09-01'};
      fakeDb.store['charts/$chartId/supplements/supp_1'] = {'id': 'supp_1'};
      fakeDb.store['charts/$chartId/supplementLogs/2026-09-01'] = {
        'date': '2026-09-01',
      };
      fakeDb.store['users/user_123'] = {'chartId': chartId};

      await service.deleteChart(chartId);

      expect(fakeDb.store['charts/$chartId'], isNull);
      expect(fakeDb.store['charts/$chartId/cycles/2026-09-01'], isNull);
      expect(
        fakeDb
            .store['charts/$chartId/cycles/2026-09-01/dailyEntries/2026-09-01'],
        isNull,
      );
      expect(fakeDb.store['charts/$chartId/supplements/supp_1'], isNull);
      expect(fakeDb.store['charts/$chartId/supplementLogs/2026-09-01'], isNull);
      expect(service.currentChartId, isNull);
      expect(fakeDb.store['users/user_123']!['chartId'], isNull);
    });

    test(
      'streamAvailableCharts: streams charts where userIds contains user',
      () async {
        fakeDb.store['charts/c1'] = {
          'id': 'c1',
          'userIds': ['user_123'],
        };
        fakeDb.store['charts/c2'] = {
          'id': 'c2',
          'userIds': ['other_user'],
        };
        fakeDb.store['charts/c3'] = {
          'id': 'c3',
          'userIds': ['user_123', 'other_user'],
        };

        final charts = await service.streamAvailableCharts().first;
        expect(charts.length, equals(2));
        final ids = charts.map((c) => c['id']).toList();
        expect(ids, containsAll(['c1', 'c3']));
      },
    );
  });

  // ===========================================================================
  // Group 6: Notification Settings & Profile State
  // ===========================================================================
  group('Group 6: Notification Settings & Profile State', () {
    const chartId = 'prefs_chart_1';

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {
        'id': chartId,
        'reminderEnabled': true,
      };
      fakeDb.store['users/user_123'] = {'uid': 'user_123', 'role': 'wife'};
    });

    test(
      'updateChartReminderSettings and streamChartReminderEnabled',
      () async {
        await service.updateChartReminderSettings(chartId, false);

        final chartDoc = fakeDb.store['charts/$chartId'];
        expect(chartDoc!['reminderEnabled'], isFalse);

        final isEnabled = await service
            .streamChartReminderEnabled(chartId)
            .first;
        expect(isEnabled, isFalse);
      },
    );

    test(
      'updateNotificationPreferences and streamNotificationPreferences',
      () async {
        const prefs = NotificationPreferences(
          dailyLoggingReminder: false,
          fertilePatternAlerts: true,
          partnerSupportReminders: false,
          breastSelfExamReminder: true,
        );

        await service.updateNotificationPreferences(chartId, prefs);

        expect(
          service.getLatestNotificationPreferences(chartId),
          equals(prefs),
        );
        expect(service.latestNotificationPreferences, equals(prefs));

        final streamed = await service
            .streamNotificationPreferences(chartId)
            .first;
        expect(streamed.fertilePatternAlerts, isTrue);
        expect(streamed.dailyLoggingReminder, isFalse);
        expect(streamed.partnerSupportReminders, isFalse);
        expect(streamed.breastSelfExamReminder, isTrue);
      },
    );

    test('updateUserRole and streamUserRole', () async {
      await service.updateUserRole('husband');

      expect(service.cachedRole, equals('husband'));
      final userDoc = fakeDb.store['users/user_123'];
      expect(userDoc!['role'], equals('husband'));

      final role = await service.streamUserRole().first;
      expect(role, equals('husband'));
    });

    test(
      'saveFcmToken and removeFcmToken: performs arrayUnion and arrayRemove',
      () async {
        await service.saveFcmToken('token_1');
        await service.saveFcmToken('token_2');

        final userDocAfterAdd = fakeDb.store['users/user_123']!;
        expect(
          userDocAfterAdd['fcmTokens'],
          containsAll(['token_1', 'token_2']),
        );

        await service.removeFcmToken('token_1');

        final userDocAfterRemove = fakeDb.store['users/user_123']!;
        expect(userDocAfterRemove['fcmTokens'], equals(['token_2']));
      },
    );

    test(
      'updateUserTimezone: updates timezone in users and active chart',
      () async {
        await service.updateUserTimezone('America/Chicago');

        expect(
          fakeDb.store['users/user_123']!['timezone'],
          equals('America/Chicago'),
        );
        expect(
          fakeDb.store['charts/$chartId']!['timezone'],
          equals('America/Chicago'),
        );
      },
    );

    group('Deleted chart and access loss handling (Issue #266)', () {
      const testChartId = 'chart_deleted_test';
      const partnerUid = 'partner_456';

      test(
        '_fetchChartId returns null and resets users/{uid}.chartId when chart document does not exist',
        () async {
          fakeDb.store['users/$partnerUid'] = {'chartId': testChartId};
          // charts/chart_deleted_test does not exist in store

          final result = await service.fetchChartId(partnerUid);

          expect(result, isNull);
          expect(fakeDb.store['users/$partnerUid']?['chartId'], isNull);
        },
      );

      test(
        '_fetchChartId returns null and resets users/{uid}.chartId when uid is absent from userIds',
        () async {
          fakeDb.store['users/$partnerUid'] = {'chartId': testChartId};
          fakeDb.store['charts/$testChartId'] = {
            'userIds': ['other_user_789'],
          };

          final result = await service.fetchChartId(partnerUid);

          expect(result, isNull);
          expect(fakeDb.store['users/$partnerUid']?['chartId'], isNull);
        },
      );

      test(
        '_fetchChartId returns chartId when chart exists and uid is in userIds',
        () async {
          fakeDb.store['users/$partnerUid'] = {'chartId': testChartId};
          fakeDb.store['charts/$testChartId'] = {
            'userIds': ['other_user_789', partnerUid],
          };

          final result = await service.fetchChartId(partnerUid);

          expect(result, equals(testChartId));
          expect(
            fakeDb.store['users/$partnerUid']?['chartId'],
            equals(testChartId),
          );
        },
      );

      test(
        '_fetchChartId returns null and resets Firestore when fetching chart throws permission-denied',
        () async {
          fakeDb.store['users/$partnerUid'] = {'chartId': testChartId};
          fakeDb.getDocErrors['charts/$testChartId'] = FirebaseException(
            plugin: 'firestore',
            code: 'permission-denied',
            message: 'Permission denied for deleted chart',
          );

          final result = await service.fetchChartId(partnerUid);

          expect(result, isNull);
          expect(fakeDb.store['users/$partnerUid']?['chartId'], isNull);
        },
      );

      test(
        '_fetchChartId preserves Firestore users/{uid}.chartId and returns chartId on transient errors',
        () async {
          fakeDb.store['users/$partnerUid'] = {'chartId': testChartId};
          fakeDb.getDocErrors['charts/$testChartId'] = FirebaseException(
            plugin: 'firestore',
            code: 'unavailable',
            message: 'Network connection unavailable',
          );

          final result = await service.fetchChartId(partnerUid);

          expect(result, equals(testChartId));
          expect(
            fakeDb.store['users/$partnerUid']?['chartId'],
            equals(testChartId),
          );
        },
      );

      test(
        '_handleChartAccessLost clears cached state, updates Firestore, and emits auth event',
        () async {
          service.cachedChartId = testChartId;
          fakeDb.store['users/user_123'] = {'chartId': testChartId};

          final authEmitted = <User?>[];
          final sub = service.authStateChanges.listen(authEmitted.add);
          addTearDown(sub.cancel);
          await pumpEventQueue();

          await service.handleChartAccessLost(testChartId);
          await pumpEventQueue();

          expect(service.currentChartId, isNull);
          expect(fakeDb.store['users/user_123']?['chartId'], isNull);
          expect(authEmitted, contains(currentUser));
        },
      );

      test(
        'streamChartReminderEnabled handles permission-denied gracefully, invalidates access, and emits fallback',
        () async {
          service.cachedChartId = testChartId;
          fakeDb.store['users/user_123'] = {'chartId': testChartId};
          fakeDb.snapshotErrors['charts/$testChartId'] = FirebaseException(
            plugin: 'firestore',
            code: 'permission-denied',
          );

          final emitted = <bool>[];
          final sub = service
              .streamChartReminderEnabled(testChartId)
              .listen(emitted.add);
          addTearDown(sub.cancel);
          await pumpEventQueue();

          // Should not throw an unhandled exception, should trigger access lost, and emit fallback true
          expect(service.currentChartId, isNull);
          expect(fakeDb.store['users/user_123']?['chartId'], isNull);
          expect(emitted, [isTrue]);

          // Consumers awaiting .first should not stall
          final firstVal = await service
              .streamChartReminderEnabled(testChartId)
              .first;
          expect(firstVal, isTrue);
        },
      );

      test(
        'streamNotificationPreferences handles permission-denied gracefully, invalidates access, and emits fallback',
        () async {
          service.cachedChartId = testChartId;
          fakeDb.store['users/user_123'] = {'chartId': testChartId};
          fakeDb.snapshotErrors['charts/$testChartId'] = FirebaseException(
            plugin: 'firestore',
            code: 'permission-denied',
          );

          final emitted = <NotificationPreferences>[];
          final sub = service
              .streamNotificationPreferences(testChartId)
              .listen(emitted.add);
          addTearDown(sub.cancel);
          await pumpEventQueue();

          // Should not throw an unhandled exception, should trigger access lost, and emit fallback const NotificationPreferences()
          expect(service.currentChartId, isNull);
          expect(fakeDb.store['users/user_123']?['chartId'], isNull);
          expect(emitted, [equals(const NotificationPreferences())]);

          // Consumers awaiting .first should not stall
          final firstVal = await service
              .streamNotificationPreferences(testChartId)
              .first;
          expect(firstVal, equals(const NotificationPreferences()));
        },
      );

      test(
        'streamCycles handles permission-denied in gated stream by clearing cached chart and resetting profile',
        () async {
          service.cachedChartId = testChartId;
          fakeDb.store['users/user_123'] = {'chartId': testChartId};

          final stream =
              FirebaseDatabaseService.buildAuthGatedStreamHelper<List<String>>(
                getCurrentChartId: () => service.currentChartId,
                authStateChanges: service.authStateChanges,
                emptyValue: const [],
                subscribe: (chartId) {
                  return Stream.error(
                    FirebaseException(
                      plugin: 'firestore',
                      code: 'permission-denied',
                    ),
                  );
                },
                onAccessLost: service.handleChartAccessLost,
              );

          final emitted = <List<String>>[];
          final sub = stream.listen(emitted.add);
          addTearDown(sub.cancel);
          await pumpEventQueue();

          expect(emitted, [isEmpty]);
          expect(service.currentChartId, isNull);
          expect(fakeDb.store['users/user_123']?['chartId'], isNull);
        },
      );
    });
  });
}
