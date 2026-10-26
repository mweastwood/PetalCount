import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import '../../theme/theme.dart';
import '../creighton_stamp_widget.dart';

class ChartGridStampCell extends StatelessWidget {
  final DailyEntry? entry;
  final int dayNum;
  final DateTime dayDate;
  final Cycle cycle;
  final void Function(DailyEntry entry, Cycle cycle) onSelectEntry;
  final void Function(Cycle? cycle, DateTime date) onAddForDate;

  const ChartGridStampCell({
    super.key,
    required this.entry,
    required this.dayNum,
    required this.dayDate,
    required this.cycle,
    required this.onSelectEntry,
    required this.onAddForDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentEntry = entry;
    final borderCol = currentEntry != null
        ? (currentEntry.stampType == StampType.whiteBaby
              ? CreightonTheme.greenBorder
              : (currentEntry.stampType == StampType.yellowBaby
                    ? CreightonTheme.yellowBorder
                    : theme.colorScheme.outline))
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    final hasPain = currentEntry != null && currentEntry.painLevel > 0;
    final hasComments =
        currentEntry != null && currentEntry.comments.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (currentEntry != null) {
          onSelectEntry(currentEntry, cycle);
        } else {
          onAddForDate(cycle, dayDate);
        }
      },
      child: Container(
        width: CreightonTheme.cellWidth,
        height: CreightonTheme.cellHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(
            color: borderCol,
            width: currentEntry != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(6.5)),
          child: Column(
            children: [
              // TOP EDGE-TO-EDGE STICKER BOX
              CreightonStampWidget.gridSticker(
                stampType: currentEntry?.stampType,
                peakDayLabel: currentEntry?.peakDayLabel,
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
                        AppDateFormats.shortMonthDay.format(dayDate),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: currentEntry != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Creighton VDRS Code (Prominent font: 12-13px bold)
                      Text(
                        currentEntry != null
                            ? currentEntry.resolvedVdrsCode
                            : '?',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: currentEntry != null
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
