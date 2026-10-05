import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  late InMemoryNotificationService service;

  setUp(() {
    service = InMemoryNotificationService();
  });

  group('InMemoryNotificationService - Lifecycle & Service Configuration', () {
    test('init sets isInitialized to true and is idempotent', () async {
      expect(service.isInitialized, isFalse);

      await service.init();
      expect(service.isInitialized, isTrue);

      // Subsequent init calls should not throw and keep isInitialized true
      await service.init();
      expect(service.isInitialized, isTrue);
    });

    test('requestPermissions returns permissionGranted state', () async {
      expect(service.permissionGranted, isTrue);
      expect(await service.requestPermissions(), isTrue);

      service.permissionGranted = false;
      expect(await service.requestPermissions(), isFalse);
    });

    test('setupFcmPushNotifications sets setupFcmCalled to true', () async {
      expect(service.setupFcmCalled, isFalse);
      await service.setupFcmPushNotifications();
      expect(service.setupFcmCalled, isTrue);
    });

    test('getFcmToken returns mockFcmToken and reflects changes', () async {
      expect(await service.getFcmToken(), 'mock_fcm_token_123');

      service.mockFcmToken = 'custom_test_fcm_token';
      expect(await service.getFcmToken(), 'custom_test_fcm_token');

      service.mockFcmToken = null;
      expect(await service.getFcmToken(), isNull);
    });
  });

  group('InMemoryNotificationService - calculateNextReminderTime', () {
    group('Same-Day Scheduling (isTodayLogged: false)', () {
      test('schedules for today at 21:00 when before 21:00', () {
        final now = DateTime(2026, 8, 17, 14, 30);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 8, 17, 21, 0, 0));
      });

      test('schedules for tomorrow at 21:00 when at exactly 21:00:00', () {
        final now = DateTime(2026, 8, 17, 21, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0, 0));
      });

      test('schedules for tomorrow at 21:00 when after 21:00 (21:15)', () {
        final now = DateTime(2026, 8, 17, 21, 15, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0, 0));
      });

      test('schedules for tomorrow at 21:00 when after 21:00 (23:30)', () {
        final now = DateTime(2026, 8, 17, 23, 30, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0, 0));
      });

      test('schedules for tomorrow at 21:00 when at 23:59:59', () {
        final now = DateTime(2026, 8, 17, 23, 59, 59);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0, 0));
      });
    });

    group('Next-Day Scheduling (isTodayLogged: true)', () {
      test('schedules for tomorrow at 21:00 when before 21:00', () {
        final now = DateTime(2026, 8, 17, 10, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: true,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0, 0));
      });

      test('schedules for tomorrow at 21:00 when at exactly 21:00:00', () {
        final now = DateTime(2026, 8, 17, 21, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: true,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0, 0));
      });

      test('schedules for tomorrow at 21:00 when after 21:00', () {
        final now = DateTime(2026, 8, 17, 22, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: true,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0, 0));
      });
    });

    group('Rollover & Transition Boundary Cases', () {
      test('schedules for today at 21:00 at midnight boundaries (00:00:00 and 00:00:01) when unlogged', () {
        final midnight = DateTime(2026, 8, 17, 0, 0, 0);
        final nextMidnight = service.calculateNextReminderTime(
          now: midnight,
          isTodayLogged: false,
        );
        expect(nextMidnight, DateTime(2026, 8, 17, 21, 0, 0));

        final justAfterMidnight = DateTime(2026, 8, 17, 0, 0, 1);
        final nextJustAfterMidnight = service.calculateNextReminderTime(
          now: justAfterMidnight,
          isTodayLogged: false,
        );
        expect(nextJustAfterMidnight, DateTime(2026, 8, 17, 21, 0, 0));
      });

      test('rolls over correctly on 31-day month boundary (Aug 31 -> Sep 1)', () {
        final now = DateTime(2026, 8, 31, 21, 30, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 9, 1, 21, 0, 0));
      });

      test('rolls over correctly on 30-day month boundary (Apr 30 -> May 1)', () {
        final now = DateTime(2026, 4, 30, 22, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 5, 1, 21, 0, 0));
      });

      test('rolls over correctly on leap year boundary (Feb 28 -> Feb 29 on 2028)', () {
        final now = DateTime(2028, 2, 28, 22, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2028, 2, 29, 21, 0, 0));

        final leapDay = DateTime(2028, 2, 29, 22, 0, 0);
        final nextAfterLeapDay = service.calculateNextReminderTime(
          now: leapDay,
          isTodayLogged: false,
        );
        expect(nextAfterLeapDay, DateTime(2028, 3, 1, 21, 0, 0));
      });

      test('rolls over correctly on non-leap year boundary (Feb 28 -> Mar 1 on 2026)', () {
        final now = DateTime(2026, 2, 28, 22, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 3, 1, 21, 0, 0));
      });

      test('rolls over correctly across year end (Dec 31 -> Jan 1)', () {
        final now = DateTime(2026, 12, 31, 22, 0, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2027, 1, 1, 21, 0, 0));
      });

      test('handles DST autumn fall-back transition dates without scheduling backwards', () {
        // Nov 1, 2026 DST fall-back day at 23:30
        final now = DateTime(2026, 11, 1, 23, 30, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 11, 2, 21, 0, 0));
        expect(next.isAfter(now), isTrue);
        expect(next.year, 2026);
        expect(next.month, 11);
        expect(next.day, 2);
        expect(next.hour, 21);
      });

      test('handles DST spring-forward transition dates correctly', () {
        // Mar 8, 2026 DST spring-forward day at 23:30
        final now = DateTime(2026, 3, 8, 23, 30, 0);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 3, 9, 21, 0, 0));
        expect(next.isAfter(now), isTrue);
        expect(next.year, 2026);
        expect(next.month, 3);
        expect(next.day, 9);
        expect(next.hour, 21);
      });
    });
  });

  group('InMemoryNotificationService - Schedule Operations & Synchronization', () {
    test('scheduleDailyReminder records state and increments scheduleCount', () async {
      final triggerTime = DateTime(2026, 8, 17, 21, 0, 0);
      expect(service.isReminderScheduled, isFalse);
      expect(service.scheduledReminderTime, isNull);
      expect(service.scheduleCount, 0);

      await service.scheduleDailyReminder(
        triggerTime: triggerTime,
        role: UserRole.wife,
      );

      expect(service.isReminderScheduled, isTrue);
      expect(service.scheduledReminderTime, triggerTime);
      expect(service.scheduleCount, 1);

      // Can be scheduled for husband as well
      final triggerTimeHusband = DateTime(2026, 8, 18, 21, 0, 0);
      await service.scheduleDailyReminder(
        triggerTime: triggerTimeHusband,
        role: UserRole.husband,
      );

      expect(service.isReminderScheduled, isTrue);
      expect(service.scheduledReminderTime, triggerTimeHusband);
      expect(service.scheduleCount, 2);
    });

    test('cancelDailyReminder clears state and increments cancelCount', () async {
      await service.scheduleDailyReminder(
        triggerTime: DateTime(2026, 8, 17, 21, 0, 0),
      );
      expect(service.isReminderScheduled, isTrue);
      expect(service.cancelCount, 0);

      await service.cancelDailyReminder();

      expect(service.isReminderScheduled, isFalse);
      expect(service.scheduledReminderTime, isNull);
      expect(service.cancelCount, 1);

      // Canceling again increments count and preserves cleared state
      await service.cancelDailyReminder();
      expect(service.isReminderScheduled, isFalse);
      expect(service.scheduledReminderTime, isNull);
      expect(service.cancelCount, 2);
    });

    group('syncReminderSchedule', () {
      test('cancels reminder when chartId is null', () async {
        await service.scheduleDailyReminder(
          triggerTime: DateTime(2026, 8, 17, 21, 0, 0),
        );
        expect(service.isReminderScheduled, isTrue);

        await service.syncReminderSchedule(
          chartId: null,
          reminderEnabled: true,
          isTodayLogged: false,
        );

        expect(service.isReminderScheduled, isFalse);
        expect(service.scheduledReminderTime, isNull);
        expect(service.cancelCount, 1);
      });

      test('cancels reminder when reminderEnabled is false', () async {
        await service.scheduleDailyReminder(
          triggerTime: DateTime(2026, 8, 17, 21, 0, 0),
        );
        expect(service.isReminderScheduled, isTrue);

        await service.syncReminderSchedule(
          chartId: 'chart-123',
          reminderEnabled: false,
          isTodayLogged: false,
        );

        expect(service.isReminderScheduled, isFalse);
        expect(service.scheduledReminderTime, isNull);
        expect(service.cancelCount, 1);
      });

      test('schedules reminder when enabled and chartId provided with explicit now', () async {
        final fixedNow = DateTime(2026, 8, 17, 13, 0, 0);

        await service.syncReminderSchedule(
          chartId: 'chart-123',
          reminderEnabled: true,
          isTodayLogged: false,
          now: fixedNow,
          role: UserRole.wife,
        );

        expect(service.isReminderScheduled, isTrue);
        expect(service.scheduledReminderTime, DateTime(2026, 8, 17, 21, 0, 0));
        expect(service.scheduleCount, 1);

        // If today is logged, schedules tomorrow
        await service.syncReminderSchedule(
          chartId: 'chart-123',
          reminderEnabled: true,
          isTodayLogged: true,
          now: fixedNow,
          role: UserRole.husband,
        );

        expect(service.isReminderScheduled, isTrue);
        expect(service.scheduledReminderTime, DateTime(2026, 8, 18, 21, 0, 0));
        expect(service.scheduleCount, 2);
      });

      test('schedules reminder when now is omitted (uses DateTime.now())', () async {
        await service.syncReminderSchedule(
          chartId: 'chart-123',
          reminderEnabled: true,
          isTodayLogged: false,
        );

        expect(service.isReminderScheduled, isTrue);
        expect(service.scheduledReminderTime, isNotNull);
        expect(service.scheduledReminderTime!.hour, 21);
        expect(service.scheduledReminderTime!.minute, 0);
        expect(service.scheduleCount, 1);
      });

      test('idempotency: repeated sync calls with identical inputs update state predictably', () async {
        final fixedNow = DateTime(2026, 8, 17, 10, 0, 0);

        for (int i = 0; i < 3; i++) {
          await service.syncReminderSchedule(
            chartId: 'chart-123',
            reminderEnabled: true,
            isTodayLogged: false,
            now: fixedNow,
          );
          expect(service.isReminderScheduled, isTrue);
          expect(
            service.scheduledReminderTime,
            DateTime(2026, 8, 17, 21, 0, 0),
          );
        }

        expect(service.scheduleCount, 3);
        expect(service.cancelCount, 0);
      });
    });
  });

  group('InMemoryNotificationService - Notification Dispatch & Deduplication', () {
    test('showNotification increments notificationCount and records dispatch entry', () async {
      expect(service.notificationCount, 0);
      expect(service.dispatchedNotifications, isEmpty);

      await service.showNotification(
        id: 100,
        title: 'Test Notification',
        body: 'Test Body Message',
      );

      expect(service.notificationCount, 1);
      expect(service.dispatchedNotifications.length, 1);

      final entry = service.dispatchedNotifications.first;
      expect(entry['id'], 100);
      expect(entry['title'], 'Test Notification');
      expect(entry['body'], 'Test Body Message');
      expect(entry['timestamp'], isA<String>());
    });

    group('notifyFertilePattern', () {
      test('dispatches notification with ID 901 and expected content for wife and husband', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);
        final wifeExpected = CycleNotificationFormatter.fertilePatternMessage(UserRole.wife);

        await service.notifyFertilePattern(role: UserRole.wife, now: now);

        expect(service.notificationCount, 1);
        expect(service.dispatchedNotifications.first['id'], InMemoryNotificationService.fertilePatternNotificationId);
        expect(service.dispatchedNotifications.first['id'], 901);
        expect(service.dispatchedNotifications.first['title'], wifeExpected.title);
        expect(service.dispatchedNotifications.first['body'], wifeExpected.body);
        expect(service.sentNotificationDeduplicationKeys, contains('2026-08-17_fertile_wife'));

        final husbandExpected = CycleNotificationFormatter.fertilePatternMessage(UserRole.husband);
        await service.notifyFertilePattern(role: UserRole.husband, now: now);

        expect(service.notificationCount, 2);
        expect(service.dispatchedNotifications[1]['id'], 901);
        expect(service.dispatchedNotifications[1]['title'], husbandExpected.title);
        expect(service.dispatchedNotifications[1]['body'], husbandExpected.body);
        expect(service.sentNotificationDeduplicationKeys, contains('2026-08-17_fertile_husband'));
      });

      test('suppresses duplicate dispatch on same day for same role unless force is true', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);

        await service.notifyFertilePattern(role: UserRole.wife, now: now);
        expect(service.notificationCount, 1);

        // Duplicate dispatch attempt on same day suppressed
        await service.notifyFertilePattern(role: UserRole.wife, now: now);
        expect(service.notificationCount, 1);

        // Force flag allows duplicate dispatch
        await service.notifyFertilePattern(role: UserRole.wife, now: now, force: true);
        expect(service.notificationCount, 2);

        // Subsequent day allows new dispatch
        final nextDay = DateTime(2026, 8, 18, 10, 0, 0);
        await service.notifyFertilePattern(role: UserRole.wife, now: nextDay);
        expect(service.notificationCount, 3);
      });
    });

    group('notifyPeakDay', () {
      test('dispatches notification with ID 902 and correct deduplication formatting', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);
        final defaultExpected = CycleNotificationFormatter.peakDayMessage(UserRole.wife);

        await service.notifyPeakDay(role: UserRole.wife, now: now);

        expect(service.notificationCount, 1);
        expect(service.dispatchedNotifications.first['id'], InMemoryNotificationService.peakDayNotificationId);
        expect(service.dispatchedNotifications.first['id'], 902);
        expect(service.dispatchedNotifications.first['title'], defaultExpected.title);
        expect(service.dispatchedNotifications.first['body'], defaultExpected.body);
        expect(service.sentNotificationDeduplicationKeys, contains('2026-08-17_peak_P_wife'));
      });

      test('differentiates deduplication keys between custom labels (P vs P+1)', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);

        await service.notifyPeakDay(role: UserRole.wife, peakLabel: 'P', now: now);
        expect(service.notificationCount, 1);

        // Calling with same label is suppressed
        await service.notifyPeakDay(role: UserRole.wife, peakLabel: 'P', now: now);
        expect(service.notificationCount, 1);

        // Calling with different peak label (e.g. 'P+1') creates different dedupe key and dispatches
        final labelExpected = CycleNotificationFormatter.peakDayMessage(UserRole.wife, peakLabel: 'P+1');
        await service.notifyPeakDay(role: UserRole.wife, peakLabel: 'P+1', now: now);
        expect(service.notificationCount, 2);
        expect(service.dispatchedNotifications[1]['title'], labelExpected.title);
        expect(service.dispatchedNotifications[1]['body'], labelExpected.body);
        expect(service.sentNotificationDeduplicationKeys, contains('2026-08-17_peak_P+1_wife'));

        // Calling with force: true bypasses deduplication
        await service.notifyPeakDay(role: UserRole.wife, peakLabel: 'P+1', now: now, force: true);
        expect(service.notificationCount, 3);
      });

      test('formats peak day notification correctly for husband', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);
        final husbandExpected = CycleNotificationFormatter.peakDayMessage(
          UserRole.husband,
          peakLabel: 'P',
        );

        await service.notifyPeakDay(role: UserRole.husband, peakLabel: 'P', now: now);
        expect(service.notificationCount, 1);
        expect(service.dispatchedNotifications.first['title'], husbandExpected.title);
        expect(service.dispatchedNotifications.first['body'], husbandExpected.body);
      });
    });

    group('notifyKindnessSupport', () {
      test('dispatches notification with ID 903 and expected deduplication key', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);
        final wifeExpected = CycleNotificationFormatter.kindnessSupportMessage(UserRole.wife);

        await service.notifyKindnessSupport(role: UserRole.wife, now: now);

        expect(service.notificationCount, 1);
        expect(service.dispatchedNotifications.first['id'], InMemoryNotificationService.kindnessSupportNotificationId);
        expect(service.dispatchedNotifications.first['id'], 903);
        expect(service.dispatchedNotifications.first['title'], wifeExpected.title);
        expect(service.dispatchedNotifications.first['body'], wifeExpected.body);
        expect(service.sentNotificationDeduplicationKeys, contains('2026-08-17_kindness_wife'));
      });

      test('suppresses duplicates unless force is true and differentiates roles', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);

        await service.notifyKindnessSupport(role: UserRole.wife, now: now);
        expect(service.notificationCount, 1);

        // Suppressed duplicate
        await service.notifyKindnessSupport(role: UserRole.wife, now: now);
        expect(service.notificationCount, 1);

        // Force dispatch
        await service.notifyKindnessSupport(role: UserRole.wife, now: now, force: true);
        expect(service.notificationCount, 2);

        // Different role (husband) allowed on same day
        await service.notifyKindnessSupport(role: UserRole.husband, now: now);
        expect(service.notificationCount, 3);
        expect(service.sentNotificationDeduplicationKeys, contains('2026-08-17_kindness_husband'));
      });
    });

    group('notifyBreastSelfExam', () {
      test('dispatches notification with ID 904 and expected deduplication key', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);
        final wifeExpected = CycleNotificationFormatter.breastSelfExamMessage(UserRole.wife);

        await service.notifyBreastSelfExam(role: UserRole.wife, now: now);

        expect(service.notificationCount, 1);
        expect(service.dispatchedNotifications.first['id'], InMemoryNotificationService.breastSelfExamNotificationId);
        expect(service.dispatchedNotifications.first['id'], 904);
        expect(service.dispatchedNotifications.first['title'], wifeExpected.title);
        expect(service.dispatchedNotifications.first['body'], wifeExpected.body);
        expect(service.sentNotificationDeduplicationKeys, contains('2026-08-17_bse_wife'));
      });

      test('suppresses duplicates unless force is true', () async {
        final now = DateTime(2026, 8, 17, 10, 0, 0);

        await service.notifyBreastSelfExam(role: UserRole.wife, now: now);
        expect(service.notificationCount, 1);

        // Suppressed duplicate
        await service.notifyBreastSelfExam(role: UserRole.wife, now: now);
        expect(service.notificationCount, 1);

        // Force dispatch
        await service.notifyBreastSelfExam(role: UserRole.wife, now: now, force: true);
        expect(service.notificationCount, 2);
      });
    });
  });

  group('InMemoryNotificationService - Parity with LocalNotificationService', () {
    late LocalNotificationService localService;

    setUp(() {
      localService = LocalNotificationService();
    });

    final testCases = <Map<String, dynamic>>[
      {
        'description': 'unlogged morning (08:30)',
        'now': DateTime(2026, 8, 17, 8, 30),
        'isTodayLogged': false,
      },
      {
        'description': 'unlogged afternoon (14:30)',
        'now': DateTime(2026, 8, 17, 14, 30),
        'isTodayLogged': false,
      },
      {
        'description': 'unlogged at exactly 21:00:00',
        'now': DateTime(2026, 8, 17, 21, 0, 0),
        'isTodayLogged': false,
      },
      {
        'description': 'unlogged late night (21:15)',
        'now': DateTime(2026, 8, 17, 21, 15, 0),
        'isTodayLogged': false,
      },
      {
        'description': 'unlogged midnight edge (23:59:59)',
        'now': DateTime(2026, 8, 17, 23, 59, 59),
        'isTodayLogged': false,
      },
      {
        'description': 'already logged morning (10:00)',
        'now': DateTime(2026, 8, 17, 10, 0),
        'isTodayLogged': true,
      },
      {
        'description': 'already logged evening before 21:00 (20:45)',
        'now': DateTime(2026, 8, 17, 20, 45),
        'isTodayLogged': true,
      },
      {
        'description': 'already logged night after 21:00 (22:30)',
        'now': DateTime(2026, 8, 17, 22, 30),
        'isTodayLogged': true,
      },
      {
        'description': 'month boundary rollover (Aug 31 22:00)',
        'now': DateTime(2026, 8, 31, 22, 0),
        'isTodayLogged': false,
      },
      {
        'description': 'year boundary rollover (Dec 31 22:00)',
        'now': DateTime(2026, 12, 31, 22, 0),
        'isTodayLogged': false,
      },
      {
        'description': 'leap year boundary (Feb 28 2028 22:00)',
        'now': DateTime(2028, 2, 28, 22, 0),
        'isTodayLogged': false,
      },
      {
        'description': 'non-leap year boundary (Feb 28 2026 22:00)',
        'now': DateTime(2026, 2, 28, 22, 0),
        'isTodayLogged': false,
      },
      {
        'description': 'autumn DST transition (Nov 1 2026 23:30)',
        'now': DateTime(2026, 11, 1, 23, 30),
        'isTodayLogged': false,
      },
      {
        'description': 'spring DST transition (Mar 8 2026 23:30)',
        'now': DateTime(2026, 3, 8, 23, 30),
        'isTodayLogged': false,
      },
    ];

    for (final tc in testCases) {
      test('parity between InMemory and Local for ${tc['description']}', () {
        final now = tc['now'] as DateTime;
        final isTodayLogged = tc['isTodayLogged'] as bool;

        final inMemoryResult = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: isTodayLogged,
        );
        final localResult = localService.calculateNextReminderTime(
          now: now,
          isTodayLogged: isTodayLogged,
        );

        expect(
          inMemoryResult,
          equals(localResult),
          reason: 'Mismatch between InMemory and Local notification service calculation',
        );
      });
    }
  });
}
