import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';
part 'notification_preferences.g.dart';

bool _parseBooleanWithDefaultTrue(Object? rawValue) {
  if (rawValue is bool) {
    return rawValue;
  }
  if (rawValue is String) {
    final normalized = rawValue.trim().toLowerCase();
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
  }
  if (rawValue is num) {
    return rawValue != 0;
  }
  return true;
}

Object? _readDailyLoggingReminderValue(Map<dynamic, dynamic> map, String key) {
  if (map.containsKey('dailyLoggingReminder') &&
      map['dailyLoggingReminder'] != null) {
    return map['dailyLoggingReminder'];
  }
  if (map.containsKey('reminderEnabled') && map['reminderEnabled'] != null) {
    return map['reminderEnabled'];
  }
  return true;
}

@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const NotificationPreferences._();

  const factory NotificationPreferences({
    @Default(true)
    @JsonKey(fromJson: _parseBooleanWithDefaultTrue)
    bool fertilePatternAlerts,
    @Default(true)
    @JsonKey(fromJson: _parseBooleanWithDefaultTrue)
    bool partnerSupportReminders,
    @Default(true)
    @JsonKey(
      readValue: _readDailyLoggingReminderValue,
      fromJson: _parseBooleanWithDefaultTrue,
    )
    bool dailyLoggingReminder,
    @Default(true)
    @JsonKey(fromJson: _parseBooleanWithDefaultTrue)
    bool breastSelfExamReminder,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const NotificationPreferences();
    }
    return NotificationPreferences.fromJson(map);
  }

  Map<String, dynamic> toMap() => toJson();
}
