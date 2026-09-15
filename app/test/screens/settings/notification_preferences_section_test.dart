import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/notification_preferences_section.dart';

void main() {
  late InMemoryDatabaseService db;
  late InMemoryNotificationService notifications;

  setUp(() async {
    db = InMemoryDatabaseService();
    notifications = InMemoryNotificationService();
    Services.db = db;
    Services.notifications = notifications;
  });

  Widget buildTestSection({required String chartId, Cycle? activeCycle}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StreamBuilder<NotificationPreferences>(
            stream: db.streamNotificationPreferences(chartId),
            initialData:
                db.getLatestNotificationPreferences(chartId) ??
                const NotificationPreferences(),
            builder: (context, snapshot) => NotificationPreferencesSection(
              chartId: chartId,
              preferences: snapshot.data ?? const NotificationPreferences(),
              activeCycle: activeCycle,
            ),
          ),
        ),
      ),
    );
  }

  group('NotificationPreferencesSection Tests', () {
    testWidgets(
      'renders all four preference switches matching provided preferences',
      (WidgetTester tester) async {
        const customPrefs = NotificationPreferences(
          dailyLoggingReminder: true,
          fertilePatternAlerts: false,
          partnerSupportReminders: true,
          breastSelfExamReminder: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NotificationPreferencesSection(
                  chartId: 'test_chart',
                  preferences: customPrefs,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Notifications & Reminders'), findsOneWidget);
        expect(find.byKey(const Key('switch_daily_reminder')), findsOneWidget);
        expect(find.byKey(const Key('switch_fertile_pattern')), findsOneWidget);
        expect(find.byKey(const Key('switch_partner_support')), findsOneWidget);
        expect(
          find.byKey(const Key('switch_breast_self_exam')),
          findsOneWidget,
        );

        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const Key('switch_daily_reminder')),
              )
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const Key('switch_fertile_pattern')),
              )
              .value,
          isFalse,
        );
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const Key('switch_partner_support')),
              )
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const Key('switch_breast_self_exam')),
              )
              .value,
          isFalse,
        );
      },
    );

    testWidgets(
      'toggling daily reminder updates preferences and syncs notifications',
      (WidgetTester tester) async {
        final chartId = db.currentChartId!;

        await tester.pumpWidget(buildTestSection(chartId: chartId));
        await tester.pumpAndSettle();

        final dailyFinder = find.byKey(const Key('switch_daily_reminder'));
        expect(tester.widget<SwitchListTile>(dailyFinder).value, isTrue);

        // Toggle off
        await tester.tap(dailyFinder);
        await tester.pumpAndSettle();

        final isEnabled = await db.streamChartReminderEnabled(chartId).first;
        expect(isEnabled, isFalse);
        expect(notifications.isReminderScheduled, isFalse);
      },
    );

    testWidgets('toggling phase alerts and BSE updates database preferences', (
      WidgetTester tester,
    ) async {
      final chartId = db.currentChartId!;

      await tester.pumpWidget(buildTestSection(chartId: chartId));
      await tester.pumpAndSettle();

      final fertileFinder = find.byKey(const Key('switch_fertile_pattern'));
      final bseFinder = find.byKey(const Key('switch_breast_self_exam'));

      await tester.tap(fertileFinder);
      await tester.pumpAndSettle();

      await tester.tap(bseFinder);
      await tester.pumpAndSettle();

      final prefs = await db.streamNotificationPreferences(chartId).first;
      expect(prefs.fertilePatternAlerts, isFalse);
      expect(prefs.breastSelfExamReminder, isFalse);
    });
  });
}
