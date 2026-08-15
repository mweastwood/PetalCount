import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/logic.dart';
import '../widgets/creighton_stamp_widget.dart';
import '../widgets/cycle_options_dialog.dart';

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

  String _getBleedingSummary(DailyEntry entry) {
    for (final obs in entry.observations) {
      if (obs.hasBleeding) {
        return '${obs.bleeding.label}${obs.bleedingColor.isNotEmpty ? " (${obs.bleedingColor})" : ""}';
      }
    }
    if (entry.hasBleeding) {
      return 'Bleeding recorded';
    }
    return '';
  }

  String _getMucusSummary(DailyEntry entry) {
    final parts = <String>[];
    for (final obs in entry.observations) {
      if (obs.hasMucus || obs.sensation != Sensation.dry) {
        final sens = obs.sensation.label;
        final str = obs.stretch != Stretch.none ? obs.stretch.label : null;
        final colors = obs.colors.map((c) => c.label).join(', ');
        final consist = obs.consistencies.map((c) => c.label).join(', ');

        final items = <String>[
          if (sens != 'Dry') sens,
          ?str,
          if (colors.isNotEmpty) colors,
          if (consist.isNotEmpty) consist,
        ];
        if (items.isNotEmpty) {
          parts.add(items.join(' • '));
        }
      }
    }
    if (parts.isNotEmpty) {
      return parts.join(' | ');
    }
    if (entry.resolvedVdrsCode.isNotEmpty && !entry.hasBleeding) {
      return entry.resolvedVdrsCode;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        ).subtract(const Duration(days: 1));
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

      int totalDays = cycleEnd.difference(cycleStart).inDays;
      if (totalDays < 0) totalDays = 0;

      for (int dayOffset = 0; dayOffset <= totalDays; dayOffset++) {
        final date = cycleStart.add(Duration(days: dayOffset));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
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
            DateFormat('MMMM yyyy').format(reversedItems[index + 1].date) !=
                DateFormat('MMMM yyyy').format(item.date);

        final bleedingSummary = entry != null ? _getBleedingSummary(entry) : '';
        final mucusSummary = entry != null ? _getMucusSummary(entry) : '';
        final hasPain =
            entry != null &&
            (entry.painLevel > 0 || entry.painTypes.isNotEmpty);
        final hasComments = entry != null && entry.comments.isNotEmpty;

        final timelineRowWidget = IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Track Column
              SizedBox(
                width: 56,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Vertical Connector Line
                    Positioned(
                      left: 26,
                      width: 4,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    // Stamp Box Node
                    Positioned(
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          if (item.cycle != null) {
                            CycleOptionsDialog.show(
                              context,
                              cycle: item.cycle!,
                              cycles: cycles,
                              targetDate: item.date,
                            );
                          }
                        },
                        child: CreightonStampWidget.timelineNode(
                          stampType: entry?.stampType,
                          peakDayLabel: entry?.peakDayLabel,
                          dayNumber: item.dayNumber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Observation Details Card Column
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: isToday
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.15,
                          )
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row: Date + VDRS Code badge + Chevron
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isToday
                                        ? 'Today – ${DateFormat('EEEE, MMM dd, yyyy').format(item.date)}'
                                        : DateFormat(
                                            'EEEE, MMM dd, yyyy',
                                          ).format(item.date),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: isToday
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isToday
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                if (entry != null &&
                                    entry.resolvedVdrsCode.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.resolvedVdrsCode,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ],
                            ),

                            // Cycle Start Banner if applicable
                            if (item.isCycleStart && item.cycle != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => CycleOptionsDialog.show(
                                  context,
                                  cycle: item.cycle!,
                                  cycles: cycles,
                                  targetDate: item.date,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flag,
                                        size: 14,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cycle starting ${DateFormat('MMMM dd, yyyy').format(item.date)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.tune,
                                        size: 12,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            if (entry == null) ...[
                              Text(
                                'Day ${item.dayNumber} • Tap to log observation',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Day ${item.dayNumber}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // If individual observations exist for this day
                              if (entry.observations.isNotEmpty) ...[
                                for (
                                  int obsIdx = 0;
                                  obsIdx < entry.observations.length;
                                  obsIdx++
                                )
                                  _buildIndividualObservationCard(
                                    context,
                                    entry.observations[obsIdx],
                                    obsIdx,
                                    entry.observations.length,
                                  ),
                              ] else ...[
                                // Fallback for legacy aggregated entry without individual observations list
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (bleedingSummary.isNotEmpty)
                                      _buildChip(
                                        context,
                                        icon: Icons.water_drop,
                                        label: bleedingSummary,
                                        color: Colors.red.shade700,
                                        bgColor: Colors.red.shade50,
                                        borderColor: Colors.red.shade200,
                                      ),
                                    if (mucusSummary.isNotEmpty)
                                      _buildChip(
                                        context,
                                        icon: Icons.invert_colors,
                                        label: mucusSummary,
                                        color: Colors.teal.shade800,
                                        bgColor: Colors.teal.shade50,
                                        borderColor: Colors.teal.shade200,
                                      ),
                                    if (hasPain)
                                      _buildChip(
                                        context,
                                        icon: Icons.bolt,
                                        label:
                                            'Pain: ${entry.painLevel.toStringAsFixed(0)}/10${entry.painTypes.isNotEmpty ? ' (${entry.painTypes.join(', ')})' : ''}',
                                        color: Colors.amber.shade900,
                                        bgColor: Colors.amber.shade50,
                                        borderColor: Colors.amber.shade300,
                                      ),
                                  ],
                                ),
                                if (hasComments) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.notes,
                                          size: 14,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '"${entry.comments}"',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        if (isMonthStart) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthHeader(context, item.date),
              timelineRowWidget,
            ],
          );
        }

        return timelineRowWidget;
      },
    );
  }

  Widget _buildIndividualObservationCard(
    BuildContext context,
    Observation obs,
    int index,
    int totalCount,
  ) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('h:mm a').format(obs.timestamp);
    final code = obs.vdrsCode;

    final bleedingText = obs.hasBleeding
        ? '${obs.bleeding.label}${obs.bleedingColor == 'R' ? ' (Red)' : (obs.bleedingColor == 'B' ? ' (Brown)' : '')}'
        : '';

    final mucusParts = <String>[];
    if (obs.hasMucus || obs.sensation != Sensation.dry) {
      if (obs.sensation != Sensation.dry) mucusParts.add(obs.sensation.label);
      if (obs.stretch != Stretch.none) mucusParts.add(obs.stretch.label);
      if (obs.colors.isNotEmpty) {
        mucusParts.add(obs.colors.map((c) => c.label).join(', '));
      }
      if (obs.consistencies.isNotEmpty) {
        mucusParts.add(obs.consistencies.map((c) => c.label).join(', '));
      }
    }
    final mucusText = mucusParts.join(' • ');

    final hasPain = obs.painLevel > 0 || obs.painTypes.isNotEmpty;
    final painText = hasPain
        ? 'Pain: ${obs.painLevel.toStringAsFixed(0)}/10${obs.painTypes.isNotEmpty ? ' (${obs.painTypes.join(', ')})' : ''}'
        : '';

    final hasComment = obs.comment.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 6.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_filled,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                totalCount > 1
                    ? 'Observation #${index + 1} • $timeStr'
                    : 'Observation • $timeStr',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (code.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (bleedingText.isNotEmpty)
                _buildChip(
                  context,
                  icon: Icons.water_drop,
                  label: bleedingText,
                  color: Colors.red.shade700,
                  bgColor: Colors.red.shade50,
                  borderColor: Colors.red.shade200,
                ),
              if (mucusText.isNotEmpty)
                _buildChip(
                  context,
                  icon: Icons.invert_colors,
                  label: mucusText,
                  color: Colors.teal.shade800,
                  bgColor: Colors.teal.shade50,
                  borderColor: Colors.teal.shade200,
                ),
              if (hasPain)
                _buildChip(
                  context,
                  icon: Icons.bolt,
                  label: painText,
                  color: Colors.amber.shade900,
                  bgColor: Colors.amber.shade50,
                  borderColor: Colors.amber.shade300,
                ),
            ],
          ),
          if (hasComment) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notes,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '"${obs.comment}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final monthYearStr = DateFormat('MMMM yyyy').format(date).toUpperCase();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Track Column - Unbroken Line Through Month Header
          SizedBox(
            width: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 26,
                  width: 4,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthYearStr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
