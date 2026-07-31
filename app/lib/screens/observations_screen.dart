import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic/logic.dart';

class _ObservationsItem {
  final DateTime date;
  final DailyEntry? entry;
  final Cycle? cycle;
  final int dayNumber;
  final bool isCycleStart;

  _ObservationsItem({
    required this.date,
    required this.entry,
    required this.cycle,
    required this.dayNumber,
    required this.isCycleStart,
  });
}

class ObservationsScreen extends StatelessWidget {
  final List<Cycle> cycles;
  final void Function(DailyEntry entry, Cycle cycle) onSelectEntry;
  final void Function(Cycle? cycle, DateTime date) onAddForDate;

  const ObservationsScreen({
    super.key,
    required this.cycles,
    required this.onSelectEntry,
    required this.onAddForDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineItems = <_ObservationsItem>[];

    for (var cycle in cycles) {
      final sortedEntries = cycle.sortedEntries;

      if (sortedEntries.isNotEmpty) {
        for (int i = 0; i < sortedEntries.length; i++) {
          final entry = sortedEntries[i];
          timelineItems.add(
            _ObservationsItem(
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
          _ObservationsItem(
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
        _ObservationsItem(
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
                  onSelectEntry(entry, item.cycle!);
                } else {
                  onAddForDate(item.cycle, item.date);
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
}
