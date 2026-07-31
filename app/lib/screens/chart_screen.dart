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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isNarrow =
        media.size.width < media.size.height || media.size.width < 600;

    if (isNarrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cycles.map((cycle) {
              return _buildVerticalCycleColumn(context, cycle);
            }).toList(),
          ),
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
        itemCount: cycles.length,
        itemBuilder: (context, index) {
          final cycle = cycles[index];
          return _buildHorizontalCycleRow(context, cycle);
        },
      );
    }
  }

  Widget _buildVerticalCycleColumn(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final totalCells = entries.length < 35 ? 35 : entries.length;

    return Container(
      width: 68,
      margin: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM dd').format(cycle.startDate),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${cycle.startDate.year}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(totalCells, (index) {
            DailyEntry? entry;
            if (index < entries.length) {
              entry = entries[index];
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildGridStampCell(context, entry, index + 1, cycle),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHorizontalCycleRow(BuildContext context, Cycle cycle) {
    final entries = cycle.sortedEntries;
    final totalCells = entries.length < 35 ? 35 : entries.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle starting ${DateFormat('MMMM dd, yyyy').format(cycle.startDate)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  tooltip: 'Export Cycle PDF',
                  onPressed: () => PdfExportService.exportCyclesToPdf([cycle]),
                ),
              ],
            ),
            Text(
              '${cycle.dailyEntries.length} entries logged  |  BIP: ${cycle.bipCodes.isEmpty ? 'None' : cycle.bipCodes.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(totalCells, (index) {
                  DailyEntry? entry;
                  if (index < entries.length) {
                    entry = entries[index];
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _buildGridStampCell(
                      context,
                      entry,
                      index + 1,
                      cycle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStampCell(
    BuildContext context,
    DailyEntry? entry,
    int dayNum,
    Cycle cycle,
  ) {
    final theme = Theme.of(context);

    Color stampColor = theme.colorScheme.surfaceContainerLowest;
    Color borderCol = theme.colorScheme.outlineVariant;
    bool hasBaby = false;
    bool hasGreenBaby = false;
    Color babyIconColor = Colors.black87;

    if (entry != null) {
      borderCol = Colors.grey.shade400;
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
        width: 58,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 18,
              alignment: Alignment.center,
              child: Text(
                entry?.peakDayLabel ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: entry?.peakDayLabel == 'P'
                      ? Colors.red
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(
                color: stampColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: borderCol,
                  width: entry != null ? 1.5 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 8,
                          color:
                              entry != null &&
                                  entry.stampType != StampType.whiteBaby
                              ? Colors.white70
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (hasBaby)
                    Icon(Icons.child_care, size: 24, color: babyIconColor)
                  else if (hasGreenBaby)
                    const Icon(Icons.child_care, size: 24, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry != null ? DateFormat('MMM dd').format(entry.date) : '-',
                style: const TextStyle(fontSize: 8, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              height: 24,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                entry?.resolvedVdrsCode ?? '',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              height: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasPain)
                    const Icon(
                      Icons.local_fire_department,
                      size: 10,
                      color: Colors.redAccent,
                    ),
                  if (hasComments) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.notes, size: 10, color: Colors.blueAccent),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
