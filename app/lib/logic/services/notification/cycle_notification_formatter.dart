import '../../models/user_role.dart';

class NotificationMessage {
  final String title;
  final String body;

  const NotificationMessage({required this.title, required this.body});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationMessage &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          body == other.body;

  @override
  int get hashCode => title.hashCode ^ body.hashCode;

  @override
  String toString() => '$title: $body';
}

class CycleNotificationFormatter {
  static const String husbandFertilePatternBody =
      'Cycle Update: Fertile mucus pattern recorded today. A great time to show extra love, buy flowers, or plan a thoughtful gesture!';
  static const String wifeFertilePatternBody =
      "Fertile Pattern Logged: Today's observation indicates potential fertility (peak-type mucus / non-BIP pattern).";

  static const String husbandPeakDayBody =
      'Peak Day identified: The fertility window count (P+1 to P+3) is underway.';
  static const String wifePeakDayBody =
      'Peak Day recorded: Entering post-peak phase (P+1 through P+3 count).';

  static const String husbandKindnessSupportBody =
      'Reminder to be kind: Your spouse is transitioning cycle phases. Extra gentleness, words of affirmation, and support go a long way today!';
  static const String wifeKindnessSupportBody =
      'Reminder to be kind: You are transitioning cycle phases. Extra gentleness, words of affirmation, and support go a long way today!';

  static const String husbandDailyReminderBody =
      "Reminder to check in with your spouse on today's chart entry.";
  static const String wifeDailyReminderBody =
      'Reminder to log your Creighton observations for today.';

  static NotificationMessage fertilePatternMessage(UserRole role) {
    switch (role) {
      case UserRole.husband:
        return const NotificationMessage(
          title: '🌸 Cycle Update',
          body: husbandFertilePatternBody,
        );
      case UserRole.wife:
        return const NotificationMessage(
          title: '🌸 Fertile Pattern Logged',
          body: wifeFertilePatternBody,
        );
    }
  }

  static NotificationMessage peakDayMessage(
    UserRole role, {
    String? peakLabel,
  }) {
    switch (role) {
      case UserRole.husband:
        return const NotificationMessage(
          title: '🌿 Peak Day Update',
          body: husbandPeakDayBody,
        );
      case UserRole.wife:
        return const NotificationMessage(
          title: '🌿 Peak Day Recorded',
          body: wifePeakDayBody,
        );
    }
  }

  static NotificationMessage kindnessSupportMessage(UserRole role) {
    switch (role) {
      case UserRole.husband:
        return const NotificationMessage(
          title: '❤️ Reminder to be Kind',
          body: husbandKindnessSupportBody,
        );
      case UserRole.wife:
        return const NotificationMessage(
          title: '❤️ Phase Support',
          body: wifeKindnessSupportBody,
        );
    }
  }

  static NotificationMessage dailyLoggingReminder(UserRole role) {
    switch (role) {
      case UserRole.husband:
        return const NotificationMessage(
          title: '📝 Daily Chart Check-In',
          body: husbandDailyReminderBody,
        );
      case UserRole.wife:
        return const NotificationMessage(
          title: '📝 Daily Observation Reminder',
          body: wifeDailyReminderBody,
        );
    }
  }
}
