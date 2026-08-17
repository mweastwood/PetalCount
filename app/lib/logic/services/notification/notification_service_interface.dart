abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermissions();
  DateTime calculateNextReminderTime({
    required DateTime now,
    required bool isTodayLogged,
  });
  Future<void> scheduleDailyReminder({required DateTime triggerTime});
  Future<void> cancelDailyReminder();
  Future<void> syncReminderSchedule({
    required String? chartId,
    required bool reminderEnabled,
    required bool isTodayLogged,
    DateTime? now,
  });
  bool get isReminderScheduled;
  DateTime? get scheduledReminderTime;
}
