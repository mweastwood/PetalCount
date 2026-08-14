import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/logic.dart';
import '../widgets/creighton_stamp_widget.dart';
import '../widgets/cycle_options_dialog.dart';
import '../theme/theme.dart';

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

    final media = MediaQuery.of(context);
    final isNarrow =
        media.size.width < media.size.height || media.size.width < 600;

    if (isNarrow) {
      return _buildVerticalSpreadsheet(context, maxDays);
    } else {
      return _buildHorizontalSpreadsheet(context, maxDays);
    }
  }

  /// Narrow Screens (Portrait): Vertical Cycle Columns with a shared Day column on the left
  Widget _buildVerticalSpreadsheet(BuildContext context, int maxDays) {
    final theme = Theme.of(context);

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
                          height: kHeaderRowHeight,
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
                      return Container(
                        margin: const EdgeInsets.only(right: kCellGap),
                        child: Column(
                          children: [
                            // Column Top Header: Cycle Start Date + PDF
                            Container(
                              width: kCellWidth,
                              height: kHeaderRowHeight,
                              margin: const EdgeInsets.only(bottom: kCellGap),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat(
                                        'MMM dd',
                                      ).format(cycle.startDate),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.picture_as_pdf,
                                      size: 14,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Export Cycle PDF',
                                    onPressed: () =>
                                        PdfExportService.exportCyclesToPdf([
                                          cycle,
                                        ]),
                                  ),
                                ],
                              ),
                            ),
                            // Cells for Day 1 .. Day N going DOWN
                            ...List.generate(maxDays, (index) {
                              final dayNum = index + 1;
                              final dayDate = DateTime(
                                cycle.startDate.year,
                                cycle.startDate.month,
                                cycle.startDate.day + index,
                              );
                              final dateKey = DateFormat(
                                'yyyy-MM-dd',
                              ).format(dayDate);
                              final entry = cycle.dailyEntries[dateKey];
                              return Container(
                                margin: const EdgeInsets.only(bottom: kCellGap),
                                child: _buildGridStampCell(
                                  context,
                                  entry,
                                  dayNum,
                                  dayDate,
                                  cycle,
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

  /// Wide Screens (Landscape): Horizontal Cycle Rows with a shared Day header row across the top
  Widget _buildHorizontalSpreadsheet(BuildContext context, int maxDays) {
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
                            child: _buildCycleRow(context, cycle, maxDays),
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
  Widget _buildCycleRow(BuildContext context, Cycle cycle, int maxDays) {
    final theme = Theme.of(context);

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
                            DateFormat('MMM dd').format(cycle.startDate),
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
        ...List.generate(maxDays, (index) {
          final dayNum = index + 1;
          final dayDate = DateTime(
            cycle.startDate.year,
            cycle.startDate.month,
            cycle.startDate.day + index,
          );
          final dateKey = DateFormat('yyyy-MM-dd').format(dayDate);
          final entry = cycle.dailyEntries[dateKey];
          return Container(
            margin: const EdgeInsets.only(right: kCellGap),
            child: _buildGridStampCell(context, entry, dayNum, dayDate, cycle),
          );
        }),
      ],
    );
  }

  /// Renders an individual Creighton Stamp Cell where the sticker goes edge-to-edge
  Widget _buildGridStampCell(
    BuildContext context,
    DailyEntry? entry,
    int dayNum,
    DateTime dayDate,
    Cycle cycle,
  ) {
    final theme = Theme.of(context);
    final borderCol = entry != null
        ? (entry.stampType == StampType.whiteBaby
              ? CreightonTheme.greenBorder
              : theme.colorScheme.outline)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    final hasPain = entry != null && entry.painLevel > 0;
    final hasComments = entry != null && entry.comments.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (entry != null) {
          onSelectEntry(entry, cycle);
        } else {
          onAddForDate(cycle, dayDate);
        }
      },
      child: Container(
        width: kCellWidth,
        height: kCellHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderCol, width: entry != null ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.5),
          child: Column(
            children: [
              // TOP EDGE-TO-EDGE STICKER BOX
              CreightonStampWidget.gridSticker(
                stampType: entry?.stampType,
                peakDayLabel: entry?.peakDayLabel,
              ),
              // BOTTOM CELL DATA SECTION
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2.0,
                    vertical: 3.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date Label (Larger font: 10px bold)
                      Text(
                        DateFormat('MMM dd').format(dayDate),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: entry != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Creighton VDRS Code (Prominent font: 12-13px bold)
                      Text(
                        entry != null ? entry.resolvedVdrsCode : '?',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: entry != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Icons for Pain or Comments
                      SizedBox(
                        height: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasPain)
                              const Icon(
                                Icons.local_fire_department,
                                size: 11,
                                color: Colors.redAccent,
                              ),
                            if (hasComments) ...[
                              if (hasPain) const SizedBox(width: 2),
                              const Icon(
                                Icons.notes,
                                size: 11,
                                color: Colors.blueAccent,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
