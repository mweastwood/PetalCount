import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class NotificationPreferencesSection extends StatelessWidget {
  final String chartId;
  final Cycle? activeCycle;
  final Stream<List<Map<String, dynamic>>>? chartsStream;

  const NotificationPreferencesSection({
    super.key,
    required this.chartId,
    this.activeCycle,
    this.chartsStream,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chartsStream ?? Services.db.streamAvailableCharts(),
      builder: (context, snapshot) {
        final charts = snapshot.data ?? [];
        final activeChart = charts.firstWhere(
          (c) => c['id'] == chartId,
          orElse: () => <String, dynamic>{},
        );
        final isEnabled = (activeChart['reminderEnabled'] as bool?) ?? true;
        final rawPrefs = activeChart['notificationPreferences'];
        final prefs = NotificationPreferences.fromMap(
          rawPrefs != null
              ? Map<String, dynamic>.from(rawPrefs)
              : {'reminderEnabled': isEnabled},
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Notifications & Reminders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure automated daily reminders and cycle phase alerts to stay consistent and supportive.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: SwitchListTile(
                key: const Key('switch_daily_reminder'),
                title: const Text(
                  'Daily 9:00 PM Reminder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Send a reminder notification at 9:00 PM if no observations have been logged for today.',
                ),
                secondary: Icon(
                  prefs.dailyLoggingReminder
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  color: prefs.dailyLoggingReminder
                      ? theme.colorScheme.primary
                      : null,
                ),
                value: prefs.dailyLoggingReminder,
                onChanged: (bool newValue) async {
                  final updatedPrefs = prefs.copyWith(
                    dailyLoggingReminder: newValue,
                  );
                  await Services.db.updateNotificationPreferences(
                    chartId,
                    updatedPrefs,
                  );
                  if (newValue) {
                    await Services.notifications.requestPermissions();
                  }
                  final todayKey = DateTime.now().dateKey;
                  final isTodayLogged =
                      activeCycle
                          ?.dailyEntries[todayKey]
                          ?.observations
                          .isNotEmpty ==
                      true;
                  await Services.notifications.syncReminderSchedule(
                    chartId: chartId,
                    reminderEnabled: newValue,
                    isTodayLogged: isTodayLogged,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: SwitchListTile(
                key: const Key('switch_fertile_pattern'),
                title: const Text(
                  'Fertile Pattern & Phase Alerts',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Receive notifications when fertile mucus patterns or peak days are detected.',
                ),
                secondary: Icon(
                  prefs.fertilePatternAlerts
                      ? Icons.local_florist
                      : Icons.local_florist_outlined,
                  color: prefs.fertilePatternAlerts
                      ? theme.colorScheme.primary
                      : null,
                ),
                value: prefs.fertilePatternAlerts,
                onChanged: (bool newValue) async {
                  final updatedPrefs = prefs.copyWith(
                    fertilePatternAlerts: newValue,
                  );
                  await Services.db.updateNotificationPreferences(
                    chartId,
                    updatedPrefs,
                  );
                  if (newValue) {
                    await Services.notifications.requestPermissions();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: SwitchListTile(
                key: const Key('switch_partner_support'),
                title: const Text(
                  'Spousal Support & Kindness Suggestions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Receive phase support tips, kindness reminders, and flower suggestions tailored for your partner role.',
                ),
                secondary: Icon(
                  prefs.partnerSupportReminders
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: prefs.partnerSupportReminders
                      ? theme.colorScheme.primary
                      : null,
                ),
                value: prefs.partnerSupportReminders,
                onChanged: (bool newValue) async {
                  final updatedPrefs = prefs.copyWith(
                    partnerSupportReminders: newValue,
                  );
                  await Services.db.updateNotificationPreferences(
                    chartId,
                    updatedPrefs,
                  );
                  if (newValue) {
                    await Services.notifications.requestPermissions();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: SwitchListTile(
                key: const Key('switch_breast_self_exam'),
                title: const Text(
                  'Day 7 Breast Self-Exam Reminder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Receive a routine health reminder on Day 7 of each cycle for a Breast Self-Exam (BSE).',
                ),
                secondary: Icon(
                  prefs.breastSelfExamReminder
                      ? Icons.health_and_safety
                      : Icons.health_and_safety_outlined,
                  color: prefs.breastSelfExamReminder
                      ? theme.colorScheme.primary
                      : null,
                ),
                value: prefs.breastSelfExamReminder,
                onChanged: (bool newValue) async {
                  final updatedPrefs = prefs.copyWith(
                    breastSelfExamReminder: newValue,
                  );
                  await Services.db.updateNotificationPreferences(
                    chartId,
                    updatedPrefs,
                  );
                  if (newValue) {
                    await Services.notifications.requestPermissions();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
