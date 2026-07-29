import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic/logic.dart';
import '../widgets/add_observation_dialog.dart';
import '../widgets/daily_detail_sheet.dart';
import 'chart_selection_screen.dart';
import 'settings_screen.dart';

enum ViewMode { timeline, creightonGrid }

class _TimelineItem {
  final DateTime date;
  final DailyEntry? entry;
  final Cycle? cycle;
  final int dayNumber;
  final bool isCycleStart;

  _TimelineItem({
    required this.date,
    required this.entry,
    required this.cycle,
    required this.dayNumber,
    required this.isCycleStart,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<List<Cycle>> _cyclesStream;
  ViewMode _viewMode = ViewMode.timeline;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _cyclesStream = Services.db.streamCycles();
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

  // --- VIEW MODE 1: VERTICAL TIMELINE VIEW ---
  Widget _buildVerticalTimelineView(BuildContext context, List<Cycle> cycles) {
    final theme = Theme.of(context);

    final timelineItems = <_TimelineItem>[];

    for (var cycle in cycles) {
      final sortedEntries = cycle.sortedEntries;

      if (sortedEntries.isNotEmpty) {
        for (int i = 0; i < sortedEntries.length; i++) {
          final entry = sortedEntries[i];
          timelineItems.add(
            _TimelineItem(
              date: entry.date,
              entry: entry,
              cycle: cycle,
              dayNumber: i + 1,
              isCycleStart: i == 0,
            ),
          );
        }
      } else {
        timelineItems.add(
          _TimelineItem(
            date: cycle.startDate,
            entry: null,
            cycle: cycle,
            dayNumber: 1,
            isCycleStart: true,
          ),
        );
      }
    }

    final DateTime today;
    if (timelineItems.isNotEmpty) {
      DateTime maxDate = timelineItems.first.date;
      for (final item in timelineItems) {
        if (item.date.isAfter(maxDate)) {
          maxDate = item.date;
        }
      }
      today = DateTime(maxDate.year, maxDate.month, maxDate.day);
    } else {
      final now = DateTime.now();
      today = DateTime(now.year, now.month, now.day);
    }

    final hasToday = timelineItems.any(
      (item) =>
          item.date.year == today.year &&
          item.date.month == today.month &&
          item.date.day == today.day,
    );

    if (!hasToday) {
      final activeCycle = cycles.isNotEmpty ? cycles.first : null;
      int dayNum = 1;
      if (activeCycle != null) {
        dayNum = today.difference(activeCycle.startDate).inDays + 1;
      }
      timelineItems.add(
        _TimelineItem(
          date: today,
          entry: null,
          cycle: activeCycle,
          dayNumber: dayNum > 0 ? dayNum : 1,
          isCycleStart: false,
        ),
      );
    }

    timelineItems.sort((a, b) => a.date.compareTo(b.date));
    final reversedItems = timelineItems.reversed.toList();

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
      itemCount: reversedItems.length,
      itemBuilder: (context, index) {
        final item = reversedItems[index];
        final entry = item.entry;
        final isToday =
            item.date.year == today.year &&
            item.date.month == today.month &&
            item.date.day == today.day;

        Color stampColor = theme.colorScheme.surfaceContainerLowest;
        Color borderColor = theme.colorScheme.outlineVariant;
        IconData? stampIcon;
        Color stampIconColor = Colors.black87;

        if (entry != null) {
          borderColor = Colors.grey.shade400;
          switch (entry.stampType) {
            case StampType.red:
              stampColor = Colors.red.shade400;
              break;
            case StampType.green:
              stampColor = Colors.green.shade400;
              break;
            case StampType.whiteBaby:
              stampColor = Colors.white;
              borderColor = Colors.green.shade600;
              stampIcon = Icons.child_care;
              stampIconColor = Colors.green.shade700;
              break;
            case StampType.greenBaby:
              stampColor = Colors.green.shade400;
              stampIcon = Icons.child_care;
              stampIconColor = Colors.white;
              break;
            case StampType.yellow:
              stampColor = Colors.yellow.shade400;
              break;
            case StampType.yellowBaby:
              stampColor = Colors.yellow.shade400;
              stampIcon = Icons.child_care;
              stampIconColor = Colors.green.shade800;
              break;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: isToday
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isToday ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (entry != null && item.cycle != null) {
                  _showDailyDetailSheet(context, entry, item.cycle!);
                } else {
                  _showAddObservationDialogForDate(
                    context,
                    item.cycle,
                    item.date,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Stamp Cell
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: stampColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (entry?.peakDayLabel != null &&
                              entry!.peakDayLabel!.isNotEmpty)
                            Positioned(
                              top: 2,
                              right: 4,
                              child: Text(
                                entry.peakDayLabel!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: entry.peakDayLabel == 'P'
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          if (stampIcon != null)
                            Icon(stampIcon, size: 24, color: stampIconColor)
                          else
                            Text(
                              '${item.dayNumber}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    entry != null &&
                                        entry.stampType != StampType.whiteBaby
                                    ? Colors.white
                                    : Colors.grey.shade800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isToday
                                    ? 'Today – ${DateFormat('EEE, MMM dd').format(item.date)}'
                                    : DateFormat(
                                        'EEEE, MMM dd, yyyy',
                                      ).format(item.date),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isToday
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (item.isCycleStart) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Cycle starting ${DateFormat('MMMM dd, yyyy').format(item.date)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry != null
                                ? 'Day ${item.dayNumber} • ${entry.resolvedVdrsCode.isNotEmpty ? entry.resolvedVdrsCode : 'Logged'}${entry.comments.isNotEmpty ? ' • "${entry.comments}"' : ''}'
                                : 'Day ${item.dayNumber} • Tap to log observation',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: entry != null
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.outline,
                              fontStyle: entry == null
                                  ? FontStyle.italic
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- VIEW MODE 2: CLASSIC CREIGHTON MODEL GRID VIEW ---
  Widget _buildCreightonGridView(BuildContext context, List<Cycle> cycles) {
    final media = MediaQuery.of(context);
    final isNarrow =
        media.size.width < media.size.height || media.size.width < 600;

    if (isNarrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cycles.map((cycle) {
              return _buildVerticalCycleColumn(context, cycle);
            }).toList(),
          ),
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
        itemCount: cycles.length,
        itemBuilder: (context, index) {
          final cycle = cycles[index];
          return _buildHorizontalCycleRow(context, cycle);
        },
      );
    }
  }

  Widget _buildVerticalCycleColumn(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final totalCells = entries.length < 35 ? 35 : entries.length;

    return Container(
      width: 68,
      margin: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM dd').format(cycle.startDate),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${cycle.startDate.year}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(totalCells, (index) {
            DailyEntry? entry;
            if (index < entries.length) {
              entry = entries[index];
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildGridStampCell(context, entry, index + 1, cycle),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHorizontalCycleRow(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final totalCells = entries.length < 35 ? 35 : entries.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle starting ${DateFormat('MMMM dd, yyyy').format(cycle.startDate)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  tooltip: 'Export Cycle PDF',
                  onPressed: () => PdfExportService.exportCyclesToPdf([cycle]),
                ),
              ],
            ),
            Text(
              '${cycle.dailyEntries.length} entries logged  |  BIP: ${cycle.bipCodes.isEmpty ? 'None' : cycle.bipCodes.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(totalCells, (index) {
                  DailyEntry? entry;
                  if (index < entries.length) {
                    entry = entries[index];
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _buildGridStampCell(
                      context,
                      entry,
                      index + 1,
                      cycle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStampCell(
    BuildContext context,
    DailyEntry? entry,
    int dayNum,
    Cycle cycle,
  ) {
    final theme = Theme.of(context);

    Color stampColor = theme.colorScheme.surfaceContainerLowest;
    Color borderCol = theme.colorScheme.outlineVariant;
    bool hasBaby = false;
    bool hasGreenBaby = false;
    Color babyIconColor = Colors.black87;

    if (entry != null) {
      borderCol = Colors.grey.shade400;
      switch (entry.stampType) {
        case StampType.red:
          stampColor = Colors.red.shade400;
          break;
        case StampType.green:
          stampColor = Colors.green.shade400;
          break;
        case StampType.whiteBaby:
          stampColor = Colors.white;
          borderCol = Colors.green.shade600;
          hasBaby = true;
          babyIconColor = Colors.green.shade700;
          break;
        case StampType.greenBaby:
          stampColor = Colors.green.shade400;
          hasGreenBaby = true;
          break;
        case StampType.yellow:
          stampColor = Colors.yellow.shade400;
          break;
        case StampType.yellowBaby:
          stampColor = Colors.yellow.shade400;
          hasBaby = true;
          babyIconColor = Colors.green.shade800;
          break;
      }
    }

    final hasPain = entry != null && entry.painLevel > 0;
    final hasComments = entry != null && entry.comments.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (entry != null) {
          _showDailyDetailSheet(context, entry, cycle);
        } else {
          final mockDate = cycle.startDate.add(Duration(days: dayNum - 1));
          _showAddObservationDialogForDate(context, cycle, mockDate);
        }
      },
      child: Container(
        width: 58,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 18,
              alignment: Alignment.center,
              child: Text(
                entry?.peakDayLabel ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: entry?.peakDayLabel == 'P'
                      ? Colors.red
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(
                color: stampColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: borderCol,
                  width: entry != null ? 1.5 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 8,
                          color:
                              entry != null &&
                                  entry.stampType != StampType.whiteBaby
                              ? Colors.white70
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (hasBaby)
                    Icon(Icons.child_care, size: 24, color: babyIconColor)
                  else if (hasGreenBaby)
                    const Icon(Icons.child_care, size: 24, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry != null ? DateFormat('MMM dd').format(entry.date) : '-',
                style: const TextStyle(fontSize: 8, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              height: 24,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry?.resolvedVdrsCode ?? '',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              height: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasPain)
                    const Icon(
                      Icons.local_fire_department,
                      size: 10,
                      color: Colors.redAccent,
                    ),
                  if (hasComments) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.notes, size: 10, color: Colors.blueAccent),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChartSelectionScreen(),
                  ),
                );
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        activeCycle: cycles.isNotEmpty ? cycles.first : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: GestureDetector(
            onTap: _isSpeedDialOpen ? _closeSpeedDial : null,
            behavior: HitTestBehavior.opaque,
            child: cycles.isEmpty
                ? _buildNoCyclesView(context)
                : (_viewMode == ViewMode.timeline
                      ? _buildVerticalTimelineView(context, cycles)
                      : _buildCreightonGridView(context, cycles)),
          ),
          bottomNavigationBar: cycles.isEmpty
              ? null
              : NavigationBar(
                  selectedIndex: _viewMode.index,
                  onDestinationSelected: (index) {
                    setState(() {
                      _viewMode = ViewMode.values[index];
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.view_timeline_outlined),
                      selectedIcon: Icon(Icons.view_timeline),
                      label: 'Timeline',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_on_outlined),
                      selectedIcon: Icon(Icons.grid_on),
                      label: 'Creighton Grid',
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
