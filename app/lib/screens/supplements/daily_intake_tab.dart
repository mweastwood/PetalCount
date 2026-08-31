import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class DailyIntakeTab extends StatelessWidget {
  final DateTime selectedDate;
  final Cycle? cycle;
  final int cycleDay;
  final int? daysPastPeak;
  final bool hasPeakOccurred;
  final List<SupplementItem> supplements;
  final DailySupplementLog dailyLog;
  final ValueChanged<int>? onDateChanged;
  final VoidCallback? onGoToToday;
  final void Function(
    SupplementItem item,
    SupplementTimeOfDay time,
    bool taken,
  )?
  onToggleDose;

  const DailyIntakeTab({
    super.key,
    required this.selectedDate,
    this.cycle,
    required this.cycleDay,
    this.daysPastPeak,
    required this.hasPeakOccurred,
    required this.supplements,
    required this.dailyLog,
    this.onDateChanged,
    this.onGoToToday,
    this.onToggleDose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        _buildDateNavigatorCard(theme),
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
          );
        }),
      ],
    );
  }

  Widget _buildDateNavigatorCard(ThemeData theme) {
    final dateStr = AppDateFormats.shortMonthDayYear.format(selectedDate);
    final isToday = DateTime.now().dateKey == selectedDate.dateKey;

    String cycleStatus = 'Cycle Day $cycleDay';
    if (daysPastPeak != null) {
      if (daysPastPeak == 0) {
        cycleStatus += ' • Peak Day (P)';
      } else if (daysPastPeak! > 0) {
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
              onPressed: onDateChanged != null
                  ? () => onDateChanged!(-1)
                  : null,
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
                onPressed: onGoToToday,
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Day',
              onPressed: onDateChanged != null ? () => onDateChanged!(1) : null,
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
                  if (onToggleDose != null) {
                    onToggleDose!(item, time, !isTaken);
                  } else {
                    Services.db.logSupplementDose(
                      date: selectedDate,
                      supplementId: item.id,
                      timeOfDay: time,
                      taken: !isTaken,
                    );
                  }
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
                          if (onToggleDose != null) {
                            onToggleDose!(item, time, val ?? false);
                          } else {
                            Services.db.logSupplementDose(
                              date: selectedDate,
                              supplementId: item.id,
                              timeOfDay: time,
                              taken: val ?? false,
                            );
                          }
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
}
