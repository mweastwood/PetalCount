import 'package:flutter/material.dart';

import '../logic/logic.dart';
import 'supplements/supplements.dart';

class SupplementScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Cycle? activeCycle;

  const SupplementScreen({super.key, this.initialDate, this.activeCycle});

  @override
  State<SupplementScreen> createState() => _SupplementScreenState();
}

class _SupplementScreenState extends State<SupplementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeDate(int offset) {
    setState(() {
      _selectedDate = _selectedDate.addCalendarDays(offset);
    });
  }

  void _goToToday() {
    final now = widget.initialDate ?? DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  Cycle? _findCycleForDate(List<Cycle> cycles, DateTime date) {
    final sorted = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (!sorted[i].startDate.isAfter(date)) {
        return sorted[i];
      }
    }
    return sorted.isNotEmpty ? sorted.last : null;
  }

  int _calculateCycleDay(Cycle? cycle, DateTime date) {
    if (cycle == null) return 1;
    return calendarDaysBetween(cycle.startDate, date) + 1;
  }

  int? _calculateDaysPastPeak(Cycle? cycle, DateTime date) {
    if (cycle == null) return null;
    DateTime? peakDate;
    for (final entry in cycle.sortedEntries) {
      if (entry.isPeakDay) {
        peakDate = entry.date;
        break;
      }
    }
    if (peakDate == null) return null;
    return calendarDaysBetween(peakDate, date);
  }

  void _showResetPresetsConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Supplement Presets?'),
        content: const Text(
          'This will reset your supplement list to the 14 standard Creighton / NaPro prescription and supplement instructions from your chart formulary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await Services.db.resetDefaultSupplements();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplements reset to standard presets.'),
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSupplementDialog(BuildContext context, SupplementItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text(
          'Are you sure you want to remove this supplement from your formulary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await Services.db.deleteSupplement(item.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Cycle>>(
      stream: Services.db.streamCycles(),
      builder: (context, cycleSnapshot) {
        final cycles = cycleSnapshot.data ?? [];
        final activeCycle =
            _findCycleForDate(cycles, _selectedDate) ?? widget.activeCycle;
        final cycleDay = _calculateCycleDay(activeCycle, _selectedDate);
        final daysPastPeak = _calculateDaysPastPeak(activeCycle, _selectedDate);
        final hasPeakOccurred = daysPastPeak != null;

        return StreamBuilder<List<SupplementItem>>(
          stream: Services.db.streamSupplements(),
          builder: (context, suppSnapshot) {
            final supplements = suppSnapshot.data ?? [];

            return StreamBuilder<Map<String, DailySupplementLog>>(
              stream: Services.db.streamDailySupplementLogs(),
              builder: (context, logSnapshot) {
                final logs = logSnapshot.data ?? {};
                final dateKey = _selectedDate.dateKey;
                final dailyLog =
                    logs[dateKey] ??
                    DailySupplementLog(date: _selectedDate, takenDoses: {});

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Supplements & Protocols'),
                    bottom: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.check_circle_outline),
                          text: 'Daily Intake',
                        ),
                        Tab(
                          icon: Icon(Icons.calendar_view_week),
                          text: 'Cycle Plan',
                        ),
                        Tab(
                          icon: Icon(Icons.medication_outlined),
                          text: 'Formulary',
                        ),
                      ],
                    ),
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'reset') {
                            _showResetPresetsConfirmation(context);
                          } else if (value == 'add') {
                            AddEditSupplementDialog.show(context);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add',
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('Add Supplement'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(Icons.restore, size: 20),
                                SizedBox(width: 8),
                                Text('Reset Default Presets'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      DailyIntakeTab(
                        selectedDate: _selectedDate,
                        cycle: activeCycle,
                        cycleDay: cycleDay,
                        daysPastPeak: daysPastPeak,
                        hasPeakOccurred: hasPeakOccurred,
                        supplements: supplements,
                        dailyLog: dailyLog,
                        onDateChanged: _changeDate,
                        onGoToToday: _goToToday,
                      ),
                      CyclePlanTab(
                        supplements: supplements,
                        cycle: activeCycle,
                      ),
                      FormularyTab(
                        supplements: supplements,
                        onEdit: (item) =>
                            AddEditSupplementDialog.show(context, item),
                        onDelete: (item) =>
                            _showDeleteSupplementDialog(context, item),
                      ),
                    ],
                  ),
                  floatingActionButton: _tabController.index == 2
                      ? FloatingActionButton.extended(
                          key: const Key('btn_add_supplement_fab'),
                          onPressed: () =>
                              AddEditSupplementDialog.show(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Supplement'),
                        )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}
