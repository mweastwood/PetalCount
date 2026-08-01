import 'package:flutter/material.dart';
import '../logic/logic.dart';
import '../widgets/add_observation_dialog.dart';
import '../widgets/daily_detail_sheet.dart';
import 'chart_screen.dart';
import 'chart_selection_screen.dart';
import 'observations_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Uri? mockUri;
  const DashboardScreen({super.key, this.mockUri});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<List<Cycle>> _cyclesStream;
  late final AppRouteManager _routeManager;
  ViewMode _viewMode = ViewMode.observations;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _cyclesStream = Services.db.streamCycles();
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Petal Count'),
            leading: IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch Chart',
              onPressed: () {
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
          body: GestureDetector(
            onTap: _isSpeedDialOpen ? _closeSpeedDial : null,
            behavior: HitTestBehavior.opaque,
            child: cycles.isEmpty
                ? _buildNoCyclesView(context)
                : (_viewMode == ViewMode.observations
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
                        )
                      : ChartScreen(
                          cycles: cycles,
                          onSelectEntry: (entry, cycle) =>
                              _showDailyDetailSheet(context, entry, cycle),
                          onAddForDate: (cycle, date) =>
                              _showAddObservationDialogForDate(
                                context,
                                cycle,
                                date,
                              ),
                        )),
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
                  ],
                ),
          floatingActionButton: _buildSpeedDialFab(
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
}
