import '../../utils/date_utils.dart';
import 'notification_service_interface.dart';

class InMemoryNotificationService implements NotificationService {
  bool _isInitialized = false;
  bool _isReminderScheduled = false;
  DateTime? _scheduledReminderTime;
  bool permissionGranted = true;
  int cancelCount = 0;
  int scheduleCount = 0;

  @override
  bool get isReminderScheduled => _isReminderScheduled;

  @override
  DateTime? get scheduledReminderTime => _scheduledReminderTime;

  bool get isInitialized => _isInitialized;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    return permissionGranted;
  }

  @override
  DateTime calculateNextReminderTime({
    required DateTime now,
    required bool isTodayLogged,
  }) {
    final today9pm = DateTime(now.year, now.month, now.day, 21, 0, 0);
    if (isTodayLogged) {
      final tomorrow = now.addCalendarDays(1);
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 21, 0, 0);
    } else {
      if (now.isBefore(today9pm)) {
        return today9pm;
      } else {
        final tomorrow = now.addCalendarDays(1);
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 21, 0, 0);
      }
    }
  }

  @override
  Future<void> scheduleDailyReminder({required DateTime triggerTime}) async {
    scheduleCount++;
    _scheduledReminderTime = triggerTime;
    _isReminderScheduled = true;
  }

  @override
  Future<void> cancelDailyReminder() async {
    cancelCount++;
    _scheduledReminderTime = null;
    _isReminderScheduled = false;
  }

  @override
  Future<void> syncReminderSchedule({
    required String? chartId,
    required bool reminderEnabled,
    required bool isTodayLogged,
    DateTime? now,
  }) async {
    if (chartId == null || !reminderEnabled) {
      await cancelDailyReminder();
      return;
    }

    final effectiveNow = now ?? DateTime.now();
    final nextTime = calculateNextReminderTime(
      now: effectiveNow,
      isTodayLogged: isTodayLogged,
    );
    await scheduleDailyReminder(triggerTime: nextTime);
  }

  String? mockFcmToken = 'mock_fcm_token_123';
  bool setupFcmCalled = false;

  @override
  Future<void> setupFcmPushNotifications() async {
    setupFcmCalled = true;
  }

  @override
  Future<String?> getFcmToken() async {
    return mockFcmToken;
  }
}
