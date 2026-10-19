import 'dart:async';
import 'package:flutter/material.dart';

import '../logic/logic.dart';
import '../widgets/add_observation_dialog.dart';
import '../widgets/daily_detail_sheet.dart';
import 'chart_screen.dart';
import 'chart_selection_screen.dart';
import 'dashboard/dashboard.dart';
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
  String? _notificationPreferencesChartId;
  Stream<NotificationPreferences>? _notificationPreferencesStream;

  Stream<NotificationPreferences> _getNotificationPreferencesStream(
    String chartId,
  ) {
    if (_notificationPreferencesStream == null ||
        _notificationPreferencesChartId != chartId) {
      _notificationPreferencesChartId = chartId;
      _notificationPreferencesStream = Services.db
          .streamNotificationPreferences(chartId);
    }
    return _notificationPreferencesStream!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Services.notifications.setupFcmPushNotifications();
    _cyclesStream = Services.db.streamCycles();
    _cyclesSubscription = _cyclesStream.listen((cycles) {
      _syncReminderStatus(cycles);
    }, onError: (_) {});
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

  Cycle? _findLatestCycle(List<Cycle> cycles) {
    if (cycles.isEmpty) return null;
    return cycles.reduce((a, b) => a.startDate.isAfter(b.startDate) ? a : b);
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
    final latestCycle = _findLatestCycle(cycles);
    _maybeNotifyBreastSelfExam(chartId, latestCycle, now);
  }

  Future<void> _syncDailyLoggingReminder(
    String chartId,
    bool isTodayLogged,
    DateTime now,
  ) async {
    try {
      final cached = Services.db.getLatestNotificationPreferences(chartId);
      final enabled =
          cached?.dailyLoggingReminder ??
          (await _getNotificationPreferencesStream(
            chartId,
          ).first).dailyLoggingReminder;

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
    Cycle? latestCycle,
    DateTime now,
  ) async {
    if (latestCycle == null) return;
    final today = DateTime(now.year, now.month, now.day);
    final currentDay = calendarDaysBetween(latestCycle.startDate, today) + 1;
    if (currentDay != 7) return;

    try {
      final prefs =
          Services.db.getLatestNotificationPreferences(chartId) ??
          await _getNotificationPreferencesStream(chartId).first;
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
        defaultDate: widget.todayOverride ?? DateTime.now(),
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
        final latestCycle = _findLatestCycle(cycles);
        final now = widget.todayOverride ?? DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final bool isDay7 =
            latestCycle != null &&
            calendarDaysBetween(latestCycle.startDate, today) + 1 == 7;

        final chartId = Services.db.currentChartId;
        final isWide = isWideScreen(context);
        final content = Column(
          children: [
            if (isDay7 && chartId != null && _viewMode != ViewMode.supplements)
              StreamBuilder<NotificationPreferences>(
                stream: _getNotificationPreferencesStream(chartId),
                initialData: Services.db.getLatestNotificationPreferences(
                  chartId,
                ),
                builder: (context, prefSnap) {
                  final prefs =
                      prefSnap.data ?? const NotificationPreferences();
                  if (!prefs.breastSelfExamReminder) {
                    return const SizedBox.shrink();
                  }
                  return const Day7BseBanner();
                },
              ),
            Expanded(
              child: _viewMode == ViewMode.observations
                  ? ObservationsScreen(
                      cycles: cycles,
                      onSelectEntry: (entry, cycle) =>
                          _showDailyDetailSheet(context, entry, cycle),
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
                          _showDailyDetailSheet(context, entry, cycle),
                      onAddForDate: (cycle, date) =>
                          _showAddObservationDialogForDate(
                            context,
                            cycle,
                            date,
                          ),
                    )
                  : SupplementScreen(
                      initialDate: widget.todayOverride,
                      activeCycle: latestCycle,
                    ),
            ),
          ],
        );

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
                          builder: (context) =>
                              SettingsScreen(activeCycle: latestCycle),
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
          drawer: DashboardDrawer(
            onNavigateToCharts: () {
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
            onSelectSupplements: () {
              Navigator.pop(context); // Close drawer
              setState(() {
                _viewMode = ViewMode.supplements;
              });
              _routeManager.updateUrlPath(ViewMode.supplements);
            },
            onNavigateToSettings: () {
              Navigator.pop(context); // Close drawer
              _routeManager.updateUrlPathRaw('/settings');
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/settings'),
                      builder: (context) =>
                          SettingsScreen(activeCycle: latestCycle),
                    ),
                  )
                  .then((_) {
                    if (!mounted) return;
                    _routeManager.updateUrlPath(_viewMode);
                  });
            },
            onSignOut: () async {
              await Services.db.signOut();
            },
          ),
          body: GestureDetector(
            onTap: _isSpeedDialOpen ? _closeSpeedDial : null,
            behavior: HitTestBehavior.opaque,
            child: (cycles.isEmpty && _viewMode != ViewMode.supplements)
                ? EmptyDashboardView(
                    onLogFirstObservation: () =>
                        _showAddObservationDialog(context, null),
                  )
                : (isWide
                      ? Row(
                          children: [
                            NavigationRail(
                              selectedIndex: _viewMode.index,
                              onDestinationSelected: (index) {
                                final newMode = ViewMode.values[index];
                                setState(() {
                                  _viewMode = newMode;
                                });
                                _routeManager.updateUrlPath(newMode);
                              },
                              labelType: NavigationRailLabelType.all,
                              destinations: const [
                                NavigationRailDestination(
                                  icon: Icon(Icons.list_alt_outlined),
                                  selectedIcon: Icon(Icons.list_alt),
                                  label: Text('Observations'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.grid_on_outlined),
                                  selectedIcon: Icon(Icons.grid_on),
                                  label: Text('Chart'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.medication_outlined),
                                  selectedIcon: Icon(Icons.medication),
                                  label: Text('Supplements'),
                                ),
                              ],
                            ),
                            const VerticalDivider(thickness: 1, width: 1),
                            Expanded(child: content),
                          ],
                        )
                      : content),
          ),
          bottomNavigationBar:
              (isWide || (cycles.isEmpty && _viewMode != ViewMode.supplements))
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
              : ObservationSpeedDialFab(
                  isOpen: _isSpeedDialOpen,
                  onToggle: _toggleSpeedDial,
                  onSelectCategory: (category) =>
                      _showAddObservationDialogCategory(
                        context,
                        latestCycle,
                        category,
                      ),
                ),
        );
      },
    );
  }
}
