import '../../models/user_role.dart';
import '../../utils/date_utils.dart';
import 'cycle_notification_formatter.dart';
import 'notification_service_interface.dart';

class InMemoryNotificationService implements NotificationService {
  static const int dailyReminderNotificationId = 900;
  static const int fertilePatternNotificationId = 901;
  static const int peakDayNotificationId = 902;
  static const int kindnessSupportNotificationId = 903;

  bool _isInitialized = false;
  bool _isReminderScheduled = false;
  DateTime? _scheduledReminderTime;
  bool permissionGranted = true;
  int cancelCount = 0;
  int scheduleCount = 0;
  int notificationCount = 0;

  final List<Map<String, dynamic>> dispatchedNotifications = [];
  final Set<String> sentNotificationDeduplicationKeys = {};

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
  Future<void> scheduleDailyReminder({
    required DateTime triggerTime,
    UserRole role = UserRole.wife,
  }) async {
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
    UserRole role = UserRole.wife,
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
    await scheduleDailyReminder(triggerTime: nextTime, role: role);
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    notificationCount++;
    dispatchedNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> notifyFertilePattern({
    required UserRole role,
    DateTime? now,
    bool force = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final dedupeKey = '${effectiveNow.dateKey}_fertile_${role.name}';
    if (!force && sentNotificationDeduplicationKeys.contains(dedupeKey)) {
      return;
    }
    sentNotificationDeduplicationKeys.add(dedupeKey);

    final msg = CycleNotificationFormatter.fertilePatternMessage(role);
    await showNotification(
      id: fertilePatternNotificationId,
      title: msg.title,
      body: msg.body,
    );
  }

  @override
  Future<void> notifyPeakDay({
    required UserRole role,
    String? peakLabel,
    DateTime? now,
    bool force = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final labelKey = peakLabel ?? 'P';
    final dedupeKey = '${effectiveNow.dateKey}_peak_${labelKey}_${role.name}';
    if (!force && sentNotificationDeduplicationKeys.contains(dedupeKey)) {
      return;
    }
    sentNotificationDeduplicationKeys.add(dedupeKey);

    final msg = CycleNotificationFormatter.peakDayMessage(
      role,
      peakLabel: peakLabel,
    );
    await showNotification(
      id: peakDayNotificationId,
      title: msg.title,
      body: msg.body,
    );
  }

  @override
  Future<void> notifyKindnessSupport({
    required UserRole role,
    DateTime? now,
    bool force = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final dedupeKey = '${effectiveNow.dateKey}_kindness_${role.name}';
    if (!force && sentNotificationDeduplicationKeys.contains(dedupeKey)) {
      return;
    }
    sentNotificationDeduplicationKeys.add(dedupeKey);

    final msg = CycleNotificationFormatter.kindnessSupportMessage(role);
    await showNotification(
      id: kindnessSupportNotificationId,
      title: msg.title,
      body: msg.body,
    );
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
