class LocalTimeInfo {
  final int hour;
  final String dateKey;

  const LocalTimeInfo({required this.hour, required this.dateKey});

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'dateKey': dateKey,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTimeInfo &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          dateKey == other.dateKey;

  @override
  int get hashCode => Object.hash(hour, dateKey);

  @override
  String toString() => 'LocalTimeInfo(hour: $hour, dateKey: $dateKey)';
}

class DailyRemindersResult {
  final int chartsChecked;
  final int remindersSent;
  final int tokensNotified;

  const DailyRemindersResult({
    required this.chartsChecked,
    required this.remindersSent,
    required this.tokensNotified,
  });

  Map<String, dynamic> toJson() => {
        'chartsChecked': chartsChecked,
        'remindersSent': remindersSent,
        'tokensNotified': tokensNotified,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRemindersResult &&
          runtimeType == other.runtimeType &&
          chartsChecked == other.chartsChecked &&
          remindersSent == other.remindersSent &&
          tokensNotified == other.tokensNotified;

  @override
  int get hashCode => Object.hash(chartsChecked, remindersSent, tokensNotified);

  @override
  String toString() =>
      'DailyRemindersResult(chartsChecked: $chartsChecked, remindersSent: $remindersSent, tokensNotified: $tokensNotified)';
}

class CollaboratorNotificationResult {
  final int notificationsDispatched;
  final int tokensNotified;

  const CollaboratorNotificationResult({
    required this.notificationsDispatched,
    required this.tokensNotified,
  });

  Map<String, dynamic> toJson() => {
        'notificationsDispatched': notificationsDispatched,
        'tokensNotified': tokensNotified,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaboratorNotificationResult &&
          runtimeType == other.runtimeType &&
          notificationsDispatched == other.notificationsDispatched &&
          tokensNotified == other.tokensNotified;

  @override
  int get hashCode => Object.hash(notificationsDispatched, tokensNotified);

  @override
  String toString() =>
      'CollaboratorNotificationResult(notificationsDispatched: $notificationsDispatched, tokensNotified: $tokensNotified)';
}
