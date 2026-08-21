import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings_screen.dart';

void main() {
  late InMemoryDatabaseService db;
  late InMemoryNotificationService notifications;

  setUp(() {
    db = InMemoryDatabaseService();
    notifications = InMemoryNotificationService();
    Services.db = db;
    Services.notifications = notifications;
  });

  testWidgets(
    'SettingsScreen displays Notifications & Reminders section with all switches',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Notifications & Reminders'), findsOneWidget);
      expect(find.text('Daily 9:00 PM Reminder'), findsOneWidget);
      expect(find.text('Fertile Pattern & Phase Alerts'), findsOneWidget);
      expect(
        find.text('Spousal Support & Kindness Suggestions'),
        findsOneWidget,
      );

      final dailyFinder = find.byKey(const Key('switch_daily_reminder'));
      final fertileFinder = find.byKey(const Key('switch_fertile_pattern'));
      final supportFinder = find.byKey(const Key('switch_partner_support'));

      expect(dailyFinder, findsOneWidget);
      expect(fertileFinder, findsOneWidget);
      expect(supportFinder, findsOneWidget);

      expect(tester.widget<SwitchListTile>(dailyFinder).value, isTrue);
      expect(tester.widget<SwitchListTile>(fertileFinder).value, isTrue);
      expect(tester.widget<SwitchListTile>(supportFinder).value, isTrue);
    },
  );

  testWidgets(
    'Toggling Daily Reminder switch updates database and syncs NotificationService',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('switch_daily_reminder'));
      expect(switchFinder, findsOneWidget);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      // Toggle switch OFF
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify database updated to false
      final chartId = db.currentChartId;
      expect(chartId, isNotNull);
      final isEnabled = await db.streamChartReminderEnabled(chartId!).first;
      expect(isEnabled, isFalse);

      // Verify notification canceled
      expect(notifications.isReminderScheduled, isFalse);
      expect(notifications.cancelCount, greaterThanOrEqualTo(1));

      // Toggle switch back ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final isReEnabled = await db.streamChartReminderEnabled(chartId).first;
      expect(isReEnabled, isTrue);
      expect(notifications.isReminderScheduled, isTrue);
      expect(notifications.scheduleCount, greaterThanOrEqualTo(1));
    },
  );

  testWidgets(
    'Toggling Fertile Pattern and Partner Support switches updates NotificationPreferences in database',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final fertileFinder = find.byKey(const Key('switch_fertile_pattern'));
      final supportFinder = find.byKey(const Key('switch_partner_support'));

      await tester.ensureVisible(fertileFinder);
      await tester.tap(fertileFinder);
      await tester.pumpAndSettle();

      await tester.ensureVisible(supportFinder);
      await tester.tap(supportFinder);
      await tester.pumpAndSettle();

      final chartId = db.currentChartId!;
      final prefs = await db.streamNotificationPreferences(chartId).first;
      expect(prefs.fertilePatternAlerts, isFalse);
      expect(prefs.partnerSupportReminders, isFalse);
      expect(prefs.dailyLoggingReminder, isTrue);
    },
  );

  testWidgets('Selecting Partner Role changes role in database', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('role_segmented_button')), findsOneWidget);
    expect(find.text('Wife / Tracker'), findsOneWidget);
    expect(find.text('Husband / Partner'), findsOneWidget);

    // Initial role is husband
    expect(await db.streamUserRole().first, 'husband');

    // Tap Wife segment
    await tester.tap(find.text('Wife / Tracker'));
    await tester.pumpAndSettle();

    expect(await db.streamUserRole().first, 'wife');

    // Tap Husband segment back
    await tester.tap(find.text('Husband / Partner'));
    await tester.pumpAndSettle();

    expect(await db.streamUserRole().first, 'husband');
  });
}
