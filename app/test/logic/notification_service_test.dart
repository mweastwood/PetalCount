import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  late InMemoryNotificationService notificationService;

  setUp(() {
    notificationService = InMemoryNotificationService();
  });

  group('NotificationService - calculateNextReminderTime', () {
    test(
      'schedules for today at 9:00 PM when not logged and before 9:00 PM',
      () {
        final now = DateTime(2026, 8, 17, 14, 30); // 2:30 PM
        final nextTime = notificationService.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );

        expect(nextTime, DateTime(2026, 8, 17, 21, 0));
      },
    );

    test(
      'schedules for tomorrow at 9:00 PM when not logged and past 9:00 PM',
      () {
        final now = DateTime(2026, 8, 17, 21, 15); // 9:15 PM
        final nextTime = notificationService.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );

        expect(nextTime, DateTime(2026, 8, 18, 21, 0));
      },
    );

    test(
      'schedules for tomorrow at 9:00 PM when today is already logged (before 9 PM)',
      () {
        final now = DateTime(2026, 8, 17, 10, 0); // 10:00 AM
        final nextTime = notificationService.calculateNextReminderTime(
          now: now,
          isTodayLogged: true,
        );

        expect(nextTime, DateTime(2026, 8, 18, 21, 0));
      },
    );

    test(
      'schedules for tomorrow at 9:00 PM when today is already logged (after 9 PM)',
      () {
        final now = DateTime(2026, 8, 17, 22, 0); // 10:00 PM
        final nextTime = notificationService.calculateNextReminderTime(
          now: now,
          isTodayLogged: true,
        );

        expect(nextTime, DateTime(2026, 8, 18, 21, 0));
      },
    );

    test('handles month rollover cleanly', () {
      final now = DateTime(2026, 8, 31, 21, 30); // Aug 31, 9:30 PM
      final nextTime = notificationService.calculateNextReminderTime(
        now: now,
        isTodayLogged: false,
      );

      expect(nextTime, DateTime(2026, 9, 1, 21, 0));
    });

    test('handles year rollover cleanly', () {
      final now = DateTime(2026, 12, 31, 22, 0); // Dec 31, 10:00 PM
      final nextTime = notificationService.calculateNextReminderTime(
        now: now,
        isTodayLogged: false,
      );

      expect(nextTime, DateTime(2027, 1, 1, 21, 0));
    });
  });

  group('NotificationService - syncReminderSchedule', () {
    test('cancels reminder if chartId is null', () async {
      await notificationService.scheduleDailyReminder(
        triggerTime: DateTime(2026, 8, 17, 21, 0),
      );
      expect(notificationService.isReminderScheduled, isTrue);

      await notificationService.syncReminderSchedule(
        chartId: null,
        reminderEnabled: true,
        isTodayLogged: false,
      );

      expect(notificationService.isReminderScheduled, isFalse);
      expect(notificationService.scheduledReminderTime, isNull);
      expect(notificationService.cancelCount, 1);
    });

    test('cancels reminder if reminderEnabled is false', () async {
      await notificationService.scheduleDailyReminder(
        triggerTime: DateTime(2026, 8, 17, 21, 0),
      );
      expect(notificationService.isReminderScheduled, isTrue);

      await notificationService.syncReminderSchedule(
        chartId: 'chart_123',
        reminderEnabled: false,
        isTodayLogged: false,
      );

      expect(notificationService.isReminderScheduled, isFalse);
      expect(notificationService.scheduledReminderTime, isNull);
      expect(notificationService.cancelCount, 1);
    });

    test(
      'schedules today 9 PM reminder when enabled and not logged today',
      () async {
        final now = DateTime(2026, 8, 17, 13, 0);
        await notificationService.syncReminderSchedule(
          chartId: 'chart_123',
          reminderEnabled: true,
          isTodayLogged: false,
          now: now,
        );

        expect(notificationService.isReminderScheduled, isTrue);
        expect(
          notificationService.scheduledReminderTime,
          DateTime(2026, 8, 17, 21, 0),
        );
        expect(notificationService.scheduleCount, 1);
      },
    );

    test(
      'schedules tomorrow 9 PM reminder when enabled and already logged today',
      () async {
        final now = DateTime(2026, 8, 17, 13, 0);
        await notificationService.syncReminderSchedule(
          chartId: 'chart_123',
          reminderEnabled: true,
          isTodayLogged: true,
          now: now,
        );

        expect(notificationService.isReminderScheduled, isTrue);
        expect(
          notificationService.scheduledReminderTime,
          DateTime(2026, 8, 18, 21, 0),
        );
        expect(notificationService.scheduleCount, 1);
      },
    );

    test('setupFcmPushNotifications and getFcmToken succeed', () async {
      expect(notificationService.setupFcmCalled, isFalse);
      await notificationService.setupFcmPushNotifications();
      expect(notificationService.setupFcmCalled, isTrue);

      final token = await notificationService.getFcmToken();
      expect(token, 'mock_fcm_token_123');
    });
  });
}
