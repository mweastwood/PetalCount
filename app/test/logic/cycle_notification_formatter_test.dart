import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  group('CycleNotificationFormatter Tests', () {
    test('formats fertile pattern notification for Husband and Wife', () {
      final husbandMsg = CycleNotificationFormatter.fertilePatternMessage(
        UserRole.husband,
      );
      expect(husbandMsg.title, contains('🌸'));
      expect(
        husbandMsg.body,
        'Cycle Update: Fertile mucus pattern recorded today. A great time to show extra love, buy flowers, or plan a thoughtful gesture!',
      );

      final wifeMsg = CycleNotificationFormatter.fertilePatternMessage(
        UserRole.wife,
      );
      expect(wifeMsg.title, contains('🌸'));
      expect(
        wifeMsg.body,
        "Fertile Pattern Logged: Today's observation indicates potential fertility (peak-type mucus / non-BIP pattern).",
      );
    });

    test('formats peak day notification for Husband and Wife', () {
      final husbandMsg = CycleNotificationFormatter.peakDayMessage(
        UserRole.husband,
      );
      expect(husbandMsg.title, contains('🌿'));
      expect(
        husbandMsg.body,
        'Peak Day identified: The fertility window count (P+1 to P+3) is underway.',
      );

      final wifeMsg = CycleNotificationFormatter.peakDayMessage(UserRole.wife);
      expect(wifeMsg.title, contains('🌿'));
      expect(
        wifeMsg.body,
        'Peak Day recorded: Entering post-peak phase (P+1 through P+3 count).',
      );
    });

    test(
      'formats kindness and phase support notification for Husband and Wife',
      () {
        final husbandMsg = CycleNotificationFormatter.kindnessSupportMessage(
          UserRole.husband,
        );
        expect(husbandMsg.title, contains('❤️'));
        expect(
          husbandMsg.body,
          'Reminder to be kind: Your spouse is transitioning cycle phases. Extra gentleness, words of affirmation, and support go a long way today!',
        );

        final wifeMsg = CycleNotificationFormatter.kindnessSupportMessage(
          UserRole.wife,
        );
        expect(wifeMsg.title, contains('❤️'));
        expect(
          wifeMsg.body,
          'Reminder to be kind: You are transitioning cycle phases. Extra gentleness, words of affirmation, and support go a long way today!',
        );
      },
    );

    test('formats daily 9:00 PM logging reminder for Husband and Wife', () {
      final husbandMsg = CycleNotificationFormatter.dailyLoggingReminder(
        UserRole.husband,
      );
      expect(husbandMsg.title, contains('📝'));
      expect(
        husbandMsg.body,
        "Reminder to check in with your spouse on today's chart entry.",
      );

      final wifeMsg = CycleNotificationFormatter.dailyLoggingReminder(
        UserRole.wife,
      );
      expect(wifeMsg.title, contains('📝'));
      expect(
        wifeMsg.body,
        'Reminder to log your Creighton observations for today.',
      );
    });

    test(
      'formats Day 7 Breast Self-Exam (BSE) notification for Husband and Wife',
      () {
        final husbandMsg = CycleNotificationFormatter.breastSelfExamMessage(
          UserRole.husband,
        );
        expect(husbandMsg.title, contains('🩺'));
        expect(
          husbandMsg.body,
          'Cycle Day 7 Health Reminder: Today is routine Breast Self-Exam day for your spouse.',
        );

        final wifeMsg = CycleNotificationFormatter.breastSelfExamMessage(
          UserRole.wife,
        );
        expect(wifeMsg.title, contains('🩺'));
        expect(
          wifeMsg.body,
          'Cycle Day 7: Today is your recommended day for a routine Breast Self-Exam (BSE).',
        );
      },
    );
  });

  group('UserRole & NotificationPreferences Model Tests', () {
    test('UserRole.fromString parses valid and fallback values', () {
      expect(UserRole.fromString('husband'), UserRole.husband);
      expect(UserRole.fromString('Husband'), UserRole.husband);
      expect(UserRole.fromString('wife'), UserRole.wife);
      expect(UserRole.fromString('Wife'), UserRole.wife);
      expect(UserRole.fromString(null), UserRole.wife);
      expect(UserRole.fromString('unknown_role'), UserRole.wife);
    });

    test('NotificationPreferences serialization, defaults and copyWith', () {
      const defaultPrefs = NotificationPreferences();
      expect(defaultPrefs.fertilePatternAlerts, isTrue);
      expect(defaultPrefs.partnerSupportReminders, isTrue);
      expect(defaultPrefs.dailyLoggingReminder, isTrue);
      expect(defaultPrefs.breastSelfExamReminder, isTrue);

      final map = defaultPrefs.toMap();
      expect(map['fertilePatternAlerts'], isTrue);
      expect(map['partnerSupportReminders'], isTrue);
      expect(map['dailyLoggingReminder'], isTrue);
      expect(map['breastSelfExamReminder'], isTrue);

      final deserialized = NotificationPreferences.fromMap(map);
      expect(deserialized, equals(defaultPrefs));

      final modified = defaultPrefs.copyWith(
        fertilePatternAlerts: false,
        partnerSupportReminders: false,
        breastSelfExamReminder: false,
      );
      expect(modified.fertilePatternAlerts, isFalse);
      expect(modified.partnerSupportReminders, isFalse);
      expect(modified.dailyLoggingReminder, isTrue);
      expect(modified.breastSelfExamReminder, isFalse);

      final fromNull = NotificationPreferences.fromMap(null);
      expect(fromNull, equals(defaultPrefs));
    });
  });
}
