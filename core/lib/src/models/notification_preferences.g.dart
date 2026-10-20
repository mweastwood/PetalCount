// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationPreferences _$NotificationPreferencesFromJson(Map json) =>
    _NotificationPreferences(
      fertilePatternAlerts: json['fertilePatternAlerts'] == null
          ? true
          : _parseBooleanWithDefaultTrue(json['fertilePatternAlerts']),
      partnerSupportReminders: json['partnerSupportReminders'] == null
          ? true
          : _parseBooleanWithDefaultTrue(json['partnerSupportReminders']),
      dailyLoggingReminder:
          _readDailyLoggingReminderValue(json, 'dailyLoggingReminder') == null
          ? true
          : _parseBooleanWithDefaultTrue(
              _readDailyLoggingReminderValue(json, 'dailyLoggingReminder'),
            ),
      breastSelfExamReminder: json['breastSelfExamReminder'] == null
          ? true
          : _parseBooleanWithDefaultTrue(json['breastSelfExamReminder']),
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
  _NotificationPreferences instance,
) => <String, dynamic>{
  'fertilePatternAlerts': instance.fertilePatternAlerts,
  'partnerSupportReminders': instance.partnerSupportReminders,
  'dailyLoggingReminder': instance.dailyLoggingReminder,
  'breastSelfExamReminder': instance.breastSelfExamReminder,
};
