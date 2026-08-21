import 'package:flutter/material.dart';

import '../logic/logic.dart';

class SettingsScreen extends StatefulWidget {
  final Cycle? activeCycle;

  const SettingsScreen({super.key, this.activeCycle});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Stream<List<Map<String, dynamic>>> _chartsStream;
  late final Stream<String?> _roleStream;
  final _inviteEmailController = TextEditingController();
  bool _isInviting = false;
  String _inviteStatus = '';

  // Set of BIP codes
  final List<String> _availableBipOptions = ['6C', '6Y', '8C', '8Y'];
  List<String> _selectedBips = [];

  @override
  void initState() {
    super.initState();
    _chartsStream = Services.db.streamAvailableCharts();
    _roleStream = Services.db.streamUserRole();
    if (widget.activeCycle != null) {
      _selectedBips = List<String>.from(widget.activeCycle!.bipCodes);
    }
  }

  Future<void> _sendInvite() async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isInviting = true;
      _inviteStatus = '';
    });

    try {
      await Services.db.invitePartner(email);
      setState(() {
        _inviteStatus = 'Invitation successfully sent to $email!';
        _inviteEmailController.clear();
      });
    } catch (e) {
      setState(() {
        _inviteStatus =
            'Error: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    } finally {
      setState(() {
        _isInviting = false;
      });
    }
  }

  Future<void> _toggleBipCode(String code, bool selected) async {
    if (widget.activeCycle == null) return;

    setState(() {
      if (selected) {
        _selectedBips.add(code);
      } else {
        _selectedBips.remove(code);
      }
    });

    // Save to database which triggers automatic recalculation of stamps!
    await Services.db.updateBipCodes(widget.activeCycle!.id, _selectedBips);
  }

  void _confirmDeleteChart(BuildContext context, String chartId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Chart?'),
          content: Text(
            'Are you sure you want to permanently delete the chart "$chartId" and all of its cycles/observations? This will delete the data for all collaborators and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                try {
                  await Services.db.deleteChart(chartId);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error deleting chart: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLeaveChart(BuildContext context, String chartId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Chart?'),
          content: Text(
            'Are you sure you want to leave the chart "$chartId"? You will lose access to its cycles and observations, but the data will remain active for other collaborators.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                try {
                  await Services.db.leaveChart(chartId);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error leaving chart: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Leave Chart'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Services.db.currentUser;
    final chartId = Services.db.currentChartId;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User profile info card
            Card(
              elevation: 0,
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<String?>(
                  stream: _roleStream,
                  builder: (context, roleSnapshot) {
                    final currentRole = UserRole.fromString(
                      roleSnapshot.data ??
                          (user?.uid == "husband_uid" ? "husband" : "wife"),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Profile',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${user?.email ?? "Offline Mode"}'),
                        Text('Role: ${currentRole.displayName}'),
                        Text('Shared Chart ID: ${chartId ?? "Not linked"}'),
                        const SizedBox(height: 12),
                        Text(
                          'Partner Role',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SegmentedButton<UserRole>(
                          key: const Key('role_segmented_button'),
                          segments: const [
                            ButtonSegment<UserRole>(
                              value: UserRole.wife,
                              label: Text('Wife / Tracker'),
                              icon: Icon(Icons.female),
                            ),
                            ButtonSegment<UserRole>(
                              value: UserRole.husband,
                              label: Text('Husband / Partner'),
                              icon: Icon(Icons.male),
                            ),
                          ],
                          selected: {currentRole},
                          onSelectionChanged:
                              (Set<UserRole> newSelection) async {
                                final selected = newSelection.first;
                                await Services.db.updateUserRole(selected.code);
                              },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Base Infertile Pattern (BIP) Configuration
            if (widget.activeCycle != null) ...[
              Text(
                'Base Infertile Pattern (BIP) Config',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Define which cervical mucus VDRS codes constitute the wife\'s standard BIP. The system will automatically paint matching days with Yellow stamps (denoting infertility) instead of White Baby stamps.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _availableBipOptions.map((code) {
                  final isSelected = _selectedBips.contains(code);
                  return FilterChip(
                    label: Text(code),
                    selected: isSelected,
                    onSelected: (selected) => _toggleBipCode(code, selected),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
            ],

            // Invite Partner Form
            Text(
              'Invite Partner to Collaborate',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your spouse\'s email address. Once they sign up and log in, they will be prompted to join this cycle chart and can view or log observations in real time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                labelText: 'Partner Email Address',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _isInviting
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _sendInvite,
                    child: const Text('Send Collaboration Invite'),
                  ),
            if (_inviteStatus.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _inviteStatus,
                style: TextStyle(
                  color: _inviteStatus.startsWith('Error')
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
            if (chartId != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chartsStream,
                builder: (context, snapshot) {
                  final charts = snapshot.data ?? [];
                  final activeChart = charts.firstWhere(
                    (c) => c['id'] == chartId,
                    orElse: () => <String, dynamic>{},
                  );
                  final isEnabled =
                      (activeChart['reminderEnabled'] as bool?) ?? true;
                  final userIds = List<String>.from(
                    activeChart['userIds'] ?? [],
                  );
                  final hasOtherCollaborators = userIds.length > 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 24),
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
                      Builder(
                        builder: (context) {
                          final rawPrefs =
                              activeChart['notificationPreferences'];
                          final prefs = NotificationPreferences.fromMap(
                            rawPrefs != null
                                ? Map<String, dynamic>.from(rawPrefs)
                                : {'reminderEnabled': isEnabled},
                          );

                          return Column(
                            children: [
                              Card(
                                elevation: 0,
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                child: SwitchListTile(
                                  key: const Key('switch_daily_reminder'),
                                  title: const Text(
                                    'Daily 9:00 PM Reminder',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                    await Services.db
                                        .updateNotificationPreferences(
                                          chartId,
                                          updatedPrefs,
                                        );
                                    if (newValue) {
                                      await Services.notifications
                                          .requestPermissions();
                                    }
                                    final todayKey = DateTime.now().dateKey;
                                    final isTodayLogged =
                                        widget
                                            .activeCycle
                                            ?.dailyEntries[todayKey]
                                            ?.observations
                                            .isNotEmpty ==
                                        true;
                                    await Services.notifications
                                        .syncReminderSchedule(
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
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                child: SwitchListTile(
                                  key: const Key('switch_fertile_pattern'),
                                  title: const Text(
                                    'Fertile Pattern & Phase Alerts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                    await Services.db
                                        .updateNotificationPreferences(
                                          chartId,
                                          updatedPrefs,
                                        );
                                    if (newValue) {
                                      await Services.notifications
                                          .requestPermissions();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 0,
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                child: SwitchListTile(
                                  key: const Key('switch_partner_support'),
                                  title: const Text(
                                    'Spousal Support & Kindness Suggestions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                    await Services.db
                                        .updateNotificationPreferences(
                                          chartId,
                                          updatedPrefs,
                                        );
                                    if (newValue) {
                                      await Services.notifications
                                          .requestPermissions();
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        'Danger Zone',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Permanently delete this chart and all associated cycle logs and observations. This action is destructive and cannot be undone.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () =>
                                    _confirmDeleteChart(context, chartId),
                                icon: const Icon(Icons.delete_forever),
                                label: const Text('Delete Chart'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                ),
                              ),
                              if (hasOtherCollaborators) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                Text(
                                  'Leave this chart. You will lose access to its observations, but the data will remain active for other collaborators.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _confirmLeaveChart(context, chartId),
                                  icon: const Icon(Icons.exit_to_app),
                                  label: const Text('Leave Chart'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    side: BorderSide(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            // Logout Button
            OutlinedButton.icon(
              onPressed: () {
                Services.db.signOut();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            // Debug & Diagnostics Card
            Text(
              'Debug & Diagnostics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export a complete, structured JSON diagnostic snapshot containing current Firestore documents, auth state, rule permission checks, and in-memory event logs to assist with troubleshooting.',
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          AppStateExporter.instance.shareDebugState(context),
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Export Debug State (JSON)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
