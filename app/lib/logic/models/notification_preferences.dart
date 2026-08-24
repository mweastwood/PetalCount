class NotificationPreferences {
  final bool fertilePatternAlerts;
  final bool partnerSupportReminders;
  final bool dailyLoggingReminder;
  final bool breastSelfExamReminder;

  const NotificationPreferences({
    this.fertilePatternAlerts = true,
    this.partnerSupportReminders = true,
    this.dailyLoggingReminder = true,
    this.breastSelfExamReminder = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'fertilePatternAlerts': fertilePatternAlerts,
      'partnerSupportReminders': partnerSupportReminders,
      'dailyLoggingReminder': dailyLoggingReminder,
      'breastSelfExamReminder': breastSelfExamReminder,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      fertilePatternAlerts: (map['fertilePatternAlerts'] as bool?) ?? true,
      partnerSupportReminders:
          (map['partnerSupportReminders'] as bool?) ?? true,
      dailyLoggingReminder:
          (map['dailyLoggingReminder'] as bool?) ??
          (map['reminderEnabled'] as bool?) ??
          true,
      breastSelfExamReminder: (map['breastSelfExamReminder'] as bool?) ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? fertilePatternAlerts,
    bool? partnerSupportReminders,
    bool? dailyLoggingReminder,
    bool? breastSelfExamReminder,
  }) {
    return NotificationPreferences(
      fertilePatternAlerts: fertilePatternAlerts ?? this.fertilePatternAlerts,
      partnerSupportReminders:
          partnerSupportReminders ?? this.partnerSupportReminders,
      dailyLoggingReminder: dailyLoggingReminder ?? this.dailyLoggingReminder,
      breastSelfExamReminder:
          breastSelfExamReminder ?? this.breastSelfExamReminder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          runtimeType == other.runtimeType &&
          fertilePatternAlerts == other.fertilePatternAlerts &&
          partnerSupportReminders == other.partnerSupportReminders &&
          dailyLoggingReminder == other.dailyLoggingReminder &&
          breastSelfExamReminder == other.breastSelfExamReminder;

  @override
  int get hashCode =>
      fertilePatternAlerts.hashCode ^
      partnerSupportReminders.hashCode ^
      dailyLoggingReminder.hashCode ^
      breastSelfExamReminder.hashCode;
}
