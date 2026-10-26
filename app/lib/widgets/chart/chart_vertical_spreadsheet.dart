import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import '../../theme/theme.dart';
import '../cycle_options_dialog.dart';
import 'chart_grid_stamp_cell.dart';

/// Narrow Screens (Portrait): Vertical Cycle Columns with a shared Day column on the left
class ChartVerticalSpreadsheet extends StatelessWidget {
  final List<Cycle> cycles;
  final int maxDays;
  final Map<String, int> displayDaysMap;
  final void Function(DailyEntry entry, Cycle cycle) onSelectEntry;
  final void Function(Cycle? cycle, DateTime date) onAddForDate;

  const ChartVerticalSpreadsheet({
    super.key,
    required this.cycles,
    required this.maxDays,
    required this.displayDaysMap,
    required this.onSelectEntry,
    required this.onAddForDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const kCellWidth = CreightonTheme.cellWidth;
    const kCellHeight = CreightonTheme.cellHeight;
    const kMobileHeaderRowHeight = CreightonTheme.mobileHeaderRowHeight;
    const kCellGap = CreightonTheme.cellGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 88.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Shared Day Column (Day 1, Day 2 ... Day N)
                    Column(
                      children: [
                        // Top-Left Corner Header Cell
                        Container(
                          width: 68.0,
                          height: kMobileHeaderRowHeight,
                          margin: const EdgeInsets.only(
                            bottom: kCellGap,
                            right: kCellGap,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Day',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        // Shared Day Labels (Day 1, Day 2, ... Day N)
                        ...List.generate(maxDays, (index) {
                          final dayNum = index + 1;
                          return Container(
                            width: 68.0,
                            height: kCellHeight,
                            margin: const EdgeInsets.only(
                              bottom: kCellGap,
                              right: kCellGap,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Day $dayNum',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    // Cycle Columns (Side-by-Side)
                    ...cycles.map((cycle) {
                      final displayDays = displayDaysMap[cycle.id] ?? maxDays;
                      return Container(
                        margin: const EdgeInsets.only(right: kCellGap),
                        child: Column(
                          children: [
                            // Column Top Header: Cycle Start Date, Year, Actions & Options
                            GestureDetector(
                              onTap: () => CycleOptionsDialog.show(
                                context,
                                cycle: cycle,
                                cycles: cycles,
                              ),
                              child: Container(
                                width: kCellWidth,
                                height: kMobileHeaderRowHeight,
                                margin: const EdgeInsets.only(bottom: kCellGap),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                  vertical: 3.0,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppDateFormats.shortMonthDay.format(
                                        cycle.startDate,
                                      ),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${cycle.startDate.year}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 9,
                                          ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            size: 14,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          style: IconButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: EdgeInsets.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          tooltip: 'Export Cycle PDF',
                                          onPressed: () =>
                                              PdfExportService.exportCyclesToPdf(
                                                [cycle],
                                              ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.settings_suggest,
                                            size: 14,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          style: IconButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: EdgeInsets.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          tooltip: 'Cycle Options',
                                          onPressed: () =>
                                              CycleOptionsDialog.show(
                                                context,
                                                cycle: cycle,
                                                cycles: cycles,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Cells for Day 1 .. Day N going DOWN
                            ...List.generate(displayDays, (index) {
                              final dayNum = index + 1;
                              final dayDate = cycle.startDate.addCalendarDays(
                                index,
                              );
                              final dateKey = dayDate.dateKey;
                              final entry = cycle.dailyEntries[dateKey];
                              return Container(
                                margin: const EdgeInsets.only(bottom: kCellGap),
                                child: ChartGridStampCell(
                                  entry: entry,
                                  dayNum: dayNum,
                                  dayDate: dayDate,
                                  cycle: cycle,
                                  onSelectEntry: onSelectEntry,
                                  onAddForDate: onAddForDate,
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
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
