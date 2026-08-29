import 'dart:async';
import 'package:flutter/material.dart';

import '../logic/logic.dart';
import '../widgets/add_observation_dialog.dart';
import '../widgets/daily_detail_sheet.dart';
import 'chart_screen.dart';
import 'chart_selection_screen.dart';
import 'observations_screen.dart';
import 'settings_screen.dart';
import 'supplement_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Uri? mockUri;
  final DateTime? todayOverride;
  const DashboardScreen({super.key, this.mockUri, this.todayOverride});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late final Stream<List<Cycle>> _cyclesStream;
  StreamSubscription<List<Cycle>>? _cyclesSubscription;
  late final AppRouteManager _routeManager;
  ViewMode _viewMode = ViewMode.observations;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Services.notifications.setupFcmPushNotifications();
    _cyclesStream = Services.db.streamCycles();
    _cyclesSubscription = _cyclesStream.listen((cycles) {
      _syncReminderStatus(cycles);
    });
    _routeManager = AppRouteManager(mockUri: widget.mockUri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeManager.handleUrlParameters(
        context: context,
        onViewModeChanged: (mode) {
          if (!mounted) return;
          setState(() {
            _viewMode = mode;
          });
        },
        currentViewMode: _viewMode,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cyclesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAndSyncReminders();
    }
  }

  void _syncReminderStatus(List<Cycle> cycles) {
    final chartId = Services.db.currentChartId;
    if (chartId == null) return;
    final now = widget.todayOverride ?? DateTime.now();
    final todayKey = now.dateKey;
    final isTodayLogged = cycles.any(
      (cycle) => cycle.dailyEntries[todayKey]?.observations.isNotEmpty == true,
    );
    _syncDailyLoggingReminder(chartId, isTodayLogged, now);
    _maybeNotifyBreastSelfExam(chartId, cycles, now);
  }

  Future<void> _syncDailyLoggingReminder(
    String chartId,
    bool isTodayLogged,
    DateTime now,
  ) async {
    try {
      final enabled = await Services.db
          .streamChartReminderEnabled(chartId)
          .first;
      await Services.notifications.syncReminderSchedule(
        chartId: chartId,
        reminderEnabled: enabled,
        isTodayLogged: isTodayLogged,
        now: widget.todayOverride,
      );
    } catch (_) {}
  }

  Future<void> _maybeNotifyBreastSelfExam(
    String chartId,
    List<Cycle> cycles,
    DateTime now,
  ) async {
    if (cycles.isEmpty) return;
    final sortedCycles = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final latestCycle = sortedCycles.last;
    final today = DateTime(now.year, now.month, now.day);
    final currentDay = calendarDaysBetween(latestCycle.startDate, today) + 1;
    if (currentDay != 7) return;

    try {
      final prefs = await Services.db
          .streamNotificationPreferences(chartId)
          .first;
      if (!prefs.breastSelfExamReminder) return;

      final roleStr = await Services.db.streamUserRole().first;
      final role = UserRole.fromString(roleStr);
      await Services.notifications.notifyBreastSelfExam(role: role, now: now);
    } catch (_) {}
  }

  Future<void> _refreshAndSyncReminders() async {
    try {
      final cycles = await Services.db.streamCycles().first;
      _syncReminderStatus(cycles);
    } catch (_) {}
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
    });
  }

  void _closeSpeedDial() {
    if (_isSpeedDialOpen) {
      setState(() {
        _isSpeedDialOpen = false;
      });
    }
  }

  void _showAddObservationDialogCategory(
    BuildContext context,
    Cycle? cycle,
    ObservationCategory category,
  ) {
    _closeSpeedDial();
    showDialog(
      context: context,
      builder: (context) => AddObservationDialog(
        cycle: cycle,
        defaultDate: DateTime.now(),
        category: category,
      ),
    );
  }

  void _showAddObservationDialog(BuildContext context, Cycle? cycle) {
    _showAddObservationDialogCategory(context, cycle, ObservationCategory.full);
  }

  void _showAddObservationDialogForDate(
    BuildContext context,
    Cycle? cycle,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          AddObservationDialog(cycle: cycle, defaultDate: date),
    );
  }

  void _showDailyDetailSheet(
    BuildContext context,
    DailyEntry entry,
    Cycle cycle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DailyDetailSheet(entry: entry, cycle: cycle),
    );
  }

  Widget _buildDay7BseBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('banner_day_7_bse'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.health_and_safety,
            color: theme.colorScheme.onTertiaryContainer,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cycle Day 7: Routine Breast Self-Exam',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Day 7 is the standard Creighton Model routine day for a monthly Breast Self-Exam (BSE).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCyclesView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Observations Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your self-reported observations to automatically track and detect your cycles.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddObservationDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Log First Observation'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Cycle>>(
      stream: _cyclesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cycles = snapshot.data ?? [];
        final now = widget.todayOverride ?? DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        bool isDay7 = false;
        if (cycles.isNotEmpty) {
          final sortedCycles = List<Cycle>.from(cycles)
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          final latestCycle = sortedCycles.last;
          final currentDay =
              calendarDaysBetween(latestCycle.startDate, today) + 1;
          isDay7 = currentDay == 7;
        }

        final chartId = Services.db.currentChartId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Petal Count'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export Chart to PDF',
                onPressed: cycles.isNotEmpty
                    ? () => PdfExportService.exportCyclesToPdf(cycles)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  _routeManager.updateUrlPathRaw('/settings');
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: '/settings'),
                          builder: (context) => SettingsScreen(
                            activeCycle: cycles.isNotEmpty
                                ? cycles.first
                                : null,
                          ),
                        ),
                      )
                      .then((_) {
                        if (!mounted) return;
                        _routeManager.updateUrlPath(_viewMode);
                      });
                },
              ),
            ],
          ),
          drawer: _buildDrawer(context, cycles),
          body: GestureDetector(
            onTap: _isSpeedDialOpen ? _closeSpeedDial : null,
            behavior: HitTestBehavior.opaque,
            child: cycles.isEmpty
                ? _buildNoCyclesView(context)
                : Column(
                    children: [
                      if (isDay7 &&
                          chartId != null &&
                          _viewMode != ViewMode.supplements)
                        StreamBuilder<NotificationPreferences>(
                          stream: Services.db.streamNotificationPreferences(
                            chartId,
                          ),
                          builder: (context, prefSnap) {
                            final prefs =
                                prefSnap.data ??
                                const NotificationPreferences();
                            if (!prefs.breastSelfExamReminder) {
                              return const SizedBox.shrink();
                            }
                            return _buildDay7BseBanner(context);
                          },
                        ),
                      Expanded(
                        child: _viewMode == ViewMode.observations
                            ? ObservationsScreen(
                                cycles: cycles,
                                onSelectEntry: (entry, cycle) =>
                                    _showDailyDetailSheet(
                                      context,
                                      entry,
                                      cycle,
                                    ),
                                onAddForDate: (cycle, date) =>
                                    _showAddObservationDialogForDate(
                                      context,
                                      cycle,
                                      date,
                                    ),
                                todayOverride: widget.todayOverride,
                              )
                            : _viewMode == ViewMode.chart
                            ? ChartScreen(
                                cycles: cycles,
                                onSelectEntry: (entry, cycle) =>
                                    _showDailyDetailSheet(
                                      context,
                                      entry,
                                      cycle,
                                    ),
                                onAddForDate: (cycle, date) =>
                                    _showAddObservationDialogForDate(
                                      context,
                                      cycle,
                                      date,
                                    ),
                              )
                            : SupplementScreen(
                                initialDate: widget.todayOverride,
                                activeCycle: cycles.isNotEmpty
                                    ? cycles.first
                                    : null,
                              ),
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: cycles.isEmpty
              ? null
              : NavigationBar(
                  selectedIndex: _viewMode.index,
                  onDestinationSelected: (index) {
                    final newMode = ViewMode.values[index];
                    setState(() {
                      _viewMode = newMode;
                    });
                    _routeManager.updateUrlPath(newMode);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: 'Observations',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_on_outlined),
                      selectedIcon: Icon(Icons.grid_on),
                      label: 'Chart',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.medication_outlined),
                      selectedIcon: Icon(Icons.medication),
                      label: 'Supplements',
                    ),
                  ],
                ),
          floatingActionButton: _viewMode == ViewMode.supplements
              ? null
              : _buildSpeedDialFab(
                  context,
                  cycles.isNotEmpty ? cycles.first : null,
                ),
        );
      },
    );
  }

  Widget _buildSpeedDialFab(BuildContext context, Cycle? activeCycle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSpeedDialOpen) ...[
          _buildSpeedDialOption(
            context: context,
            label: 'Log intercourse',
            icon: Icons.favorite,
            color: Colors.pink.shade400,
            onTap: () => _showAddObservationDialogCategory(
              context,
              activeCycle,
              ObservationCategory.intercourse,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            context: context,
            label: 'Log pain',
            icon: Icons.healing,
            color: Colors.orange.shade700,
            onTap: () => _showAddObservationDialogCategory(
              context,
              activeCycle,
              ObservationCategory.pain,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            context: context,
            label: 'Log bleeding',
            icon: Icons.water_drop,
            color: Colors.red.shade600,
            onTap: () => _showAddObservationDialogCategory(
              context,
              activeCycle,
              ObservationCategory.bleeding,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            context: context,
            label: 'Log mucus',
            icon: Icons.bubble_chart,
            color: Colors.teal.shade600,
            onTap: () => _showAddObservationDialogCategory(
              context,
              activeCycle,
              ObservationCategory.mucus,
            ),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          key: const Key('fab_log_observation_toggle'),
          tooltip: 'Log Observation',
          onPressed: _toggleSpeedDial,
          child: Icon(_isSpeedDialOpen ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  Widget _buildSpeedDialOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, List<Cycle> cycles) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          ListTile(
            key: const Key('drawer_switch_chart_tile'),
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch Chart'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _routeManager.updateUrlPathRaw('/charts');
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/charts'),
                      builder: (context) => const ChartSelectionScreen(),
                    ),
                  )
                  .then((_) {
                    if (!mounted) return;
                    _routeManager.updateUrlPath(_viewMode);
                  });
            },
          ),
          ListTile(
            key: const Key('drawer_supplements_tile'),
            leading: const Icon(Icons.medication_outlined),
            title: const Text('Supplements & Schedule'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              setState(() {
                _viewMode = ViewMode.supplements;
              });
              _routeManager.updateUrlPath(ViewMode.supplements);
            },
          ),
          ListTile(
            key: const Key('drawer_settings_tile'),
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _routeManager.updateUrlPathRaw('/settings');
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/settings'),
                      builder: (context) => SettingsScreen(
                        activeCycle: cycles.isNotEmpty ? cycles.first : null,
                      ),
                    ),
                  )
                  .then((_) {
                    if (!mounted) return;
                    _routeManager.updateUrlPath(_viewMode);
                  });
            },
          ),
          ListTile(
            key: const Key('drawer_logout_tile'),
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              await Services.db.signOut();
            },
          ),
          const Divider(),
          ListTile(
            key: const Key('drawer_version_tile'),
            leading: const Icon(Icons.info_outline),
            title: Text(AppVersion.display),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
