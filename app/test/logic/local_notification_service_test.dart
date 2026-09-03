import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ScheduledNotificationRecord {
  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails notificationDetails;
  final AndroidScheduleMode androidScheduleMode;

  ScheduledNotificationRecord({
    required this.id,
    this.title,
    this.body,
    required this.scheduledDate,
    required this.notificationDetails,
    required this.androidScheduleMode,
  });
}

class ShownNotificationRecord {
  final int id;
  final String? title;
  final String? body;
  final NotificationDetails? notificationDetails;

  ShownNotificationRecord({
    required this.id,
    this.title,
    this.body,
    this.notificationDetails,
  });
}

class FakeAndroidFlutterLocalNotificationsPlugin extends Fake
    implements AndroidFlutterLocalNotificationsPlugin {
  bool? permissionResult = true;
  bool requestCalled = false;

  @override
  Future<bool?> requestNotificationsPermission() async {
    requestCalled = true;
    return permissionResult;
  }
}

class FakeIOSFlutterLocalNotificationsPlugin extends Fake
    implements IOSFlutterLocalNotificationsPlugin {
  bool? permissionResult = true;
  bool requestCalled = false;

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requestCalled = true;
    return permissionResult;
  }
}

class FakeMacOSFlutterLocalNotificationsPlugin extends Fake
    implements MacOSFlutterLocalNotificationsPlugin {
  bool? permissionResult = true;
  bool requestCalled = false;

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requestCalled = true;
    return permissionResult;
  }
}

class FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  int initializeCallCount = 0;
  InitializationSettings? lastInitSettings;
  bool throwOnInitialize = false;
  bool throwOnZonedSchedule = false;
  bool throwOnCancel = false;
  bool throwOnShow = false;

  FakeAndroidFlutterLocalNotificationsPlugin? androidImplementation;
  FakeIOSFlutterLocalNotificationsPlugin? iosImplementation;
  FakeMacOSFlutterLocalNotificationsPlugin? macOSImplementation;

  final List<ScheduledNotificationRecord> scheduledNotifications = [];
  final List<int> cancelledNotificationIds = [];
  final List<ShownNotificationRecord> shownNotifications = [];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (throwOnInitialize) {
      throw Exception('Simulated initialize error');
    }
    initializeCallCount++;
    lastInitSettings = settings;
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return androidImplementation as T?;
    }
    if (T == IOSFlutterLocalNotificationsPlugin) {
      return iosImplementation as T?;
    }
    if (T == MacOSFlutterLocalNotificationsPlugin) {
      return macOSImplementation as T?;
    }
    return null;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    if (throwOnZonedSchedule) {
      throw Exception('Simulated zonedSchedule error');
    }
    scheduledNotifications.add(
      ScheduledNotificationRecord(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
      ),
    );
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    if (throwOnCancel) {
      throw Exception('Simulated cancel error');
    }
    cancelledNotificationIds.add(id);
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    if (throwOnShow) {
      throw Exception('Simulated show error');
    }
    shownNotifications.add(
      ShownNotificationRecord(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      ),
    );
  }
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  late FakeFlutterLocalNotificationsPlugin fakePlugin;
  late LocalNotificationService service;

  setUp(() {
    fakePlugin = FakeFlutterLocalNotificationsPlugin();
    service = LocalNotificationService(notificationsPlugin: fakePlugin);
  });

  group('LocalNotificationService - Channel & Constant Definitions', () {
    test('verifies static channel and notification constants', () {
      expect(LocalNotificationService.dailyReminderNotificationId, 900);
      expect(LocalNotificationService.fertilePatternNotificationId, 901);
      expect(LocalNotificationService.peakDayNotificationId, 902);
      expect(LocalNotificationService.kindnessSupportNotificationId, 903);
      expect(LocalNotificationService.breastSelfExamNotificationId, 904);

      expect(
        LocalNotificationService.notificationChannelId,
        'daily_logging_reminders',
      );
      expect(
        LocalNotificationService.notificationChannelName,
        'Daily Logging Reminders',
      );
      expect(
        LocalNotificationService.notificationChannelDescription,
        'Reminders to log daily Creighton observations by 9:00 PM',
      );

      expect(
        LocalNotificationService.cycleAlertChannelId,
        'cycle_pattern_alerts',
      );
      expect(
        LocalNotificationService.cycleAlertChannelName,
        'Cycle & Phase Alerts',
      );
      expect(
        LocalNotificationService.cycleAlertChannelDescription,
        'Notifications for fertile mucus patterns, peak day shifts, and partner support',
      );
    });
  });

  group('LocalNotificationService - Initialization (init)', () {
    test('initializes with platform-specific settings', () async {
      await service.init();

      expect(fakePlugin.initializeCallCount, 1);
      final initSettings = fakePlugin.lastInitSettings;
      expect(initSettings, isNotNull);
      expect(initSettings!.android, isNotNull);
      expect(initSettings.android!.defaultIcon, '@mipmap/ic_launcher');
      expect(initSettings.iOS, isNotNull);
      expect(initSettings.iOS!.requestAlertPermission, isFalse);
      expect(initSettings.iOS!.requestBadgePermission, isFalse);
      expect(initSettings.iOS!.requestSoundPermission, isFalse);
      expect(initSettings.macOS, isNotNull);
      expect(initSettings.macOS!.requestAlertPermission, isFalse);
      expect(initSettings.macOS!.requestBadgePermission, isFalse);
      expect(initSettings.macOS!.requestSoundPermission, isFalse);
    });

    test('init is idempotent and only initializes once', () async {
      await service.init();
      await service.init();
      await service.init();

      expect(fakePlugin.initializeCallCount, 1);
    });

    test(
      'handles plugin initialization errors gracefully without throwing',
      () async {
        fakePlugin.throwOnInitialize = true;

        // Should catch exception and mark initialized
        await expectLater(service.init(), completes);
        // Subsequent call should do nothing because initialized flag is true
        await service.init();
        expect(fakePlugin.initializeCallCount, 0);
      },
    );

    test('default constructor creates instance without throwing', () {
      final defaultService = LocalNotificationService();
      expect(defaultService.isReminderScheduled, isFalse);
      expect(defaultService.scheduledReminderTime, isNull);
    });
  });

  group('LocalNotificationService - Platform Implementations Resolution', () {
    test('resolves Android platform plugin implementation correctly', () {
      final fakeAndroid = FakeAndroidFlutterLocalNotificationsPlugin();
      fakePlugin.androidImplementation = fakeAndroid;

      final resolved = fakePlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      expect(resolved, same(fakeAndroid));
    });

    test('resolves iOS platform plugin implementation correctly', () {
      final fakeIos = FakeIOSFlutterLocalNotificationsPlugin();
      fakePlugin.iosImplementation = fakeIos;

      final resolved = fakePlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      expect(resolved, same(fakeIos));
    });

    test('resolves macOS platform plugin implementation correctly', () {
      final fakeMacOs = FakeMacOSFlutterLocalNotificationsPlugin();
      fakePlugin.macOSImplementation = fakeMacOs;

      final resolved = fakePlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      expect(resolved, same(fakeMacOs));
    });

    test(
      'requestPermissions returns false on non-mobile/desktop test runner or unconfigured platform',
      () async {
        final result = await service.requestPermissions();
        expect(result, isFalse);
      },
    );
  });

  group('LocalNotificationService - calculateNextReminderTime', () {
    test(
      'schedules for today at 9:00 PM when not logged and before 9:00 PM',
      () {
        final now = DateTime(2026, 8, 17, 14, 30);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 8, 17, 21, 0));
      },
    );

    test(
      'schedules for tomorrow at 9:00 PM when not logged and after 9:00 PM',
      () {
        final now = DateTime(2026, 8, 17, 21, 15);
        final next = service.calculateNextReminderTime(
          now: now,
          isTodayLogged: false,
        );
        expect(next, DateTime(2026, 8, 18, 21, 0));
      },
    );

    test('schedules for tomorrow at 9:00 PM when today is already logged', () {
      final now = DateTime(2026, 8, 17, 10, 0);
      final next = service.calculateNextReminderTime(
        now: now,
        isTodayLogged: true,
      );
      expect(next, DateTime(2026, 8, 18, 21, 0));
    });

    test('handles month rollover', () {
      final now = DateTime(2026, 8, 31, 22, 0);
      final next = service.calculateNextReminderTime(
        now: now,
        isTodayLogged: false,
      );
      expect(next, DateTime(2026, 9, 1, 21, 0));
    });

    test('handles year rollover', () {
      final now = DateTime(2026, 12, 31, 22, 0);
      final next = service.calculateNextReminderTime(
        now: now,
        isTodayLogged: false,
      );
      expect(next, DateTime(2027, 1, 1, 21, 0));
    });
  });

  group(
    'LocalNotificationService - Daily Reminder Scheduling & Cancellation',
    () {
      test(
        'schedules daily reminder for wife with exact channel and payload details',
        () async {
          final triggerTime = DateTime(2026, 8, 17, 21, 0);

          await service.scheduleDailyReminder(
            triggerTime: triggerTime,
            role: UserRole.wife,
          );

          expect(service.isReminderScheduled, isTrue);
          expect(service.scheduledReminderTime, triggerTime);
          expect(fakePlugin.scheduledNotifications.length, 1);

          final record = fakePlugin.scheduledNotifications.first;
          expect(
            record.id,
            LocalNotificationService.dailyReminderNotificationId,
          );
          expect(record.id, 900);
          expect(
            record.title,
            CycleNotificationFormatter.dailyLoggingReminder(
              UserRole.wife,
            ).title,
          );
          expect(
            record.body,
            CycleNotificationFormatter.dailyLoggingReminder(UserRole.wife).body,
          );
          expect(record.scheduledDate.year, 2026);
          expect(record.scheduledDate.month, 8);
          expect(record.scheduledDate.day, 17);
          expect(record.scheduledDate.hour, 21);
          expect(record.scheduledDate.minute, 0);
          expect(
            record.androidScheduleMode,
            AndroidScheduleMode.exactAllowWhileIdle,
          );

          final androidDetails = record.notificationDetails.android;
          expect(androidDetails, isNotNull);
          expect(
            androidDetails!.channelId,
            LocalNotificationService.notificationChannelId,
          );
          expect(
            androidDetails.channelName,
            LocalNotificationService.notificationChannelName,
          );
          expect(
            androidDetails.channelDescription,
            LocalNotificationService.notificationChannelDescription,
          );
          expect(androidDetails.importance, Importance.high);
          expect(androidDetails.priority, Priority.high);

          final iosDetails = record.notificationDetails.iOS;
          expect(iosDetails, isNotNull);
          expect(iosDetails!.presentAlert, isTrue);
          expect(iosDetails.presentBadge, isTrue);
          expect(iosDetails.presentSound, isTrue);
        },
      );

      test(
        'schedules daily reminder for husband with partner-specific message',
        () async {
          final triggerTime = DateTime(2026, 8, 17, 21, 0);

          await service.scheduleDailyReminder(
            triggerTime: triggerTime,
            role: UserRole.husband,
          );

          expect(service.isReminderScheduled, isTrue);
          expect(service.scheduledReminderTime, triggerTime);
          expect(fakePlugin.scheduledNotifications.length, 1);

          final record = fakePlugin.scheduledNotifications.first;
          expect(record.id, 900);
          expect(
            record.title,
            CycleNotificationFormatter.dailyLoggingReminder(
              UserRole.husband,
            ).title,
          );
          expect(
            record.body,
            CycleNotificationFormatter.dailyLoggingReminder(
              UserRole.husband,
            ).body,
          );
        },
      );

      test(
        'catches errors during zonedSchedule without unhandled exception',
        () async {
          fakePlugin.throwOnZonedSchedule = true;
          final triggerTime = DateTime(2026, 8, 17, 21, 0);

          await expectLater(
            service.scheduleDailyReminder(triggerTime: triggerTime),
            completes,
          );
          expect(service.isReminderScheduled, isTrue);
          expect(service.scheduledReminderTime, triggerTime);
        },
      );

      test('cancels daily reminder and resets scheduled state', () async {
        final triggerTime = DateTime(2026, 8, 17, 21, 0);
        await service.scheduleDailyReminder(triggerTime: triggerTime);
        expect(service.isReminderScheduled, isTrue);
        expect(service.scheduledReminderTime, triggerTime);

        await service.cancelDailyReminder();

        expect(service.isReminderScheduled, isFalse);
        expect(service.scheduledReminderTime, isNull);
        expect(
          fakePlugin.cancelledNotificationIds,
          contains(LocalNotificationService.dailyReminderNotificationId),
        );
      });

      test(
        'catches errors during cancelDailyReminder without unhandled exception',
        () async {
          fakePlugin.throwOnCancel = true;

          await expectLater(service.cancelDailyReminder(), completes);
          expect(service.isReminderScheduled, isFalse);
          expect(service.scheduledReminderTime, isNull);
        },
      );
    },
  );

  group(
    'LocalNotificationService - Reminder Schedule Sync (syncReminderSchedule)',
    () {
      test('cancels daily reminder when chartId is null', () async {
        final triggerTime = DateTime(2026, 8, 17, 21, 0);
        await service.scheduleDailyReminder(triggerTime: triggerTime);
        expect(service.isReminderScheduled, isTrue);

        await service.syncReminderSchedule(
          chartId: null,
          reminderEnabled: true,
          isTodayLogged: false,
        );

        expect(service.isReminderScheduled, isFalse);
        expect(service.scheduledReminderTime, isNull);
        expect(
          fakePlugin.cancelledNotificationIds,
          contains(LocalNotificationService.dailyReminderNotificationId),
        );
      });

      test('cancels daily reminder when reminderEnabled is false', () async {
        final triggerTime = DateTime(2026, 8, 17, 21, 0);
        await service.scheduleDailyReminder(triggerTime: triggerTime);
        expect(service.isReminderScheduled, isTrue);

        await service.syncReminderSchedule(
          chartId: 'chart_abc',
          reminderEnabled: false,
          isTodayLogged: false,
        );

        expect(service.isReminderScheduled, isFalse);
        expect(service.scheduledReminderTime, isNull);
        expect(
          fakePlugin.cancelledNotificationIds,
          contains(LocalNotificationService.dailyReminderNotificationId),
        );
      });

      test(
        'computes and schedules next reminder when enabled and not logged today',
        () async {
          final now = DateTime(2026, 8, 17, 15, 0);

          await service.syncReminderSchedule(
            chartId: 'chart_abc',
            reminderEnabled: true,
            isTodayLogged: false,
            now: now,
            role: UserRole.wife,
          );

          expect(service.isReminderScheduled, isTrue);
          expect(service.scheduledReminderTime, DateTime(2026, 8, 17, 21, 0));
          expect(fakePlugin.scheduledNotifications.length, 1);
        },
      );

      test(
        'computes and schedules next reminder for tomorrow when already logged today',
        () async {
          final now = DateTime(2026, 8, 17, 15, 0);

          await service.syncReminderSchedule(
            chartId: 'chart_abc',
            reminderEnabled: true,
            isTodayLogged: true,
            now: now,
            role: UserRole.husband,
          );

          expect(service.isReminderScheduled, isTrue);
          expect(service.scheduledReminderTime, DateTime(2026, 8, 18, 21, 0));
          expect(fakePlugin.scheduledNotifications.length, 1);
          expect(
            fakePlugin.scheduledNotifications.first.body,
            CycleNotificationFormatter.dailyLoggingReminder(
              UserRole.husband,
            ).body,
          );
        },
      );
    },
  );

  group('LocalNotificationService - Immediate & Cycle Phase Notifications', () {
    test(
      'showNotification dispatches alert on cycle_pattern_alerts channel',
      () async {
        await service.showNotification(
          id: 12345,
          title: 'Custom Alert Title',
          body: 'Custom Alert Body',
        );

        expect(fakePlugin.shownNotifications.length, 1);
        final record = fakePlugin.shownNotifications.first;
        expect(record.id, 12345);
        expect(record.title, 'Custom Alert Title');
        expect(record.body, 'Custom Alert Body');

        final android = record.notificationDetails?.android;
        expect(android, isNotNull);
        expect(
          android!.channelId,
          LocalNotificationService.cycleAlertChannelId,
        );
        expect(
          android.channelName,
          LocalNotificationService.cycleAlertChannelName,
        );
        expect(
          android.channelDescription,
          LocalNotificationService.cycleAlertChannelDescription,
        );
        expect(android.importance, Importance.high);
        expect(android.priority, Priority.high);

        final ios = record.notificationDetails?.iOS;
        expect(ios, isNotNull);
        expect(ios!.presentAlert, isTrue);
        expect(ios.presentBadge, isTrue);
        expect(ios.presentSound, isTrue);
      },
    );

    test('showNotification catches plugin errors gracefully', () async {
      fakePlugin.throwOnShow = true;

      await expectLater(
        service.showNotification(id: 1, title: 'T', body: 'B'),
        completes,
      );
    });

    test(
      'notifyFertilePattern dispatches notification 901 and deduplicates per day',
      () async {
        final now = DateTime(2026, 8, 20);

        // First dispatch for wife
        await service.notifyFertilePattern(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);
        expect(
          fakePlugin.shownNotifications.first.id,
          LocalNotificationService.fertilePatternNotificationId,
        );
        expect(
          fakePlugin.shownNotifications.first.title,
          CycleNotificationFormatter.fertilePatternMessage(UserRole.wife).title,
        );
        expect(
          fakePlugin.shownNotifications.first.body,
          CycleNotificationFormatter.fertilePatternMessage(UserRole.wife).body,
        );

        // Duplicate dispatch on same day should be skipped
        await service.notifyFertilePattern(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);

        // Force dispatch bypasses deduplication
        await service.notifyFertilePattern(
          role: UserRole.wife,
          now: now,
          force: true,
        );
        expect(fakePlugin.shownNotifications.length, 2);

        // Dispatch for husband has distinct deduplication key and message
        await service.notifyFertilePattern(role: UserRole.husband, now: now);
        expect(fakePlugin.shownNotifications.length, 3);
        expect(
          fakePlugin.shownNotifications.last.title,
          CycleNotificationFormatter.fertilePatternMessage(
            UserRole.husband,
          ).title,
        );
        expect(
          fakePlugin.shownNotifications.last.body,
          CycleNotificationFormatter.fertilePatternMessage(
            UserRole.husband,
          ).body,
        );
      },
    );

    test(
      'notifyPeakDay dispatches notification 902 with custom/fallback label and deduplicates',
      () async {
        final now = DateTime(2026, 8, 22);

        // Fallback label 'P' for wife
        await service.notifyPeakDay(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);
        expect(
          fakePlugin.shownNotifications.first.id,
          LocalNotificationService.peakDayNotificationId,
        );
        expect(
          fakePlugin.shownNotifications.first.title,
          CycleNotificationFormatter.peakDayMessage(UserRole.wife).title,
        );
        expect(
          fakePlugin.shownNotifications.first.body,
          CycleNotificationFormatter.peakDayMessage(UserRole.wife).body,
        );

        // Duplicate call with same label is deduplicated
        await service.notifyPeakDay(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);

        // Different label 'P+1' is not deduplicated
        await service.notifyPeakDay(
          role: UserRole.wife,
          peakLabel: 'P+1',
          now: now,
        );
        expect(fakePlugin.shownNotifications.length, 2);

        // Force flag bypasses deduplication
        await service.notifyPeakDay(
          role: UserRole.wife,
          peakLabel: 'P+1',
          now: now,
          force: true,
        );
        expect(fakePlugin.shownNotifications.length, 3);

        // Husband message
        await service.notifyPeakDay(
          role: UserRole.husband,
          peakLabel: 'P+2',
          now: now,
        );
        expect(fakePlugin.shownNotifications.length, 4);
        expect(
          fakePlugin.shownNotifications.last.title,
          CycleNotificationFormatter.peakDayMessage(
            UserRole.husband,
            peakLabel: 'P+2',
          ).title,
        );
        expect(
          fakePlugin.shownNotifications.last.body,
          CycleNotificationFormatter.peakDayMessage(
            UserRole.husband,
            peakLabel: 'P+2',
          ).body,
        );
      },
    );

    test(
      'notifyKindnessSupport dispatches notification 903 and deduplicates',
      () async {
        final now = DateTime(2026, 8, 23);

        // Wife kindness notification
        await service.notifyKindnessSupport(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);
        expect(
          fakePlugin.shownNotifications.first.id,
          LocalNotificationService.kindnessSupportNotificationId,
        );
        expect(
          fakePlugin.shownNotifications.first.title,
          CycleNotificationFormatter.kindnessSupportMessage(
            UserRole.wife,
          ).title,
        );
        expect(
          fakePlugin.shownNotifications.first.body,
          CycleNotificationFormatter.kindnessSupportMessage(UserRole.wife).body,
        );

        // Duplicate on same date
        await service.notifyKindnessSupport(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);

        // Force bypasses deduplication
        await service.notifyKindnessSupport(
          role: UserRole.wife,
          now: now,
          force: true,
        );
        expect(fakePlugin.shownNotifications.length, 2);

        // Husband kindness reminder
        await service.notifyKindnessSupport(role: UserRole.husband, now: now);
        expect(fakePlugin.shownNotifications.length, 3);
        expect(
          fakePlugin.shownNotifications.last.title,
          CycleNotificationFormatter.kindnessSupportMessage(
            UserRole.husband,
          ).title,
        );
        expect(
          fakePlugin.shownNotifications.last.body,
          CycleNotificationFormatter.kindnessSupportMessage(
            UserRole.husband,
          ).body,
        );
      },
    );

    test(
      'notifyBreastSelfExam dispatches notification 904 and deduplicates',
      () async {
        final now = DateTime(2026, 8, 24);

        // Wife BSE notification
        await service.notifyBreastSelfExam(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);
        expect(
          fakePlugin.shownNotifications.first.id,
          LocalNotificationService.breastSelfExamNotificationId,
        );
        expect(
          fakePlugin.shownNotifications.first.title,
          CycleNotificationFormatter.breastSelfExamMessage(UserRole.wife).title,
        );
        expect(
          fakePlugin.shownNotifications.first.body,
          CycleNotificationFormatter.breastSelfExamMessage(UserRole.wife).body,
        );

        // Duplicate on same date
        await service.notifyBreastSelfExam(role: UserRole.wife, now: now);
        expect(fakePlugin.shownNotifications.length, 1);

        // Force bypasses deduplication
        await service.notifyBreastSelfExam(
          role: UserRole.wife,
          now: now,
          force: true,
        );
        expect(fakePlugin.shownNotifications.length, 2);

        // Husband BSE notification
        await service.notifyBreastSelfExam(role: UserRole.husband, now: now);
        expect(fakePlugin.shownNotifications.length, 3);
        expect(
          fakePlugin.shownNotifications.last.title,
          CycleNotificationFormatter.breastSelfExamMessage(
            UserRole.husband,
          ).title,
        );
        expect(
          fakePlugin.shownNotifications.last.body,
          CycleNotificationFormatter.breastSelfExamMessage(
            UserRole.husband,
          ).body,
        );
      },
    );
  });

  group('LocalNotificationService - FCM Push Notifications & Tokens', () {
    test(
      'setupFcmPushNotifications safely completes when Firebase is uninitialized',
      () async {
        await expectLater(service.setupFcmPushNotifications(), completes);
      },
    );

    test(
      'getFcmToken returns null safely when Firebase is uninitialized',
      () async {
        final token = await service.getFcmToken();
        expect(token, isNull);
      },
    );
  });
}
