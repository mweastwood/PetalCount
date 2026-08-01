import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic/logic.dart';

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

  static const double kCellWidth = 66.0;
  static const double kCellHeight = 114.0;
  static const double kHeaderRowHeight = 36.0;
  static const double kCycleHeaderWidth = 110.0;
  static const double kCellGap = 3.0;

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) {
      return const Center(
        child: Text('No cycles available. Log an observation to begin.'),
      );
    }

    // Determine the maximum number of days to display across all cycles (at least 35 days)
    int maxDays = 35;
    for (final cycle in cycles) {
      final count = cycle.sortedEntries.length;
      if (count > maxDays) maxDays = count;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 88.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shared Spreadsheet Header Row (Day 1, Day 2 ... Day N)
            _buildSpreadsheetHeaderRow(context, maxDays),
            const SizedBox(height: 6.0),
            // Cycle Rows
            ...cycles.map((cycle) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _buildCycleRow(context, cycle, maxDays),
              );
            }),
          ],
        ),
      ),
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

  /// Renders a single cycle row with its left label card and day cells
  Widget _buildCycleRow(BuildContext context, Cycle cycle, int maxDays) {
    final theme = Theme.of(context);
    final entries = cycle.sortedEntries;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Cycle Label Card
        Container(
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
              const Divider(height: 8),
              Text(
                '${cycle.dailyEntries.length} entries',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (cycle.bipCodes.isNotEmpty)
                Text(
                  'BIP: ${cycle.bipCodes.join(', ')}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Day Stamp Cells for Day 1 .. Day N
        ...List.generate(maxDays, (index) {
          final dayNum = index + 1;
          DailyEntry? entry;
          if (index < entries.length) {
            entry = entries[index];
          }
          return Container(
            margin: const EdgeInsets.only(right: kCellGap),
            child: _buildGridStampCell(context, entry, dayNum, cycle),
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
    Cycle cycle,
  ) {
    final theme = Theme.of(context);

    Color stampColor = theme.colorScheme.surfaceContainerLowest;
    Color borderCol = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    bool hasBaby = false;
    bool hasGreenBaby = false;
    Color babyIconColor = Colors.black87;

    if (entry != null) {
      borderCol = theme.colorScheme.outline;
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

    final peakLabel = entry?.peakDayLabel;

    return GestureDetector(
      onTap: () {
        if (entry != null) {
          onSelectEntry(entry, cycle);
        } else {
          final mockDate = cycle.startDate.add(Duration(days: dayNum - 1));
          onAddForDate(cycle, mockDate);
        }
      },
      child: Container(
        width: kCellWidth,
        height: kCellHeight,
        clipBehavior: Clip.antiAlias,
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
        child: Column(
          children: [
            // TOP EDGE-TO-EDGE STICKER BOX
            Container(
              width: double.infinity,
              height: 46.0,
              decoration: BoxDecoration(color: stampColor),
              child: Stack(
                children: [
                  // Peak Day Badge at top-left
                  if (peakLabel != null && peakLabel.isNotEmpty)
                    Positioned(
                      top: 2,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: peakLabel == 'P'
                              ? Colors.red.shade700
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          peakLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Baby Icon in center for fertile stamps
                  if (hasBaby)
                    Center(
                      child: Icon(
                        Icons.child_care,
                        size: 26,
                        color: babyIconColor,
                      ),
                    )
                  else if (hasGreenBaby)
                    const Center(
                      child: Icon(
                        Icons.child_care,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
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
                      entry != null
                          ? DateFormat('MMM dd').format(entry.date)
                          : '-',
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
                      entry?.resolvedVdrsCode ?? '',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
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
    );
  }
}
