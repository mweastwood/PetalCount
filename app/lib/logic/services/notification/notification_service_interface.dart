import '../../models/user_role.dart';

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermissions();
  DateTime calculateNextReminderTime({
    required DateTime now,
    required bool isTodayLogged,
  });
  Future<void> scheduleDailyReminder({
    required DateTime triggerTime,
    UserRole role = UserRole.wife,
  });
  Future<void> cancelDailyReminder();
  Future<void> syncReminderSchedule({
    required String? chartId,
    required bool reminderEnabled,
    required bool isTodayLogged,
    DateTime? now,
    UserRole role = UserRole.wife,
  });
  Future<void> setupFcmPushNotifications();
  Future<String?> getFcmToken();
  bool get isReminderScheduled;
  DateTime? get scheduledReminderTime;

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  });

  Future<void> notifyFertilePattern({
    required UserRole role,
    DateTime? now,
    bool force = false,
  });

  Future<void> notifyPeakDay({
    required UserRole role,
    String? peakLabel,
    DateTime? now,
    bool force = false,
  });

  Future<void> notifyKindnessSupport({
    required UserRole role,
    DateTime? now,
    bool force = false,
  });
}
