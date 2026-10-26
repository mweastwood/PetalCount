import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import '../../theme/theme.dart';
import '../cycle_options_dialog.dart';
import 'chart_grid_stamp_cell.dart';

/// Wide Screens (Landscape): Horizontal Cycle Rows with a shared Day header row across the top
class ChartHorizontalSpreadsheet extends StatelessWidget {
  final List<Cycle> cycles;
  final int maxDays;
  final Map<String, int> displayDaysMap;
  final void Function(DailyEntry entry, Cycle cycle) onSelectEntry;
  final void Function(Cycle? cycle, DateTime date) onAddForDate;

  const ChartHorizontalSpreadsheet({
    super.key,
    required this.cycles,
    required this.maxDays,
    required this.displayDaysMap,
    required this.onSelectEntry,
    required this.onAddForDate,
  });

  @override
  Widget build(BuildContext context) {
    const kCellWidth = CreightonTheme.cellWidth;
    const kCycleHeaderWidth = CreightonTheme.cycleHeaderWidth;
    const kCellGap = CreightonTheme.cellGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            kCycleHeaderWidth + kCellGap + maxDays * (kCellWidth + kCellGap);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shared Spreadsheet Header Row (Day 1, Day 2 ... Day N across top)
                    _buildSpreadsheetHeaderRow(context, maxDays),
                    const SizedBox(height: 6.0),
                    // Cycle Rows: Note that in a bidirectional 2D scroll layout with
                    // unbounded vertical constraints, ListView.builder with shrinkWrap
                    // measures items eagerly while maintaining clean index-based rendering.
                    SizedBox(
                      width: contentWidth,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cycles.length,
                        itemBuilder: (context, index) {
                          final cycle = cycles[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: _buildCycleRow(
                              context,
                              cycle,
                              displayDaysMap[cycle.id] ?? maxDays,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Renders the shared top spreadsheet header row labeling Day 1 .. Day N
  Widget _buildSpreadsheetHeaderRow(BuildContext context, int maxDays) {
    final theme = Theme.of(context);
    const kCellWidth = CreightonTheme.cellWidth;
    const kHeaderRowHeight = CreightonTheme.headerRowHeight;
    const kCycleHeaderWidth = CreightonTheme.cycleHeaderWidth;
    const kCellGap = CreightonTheme.cellGap;

    return Row(
      children: [
        // Left Column Header Label
        Container(
          width: kCycleHeaderWidth,
          height: kHeaderRowHeight,
          margin: const EdgeInsets.only(right: kCellGap),
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            'Cycle / Day',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        // Shared Day Numbers (Day 1, Day 2, ... Day N)
        ...List.generate(maxDays, (index) {
          final dayNum = index + 1;
          return Container(
            width: kCellWidth,
            height: kHeaderRowHeight,
            margin: const EdgeInsets.only(right: kCellGap),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.7,
              ),
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
    );
  }

  /// Renders a single cycle row with its left label card and day cells (Horizontal Layout)
  Widget _buildCycleRow(BuildContext context, Cycle cycle, int displayDays) {
    final theme = Theme.of(context);
    const kCellHeight = CreightonTheme.cellHeight;
    const kCycleHeaderWidth = CreightonTheme.cycleHeaderWidth;
    const kCellGap = CreightonTheme.cellGap;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Cycle Label Card
        GestureDetector(
          onTap: () =>
              CycleOptionsDialog.show(context, cycle: cycle, cycles: cycles),
          child: Container(
            width: kCycleHeaderWidth,
            height: kCellHeight,
            margin: const EdgeInsets.only(right: kCellGap),
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateFormats.shortMonthDay.format(
                              cycle.startDate,
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${cycle.startDate.year}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Export Cycle PDF',
                      onPressed: () =>
                          PdfExportService.exportCyclesToPdf([cycle]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.settings_suggest,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Options',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Day Stamp Cells for Day 1 .. Day N going ACROSS
        ...List.generate(displayDays, (index) {
          final dayNum = index + 1;
          final dayDate = cycle.startDate.addCalendarDays(index);
          final dateKey = dayDate.dateKey;
          final entry = cycle.dailyEntries[dateKey];
          return Container(
            margin: const EdgeInsets.only(right: kCellGap),
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
    );
  }
}
