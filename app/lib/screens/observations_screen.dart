import 'package:flutter/material.dart';

import '../logic/logic.dart';
import '../widgets/cycle_options_dialog.dart';
import '../widgets/timeline/timeline.dart';

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
  final DateTime? todayOverride;

  const ObservationsScreen({
    super.key,
    required this.cycles,
    required this.onSelectEntry,
    required this.onAddForDate,
    this.todayOverride,
  });

  @override
  Widget build(BuildContext context) {
    final now = todayOverride ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final timelineItems = <_ObservationsItem>[];

    // Sort cycles chronologically (oldest first) to accurately construct timeline day numbers
    final sortedCycles = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    for (int c = 0; c < sortedCycles.length; c++) {
      final cycle = sortedCycles[c];
      final cycleStart = DateTime(
        cycle.startDate.year,
        cycle.startDate.month,
        cycle.startDate.day,
      );

      // Determine end date for this cycle
      final DateTime cycleEnd;
      if (c < sortedCycles.length - 1) {
        final nextStart = sortedCycles[c + 1].startDate;
        cycleEnd = DateTime(
          nextStart.year,
          nextStart.month,
          nextStart.day,
        ).subtractCalendarDays(1);
      } else {
        // Active/latest cycle ends at max(today, maxEntryDate)
        DateTime maxEntryDate = cycleStart;
        for (final entry in cycle.sortedEntries) {
          final entryDate = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          if (entryDate.isAfter(maxEntryDate)) {
            maxEntryDate = entryDate;
          }
        }
        cycleEnd = maxEntryDate.isAfter(today) ? maxEntryDate : today;
      }

      int totalDays = calendarDaysBetween(cycleStart, cycleEnd);
      if (totalDays < 0) totalDays = 0;

      for (int dayOffset = 0; dayOffset <= totalDays; dayOffset++) {
        final date = cycleStart.addCalendarDays(dayOffset);
        final dateKey = date.dateKey;
        final entry = cycle.dailyEntries[dateKey];

        timelineItems.add(
          _ObservationsItem(
            date: date,
            entry: entry,
            cycle: cycle,
            dayNumber: dayOffset + 1,
            isCycleStart: dayOffset == 0,
          ),
        );
      }
    }

    if (timelineItems.isEmpty) {
      timelineItems.add(
        _ObservationsItem(
          date: today,
          entry: null,
          cycle: null,
          dayNumber: 1,
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

        final isMonthStart =
            index == reversedItems.length - 1 ||
            reversedItems[index + 1].date.year != item.date.year ||
            reversedItems[index + 1].date.month != item.date.month;

        final timelineRowWidget = IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TimelineTrackNode(
                stampType: entry?.stampType,
                peakDayLabel: entry?.peakDayLabel,
                dayNumber: item.dayNumber,
                onTap: item.cycle != null
                    ? () {
                        CycleOptionsDialog.show(
                          context,
                          cycle: item.cycle!,
                          cycles: cycles,
                          targetDate: item.date,
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimelineItemCard(
                  date: item.date,
                  entry: entry,
                  cycle: item.cycle,
                  dayNumber: item.dayNumber,
                  isCycleStart: item.isCycleStart,
                  isToday: isToday,
                  onTap: () {
                    if (entry != null && item.cycle != null) {
                      onSelectEntry(entry, item.cycle!);
                    } else {
                      onAddForDate(item.cycle, item.date);
                    }
                  },
                  onCycleOptionsTap: item.cycle != null
                      ? () => CycleOptionsDialog.show(
                          context,
                          cycle: item.cycle!,
                          cycles: cycles,
                          targetDate: item.date,
                        )
                      : null,
                ),
              ),
            ],
          ),
        );

        if (isMonthStart) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimelineMonthHeader(date: item.date),
              timelineRowWidget,
            ],
          );
        }

        return timelineRowWidget;
      },
    );
  }
}
