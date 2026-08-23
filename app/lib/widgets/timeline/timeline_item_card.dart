import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import 'observation_details_card.dart';
import 'timeline_summary_chip.dart';

/// Card widget on the right side of the timeline track displaying date header,
/// cycle flag, day indicator, and logged observations or empty state prompts.
class TimelineItemCard extends StatelessWidget {
  final DateTime date;
  final DailyEntry? entry;
  final Cycle? cycle;
  final int dayNumber;
  final bool isCycleStart;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback? onCycleOptionsTap;

  const TimelineItemCard({
    super.key,
    required this.date,
    required this.entry,
    required this.cycle,
    required this.dayNumber,
    required this.isCycleStart,
    required this.isToday,
    required this.onTap,
    this.onCycleOptionsTap,
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
    final currentEntry = entry;

    final bleedingSummary = currentEntry != null
        ? _getBleedingSummary(currentEntry)
        : '';
    final mucusSummary = currentEntry != null
        ? _getMucusSummary(currentEntry)
        : '';
    final hasPain =
        currentEntry != null &&
        (currentEntry.painLevel > 0 || currentEntry.painTypes.isNotEmpty);
    final hasComments =
        currentEntry != null && currentEntry.comments.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
          onTap: onTap,
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
                            ? 'Today – ${AppDateFormats.fullDate.format(date)}'
                            : AppDateFormats.fullDate.format(date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (currentEntry != null &&
                        currentEntry.resolvedVdrsCode.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentEntry.resolvedVdrsCode,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      if (currentEntry.hasIntercourse) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.pink.shade200,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 13,
                            color: Colors.pink.shade600,
                          ),
                        ),
                      ],
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
                if (isCycleStart && cycle != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onCycleOptionsTap,
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
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cycle starting ${AppDateFormats.monthDayYear.format(date)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.tune,
                            size: 12,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                if (currentEntry == null) ...[
                  Text(
                    'Day $dayNumber • Tap to log observation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Day $dayNumber',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // If individual observations exist for this day
                  if (currentEntry.observations.isNotEmpty) ...[
                    for (
                      int obsIdx = 0;
                      obsIdx < currentEntry.observations.length;
                      obsIdx++
                    )
                      ObservationDetailsCard(
                        observation: currentEntry.observations[obsIdx],
                        index: obsIdx,
                        totalCount: currentEntry.observations.length,
                      ),
                  ] else ...[
                    // Fallback for legacy aggregated entry without individual observations list
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (bleedingSummary.isNotEmpty)
                          TimelineSummaryChip(
                            icon: Icons.water_drop,
                            label: bleedingSummary,
                            color: Colors.red.shade700,
                            bgColor: Colors.red.shade50,
                            borderColor: Colors.red.shade200,
                          ),
                        if (mucusSummary.isNotEmpty)
                          TimelineSummaryChip(
                            icon: Icons.invert_colors,
                            label: mucusSummary,
                            color: Colors.teal.shade800,
                            bgColor: Colors.teal.shade50,
                            borderColor: Colors.teal.shade200,
                          ),
                        if (hasPain)
                          TimelineSummaryChip(
                            icon: Icons.bolt,
                            label:
                                'Pain: ${currentEntry.painLevel.toStringAsFixed(0)}/10${currentEntry.painTypes.isNotEmpty ? ' (${currentEntry.painTypes.join(', ')})' : ''}',
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
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notes,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '"${currentEntry.comments}"',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
