import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class NotificationPreferencesSection extends StatelessWidget {
  final String chartId;
  final NotificationPreferences preferences;
  final Cycle? activeCycle;

  const NotificationPreferencesSection({
    super.key,
    required this.chartId,
    required this.preferences,
    this.activeCycle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              preferences.dailyLoggingReminder
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: preferences.dailyLoggingReminder
                  ? theme.colorScheme.primary
                  : null,
            ),
            value: preferences.dailyLoggingReminder,
            onChanged: (bool newValue) async {
              final updatedPrefs = preferences.copyWith(
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
              preferences.fertilePatternAlerts
                  ? Icons.local_florist
                  : Icons.local_florist_outlined,
              color: preferences.fertilePatternAlerts
                  ? theme.colorScheme.primary
                  : null,
            ),
            value: preferences.fertilePatternAlerts,
            onChanged: (bool newValue) async {
              final updatedPrefs = preferences.copyWith(
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
              preferences.partnerSupportReminders
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: preferences.partnerSupportReminders
                  ? theme.colorScheme.primary
                  : null,
            ),
            value: preferences.partnerSupportReminders,
            onChanged: (bool newValue) async {
              final updatedPrefs = preferences.copyWith(
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
              preferences.breastSelfExamReminder
                  ? Icons.health_and_safety
                  : Icons.health_and_safety_outlined,
              color: preferences.breastSelfExamReminder
                  ? theme.colorScheme.primary
                  : null,
            ),
            value: preferences.breastSelfExamReminder,
            onChanged: (bool newValue) async {
              final updatedPrefs = preferences.copyWith(
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
  }
}
