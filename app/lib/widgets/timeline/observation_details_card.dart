import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import 'timeline_summary_chip.dart';

/// Card rendering individual intra-day observation entries with sequence index,
/// timestamp, VDRS code badge, summary chips, and optional user notes.
class ObservationDetailsCard extends StatelessWidget {
  final Observation observation;
  final int index;
  final int totalCount;

  const ObservationDetailsCard({
    super.key,
    required this.observation,
    required this.index,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = AppDateFormats.timeOfDay.format(observation.timestamp);
    final code = observation.vdrsCode;

    final bleedingText = observation.hasBleeding
        ? '${observation.bleeding.label}${observation.bleedingColor == 'R' ? ' (Red)' : (observation.bleedingColor == 'B' ? ' (Brown)' : '')}'
        : '';

    final mucusParts = <String>[];
    if (observation.hasMucus || observation.sensation != Sensation.dry) {
      if (observation.sensation != Sensation.dry) {
        mucusParts.add(observation.sensation.label);
      }
      if (observation.stretch != Stretch.none) {
        mucusParts.add(observation.stretch.label);
      }
      if (observation.colors.isNotEmpty) {
        mucusParts.add(observation.colors.map((c) => c.label).join(', '));
      }
      if (observation.consistencies.isNotEmpty) {
        mucusParts.add(
          observation.consistencies.map((c) => c.label).join(', '),
        );
      }
    }
    final mucusText = mucusParts.join(' • ');

    final hasPain =
        observation.painLevel > 0 || observation.painTypes.isNotEmpty;
    final painText = hasPain
        ? 'Pain: ${observation.painLevel.toStringAsFixed(0)}/10${observation.painTypes.isNotEmpty ? ' (${observation.painTypes.join(', ')})' : ''}'
        : '';

    final hasComment = observation.comment.isNotEmpty;

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
                TimelineSummaryChip(
                  icon: Icons.water_drop,
                  label: bleedingText,
                  color: Colors.red.shade700,
                  bgColor: Colors.red.shade50,
                  borderColor: Colors.red.shade200,
                ),
              if (mucusText.isNotEmpty)
                TimelineSummaryChip(
                  icon: Icons.invert_colors,
                  label: mucusText,
                  color: Colors.teal.shade800,
                  bgColor: Colors.teal.shade50,
                  borderColor: Colors.teal.shade200,
                ),
              if (hasPain)
                TimelineSummaryChip(
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
                      '"${observation.comment}"',
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
}
