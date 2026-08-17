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
    'SettingsScreen displays Notifications & Reminders section with switch',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.pumpAndSettle();

      expect(find.text('Notifications & Reminders'), findsOneWidget);
      expect(find.text('Daily 9:00 PM Reminder'), findsOneWidget);
      expect(
        find.text(
          'Send a reminder notification at 9:00 PM if no observations have been logged for today.',
        ),
        findsOneWidget,
      );

      final switchFinder = find.byKey(const Key('switch_daily_reminder'));
      expect(switchFinder, findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.value, isTrue);
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
}
