import 'package:flutter/material.dart';

import '../logic/logic.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            final supplements =
                suppSnapshot.data ?? SupplementPresets.defaultList;

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
                            _showAddEditSupplementDialog(context, null);
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
                      _buildDailyIntakeTab(
                        context: context,
                        theme: theme,
                        supplements: supplements,
                        dailyLog: dailyLog,
                        cycle: activeCycle,
                        cycleDay: cycleDay,
                        daysPastPeak: daysPastPeak,
                        hasPeakOccurred: hasPeakOccurred,
                      ),
                      _buildCyclePlanTab(
                        context: context,
                        theme: theme,
                        supplements: supplements,
                        cycle: activeCycle,
                      ),
                      _buildFormularyTab(
                        context: context,
                        theme: theme,
                        supplements: supplements,
                      ),
                    ],
                  ),
                  floatingActionButton: _tabController.index == 2
                      ? FloatingActionButton.extended(
                          key: const Key('btn_add_supplement_fab'),
                          onPressed: () =>
                              _showAddEditSupplementDialog(context, null),
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

  // --- TAB 1: DAILY INTAKE CHECKLIST ---
  Widget _buildDailyIntakeTab({
    required BuildContext context,
    required ThemeData theme,
    required List<SupplementItem> supplements,
    required DailySupplementLog dailyLog,
    required Cycle? cycle,
    required int cycleDay,
    required int? daysPastPeak,
    required bool hasPeakOccurred,
  }) {
    final activeSupplements = supplements
        .where(
          (s) => s.isScheduledFor(
            cycleDay: cycleDay,
            daysPastPeak: daysPastPeak,
            hasPeakOccurred: hasPeakOccurred,
          ),
        )
        .toList();

    int totalDoses = 0;
    int takenDoses = 0;

    for (final time in SupplementTimeOfDay.values) {
      for (final supp in activeSupplements) {
        if (supp.doseForTime(time) > 0) {
          totalDoses++;
          if (dailyLog.isTaken(supp.id, time)) {
            takenDoses++;
          }
        }
      }
    }

    final progress = totalDoses > 0 ? (takenDoses / totalDoses) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Date Navigator Card
        _buildDateNavigatorCard(theme, cycle, cycleDay, daysPastPeak),
        const SizedBox(height: 12),

        // Adherence Progress Card
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Adherence',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$takenDoses / $totalDoses taken',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: takenDoses == totalDoses && totalDoses > 0
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      takenDoses == totalDoses && totalDoses > 0
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Time of Day Sections
        ...SupplementTimeOfDay.values.map((time) {
          final itemsForTime = activeSupplements
              .where((s) => s.doseForTime(time) > 0)
              .toList();

          return _buildTimeOfDaySection(
            context: context,
            theme: theme,
            time: time,
            items: itemsForTime,
            dailyLog: dailyLog,
          );
        }),
      ],
    );
  }

  Widget _buildDateNavigatorCard(
    ThemeData theme,
    Cycle? cycle,
    int cycleDay,
    int? daysPastPeak,
  ) {
    final dateStr = AppDateFormats.shortMonthDayYear.format(_selectedDate);
    final isToday = DateTime.now().dateKey == _selectedDate.dateKey;

    String cycleStatus = 'Cycle Day $cycleDay';
    if (daysPastPeak != null) {
      if (daysPastPeak == 0) {
        cycleStatus += ' • Peak Day (P)';
      } else if (daysPastPeak > 0) {
        cycleStatus += ' • Post-Peak (P+$daysPastPeak)';
      } else {
        cycleStatus += ' • Pre-Peak (P$daysPastPeak)';
      }
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Day',
              onPressed: () => _changeDate(-1),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'TODAY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cycleStatus,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isToday)
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Go to Today',
                onPressed: _goToToday,
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Day',
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOfDaySection({
    required BuildContext context,
    required ThemeData theme,
    required SupplementTimeOfDay time,
    required List<SupplementItem> items,
    required DailySupplementLog dailyLog,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Text(time.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                time.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${items.where((i) => dailyLog.isTaken(i.id, time)).length} / ${items.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Center(
                child: Text(
                  'No ${time.label.toLowerCase()} supplements scheduled for this phase.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final isTaken = dailyLog.isTaken(item.id, time);
            final dose = item.doseForTime(time);

            return Card(
              elevation: isTaken ? 0 : 1,
              color: isTaken
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surface,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isTaken
                      ? Colors.green.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Services.db.logSupplementDose(
                    date: _selectedDate,
                    supplementId: item.id,
                    timeOfDay: time,
                    taken: !isTaken,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isTaken,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          Services.db.logSupplementDose(
                            date: _selectedDate,
                            supplementId: item.id,
                            timeOfDay: time,
                            taken: val ?? false,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: isTaken
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isTaken
                                    ? theme.colorScheme.outline
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dose × ${item.quantity}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (item.takeWithFood)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '🍽️ With food',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Empty stomach / Any',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.scheduleDescription,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
      ],
    );
  }

  // --- TAB 2: CYCLE PLAN SPREADSHEET MATRIX ---
  Widget _buildCyclePlanTab({
    required BuildContext context,
    required ThemeData theme,
    required List<SupplementItem> supplements,
    required Cycle? cycle,
  }) {
    const totalCycleDays = 35;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Text(
          'Cycle Protocol Matrix',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Schedule of prescribed supplements across cycle days 1 to $totalCycleDays.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...SupplementTimeOfDay.values.map((time) {
          final itemsWithDose = supplements
              .where((s) => s.doseForTime(time) > 0)
              .toList();

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(time.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '${time.label} Schedule',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 38,
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 44,
                      columnSpacing: 16,
                      columns: [
                        const DataColumn(
                          label: Text(
                            'Supplement',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Dose',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Schedule Rule',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...List.generate(totalCycleDays, (i) {
                          final day = i + 1;
                          return DataColumn(
                            label: Text(
                              'D$day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }),
                      ],
                      rows: itemsWithDose.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text(item.quantity)),
                            DataCell(Text(item.scheduleDescription)),
                            ...List.generate(totalCycleDays, (i) {
                              final day = i + 1;
                              final isActive = item.isScheduledFor(
                                cycleDay: day,
                              );
                              return DataCell(
                                Center(
                                  child: isActive
                                      ? Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green.shade600,
                                        )
                                      : Icon(
                                          Icons.remove,
                                          size: 14,
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 3: FORMULARY INSTRUCTIONS MANAGER ---
  Widget _buildFormularyTab({
    required BuildContext context,
    required ThemeData theme,
    required List<SupplementItem> supplements,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: supplements.map((item) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quantity: ${item.quantity}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit Supplement',
                      onPressed: () =>
                          _showAddEditSupplementDialog(context, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.error,
                      tooltip: 'Delete Supplement',
                      onPressed: () =>
                          _showDeleteSupplementDialog(context, item),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (item.takesInMorning)
                      _buildDoseBadge(
                        '🌅 Morning (${item.morningDose})',
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.onPrimaryContainer,
                      ),
                    if (item.takesInAfternoon)
                      _buildDoseBadge(
                        '☀️ Afternoon (${item.afternoonDose})',
                        theme.colorScheme.secondaryContainer,
                        theme.colorScheme.onSecondaryContainer,
                      ),
                    if (item.takesInEvening)
                      _buildDoseBadge(
                        '🌙 Evening (${item.eveningDose})',
                        theme.colorScheme.tertiaryContainer,
                        theme.colorScheme.onTertiaryContainer,
                      ),
                    if (item.takeWithFood)
                      _buildDoseBadge(
                        '🍽️ Take with food',
                        Colors.amber.shade100,
                        Colors.amber.shade900,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Schedule: ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.scheduleDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.instructions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.instructions,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDoseBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // --- DIALOGS ---
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

  void _showAddEditSupplementDialog(
    BuildContext context,
    SupplementItem? existing,
  ) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final quantityCtrl = TextEditingController(text: existing?.quantity ?? '');
    final instructionsCtrl = TextEditingController(
      text: existing?.instructions ?? '',
    );
    bool takeWithFood = existing?.takeWithFood ?? false;
    int morningDose = existing?.morningDose ?? 1;
    int afternoonDose = existing?.afternoonDose ?? 0;
    int eveningDose = existing?.eveningDose ?? 0;
    SupplementScheduleRuleType ruleType =
        existing?.ruleType ?? SupplementScheduleRuleType.allDays;
    final startDayCtrl = TextEditingController(
      text: existing?.startCycleDay?.toString() ?? '',
    );
    final endDayCtrl = TextEditingController(
      text: existing?.endCycleDay?.toString() ?? '',
    );
    final startPeakCtrl = TextEditingController(
      text: existing?.startPeakOffset?.toString() ?? '',
    );
    final endPeakCtrl = TextEditingController(
      text: existing?.endPeakOffset?.toString() ?? '',
    );
    final durationCtrl = TextEditingController(
      text: existing?.durationDays?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Add Supplement' : 'Edit Supplement',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Supplement Name *',
                      hintText: 'e.g. CoQ10, Prenatal, Clomid',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosage / Quantity *',
                      hintText: 'e.g. 200 mg, 1 tablet, 2 g',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Take with food?'),
                    subtitle: const Text('Required with meals for absorption'),
                    value: takeWithFood,
                    onChanged: (val) {
                      setDialogState(() {
                        takeWithFood = val;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  Text(
                    'Daily Doses',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDoseRow(
                    label: '🌅 Morning Dose',
                    count: morningDose,
                    onChanged: (val) => setDialogState(() => morningDose = val),
                  ),
                  _buildDoseRow(
                    label: '☀️ Afternoon Dose',
                    count: afternoonDose,
                    onChanged: (val) =>
                        setDialogState(() => afternoonDose = val),
                  ),
                  _buildDoseRow(
                    label: '🌙 Evening Dose',
                    count: eveningDose,
                    onChanged: (val) => setDialogState(() => eveningDose = val),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Cycle Schedule Rule',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SupplementScheduleRuleType>(
                    initialValue: ruleType,
                    decoration: const InputDecoration(
                      labelText: 'Schedule Window',
                    ),
                    items: SupplementScheduleRuleType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          ruleType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (ruleType == SupplementScheduleRuleType.cycleDays) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startDayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Start Cycle Day',
                              hintText: 'e.g. 4',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endDayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'End Cycle Day',
                              hintText: 'e.g. 8',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (ruleType ==
                      SupplementScheduleRuleType.peakOffset) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startPeakCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Peak Offset (e.g. 3 for P+3)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (Days)',
                              hintText: 'e.g. 10',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: startDayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fallback Start Cycle Day (if no peak)',
                        hintText: 'e.g. 21',
                      ),
                    ),
                  ] else if (ruleType ==
                      SupplementScheduleRuleType.cycleDaysOrPeak) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startDayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Start Cycle Day',
                              hintText: 'e.g. 8',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endPeakCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'End Peak Offset',
                              hintText: 'e.g. 1 for P+1',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: endDayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fallback End Cycle Day (if no peak)',
                        hintText: 'e.g. 19',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: instructionsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes / Instructions',
                      hintText: 'e.g. Take with dinner, sustained release',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final quantity = quantityCtrl.text.trim();
                  if (name.isEmpty || quantity.isEmpty) {
                    return;
                  }

                  final id =
                      existing?.id ??
                      'supp_${DateTime.now().millisecondsSinceEpoch}';
                  final item = SupplementItem(
                    id: id,
                    name: name,
                    quantity: quantity,
                    takeWithFood: takeWithFood,
                    morningDose: morningDose,
                    afternoonDose: afternoonDose,
                    eveningDose: eveningDose,
                    ruleType: ruleType,
                    startCycleDay: int.tryParse(startDayCtrl.text.trim()),
                    endCycleDay: int.tryParse(endDayCtrl.text.trim()),
                    startPeakOffset: int.tryParse(startPeakCtrl.text.trim()),
                    endPeakOffset: int.tryParse(endPeakCtrl.text.trim()),
                    durationDays: int.tryParse(durationCtrl.text.trim()),
                    instructions: instructionsCtrl.text.trim(),
                    isActive: existing?.isActive ?? true,
                  );

                  Navigator.pop(context);
                  await Services.db.saveSupplement(item);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDoseRow({
    required String label,
    required int count,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 14),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: count > 0 ? () => onChanged(count - 1) : null,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 14),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => onChanged(count + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
