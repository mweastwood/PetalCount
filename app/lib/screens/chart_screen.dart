import 'package:flutter/material.dart';

import '../logic/logic.dart';
import '../theme/theme.dart';
import '../widgets/chart/chart_horizontal_spreadsheet.dart';
import '../widgets/chart/chart_vertical_spreadsheet.dart';

class ChartScreen extends StatelessWidget {
  final List<Cycle> cycles;
  final void Function(DailyEntry entry, Cycle cycle) onSelectEntry;
  final void Function(Cycle? cycle, DateTime date) onAddForDate;

  const ChartScreen({
    super.key,
    required this.cycles,
    required this.onSelectEntry,
    required this.onAddForDate,
  });

  static const double kCellWidth = CreightonTheme.cellWidth;
  static const double kCellHeight = CreightonTheme.cellHeight;
  static const double kHeaderRowHeight = CreightonTheme.headerRowHeight;
  static const double kMobileHeaderRowHeight =
      CreightonTheme.mobileHeaderRowHeight;
  static const double kCycleHeaderWidth = CreightonTheme.cycleHeaderWidth;
  static const double kCellGap = CreightonTheme.cellGap;

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) {
      return const Center(
        child: Text('No cycles available. Log an observation to begin.'),
      );
    }

    // Determine the maximum number of days to display across all cycles (at least 35 days)
    final int maxDays = Cycle.calculateMaxDisplayDays(cycles);
    final displayDaysMap = computeDisplayDaysMap(cycles, maxDays);

    final media = MediaQuery.of(context);
    final isNarrow =
        media.size.width < media.size.height || media.size.width < 600;

    if (isNarrow) {
      return ChartVerticalSpreadsheet(
        cycles: cycles,
        maxDays: maxDays,
        displayDaysMap: displayDaysMap,
        onSelectEntry: onSelectEntry,
        onAddForDate: onAddForDate,
      );
    } else {
      return ChartHorizontalSpreadsheet(
        cycles: cycles,
        maxDays: maxDays,
        displayDaysMap: displayDaysMap,
        onSelectEntry: onSelectEntry,
        onAddForDate: onAddForDate,
      );
    }
  }

  /// Computes a map of cycle ID to the number of days to display for that cycle.
  ///
  /// Pre-computes display days in a single O(N log N) pass:
  /// - Cycles with an `endDate` are displayed up to their end date (or `maxDays`).
  /// - Cycles without an `endDate` that are followed by another cycle are displayed up to the next cycle's start date (or `maxDays`).
  /// - The latest open cycle defaults to `maxDays`.
  @visibleForTesting
  static Map<String, int> computeDisplayDaysMap(
    List<Cycle> cycles,
    int maxDays,
  ) {
    if (cycles.isEmpty) return const {};

    final sortedCycles = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final map = <String, int>{};
    for (int i = 0; i < sortedCycles.length; i++) {
      final cycle = sortedCycles[i];
      if (cycle.endDate != null) {
        final endDays =
            calendarDaysBetween(cycle.startDate, cycle.endDate!) + 1;
        map[cycle.id] = endDays < maxDays ? endDays : maxDays;
      } else if (i < sortedCycles.length - 1) {
        final nextCycle = sortedCycles[i + 1];
        final daysToNext = calendarDaysBetween(
          cycle.startDate,
          nextCycle.startDate,
        );
        if (daysToNext > 0) {
          map[cycle.id] = daysToNext < maxDays ? daysToNext : maxDays;
        } else {
          map[cycle.id] = maxDays;
        }
      } else {
        map[cycle.id] = maxDays;
      }
    }
    return map;
  }
}
