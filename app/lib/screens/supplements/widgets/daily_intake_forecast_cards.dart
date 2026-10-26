import 'package:flutter/material.dart';

import '../../../logic/logic.dart';

class UpcomingDayForecastCard extends StatelessWidget {
  final SupplementDayForecast day;

  const UpcomingDayForecastCard({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = AppDateFormats.weekdayMonthDay.format(day.date);
    final dayTitle = day.dayOffset == 1
        ? 'Tomorrow • $formattedDate'
        : formattedDate;

    String cycleBadge = 'Cycle Day ${day.cycleDay}';
    if (day.daysPastPeak != null) {
      if (day.daysPastPeak == 0) {
        cycleBadge += ' • Peak (P)';
      } else if (day.daysPastPeak! > 0) {
        cycleBadge += ' • P+${day.daysPastPeak}';
      } else {
        cycleBadge += ' • P${day.daysPastPeak}';
      }
    }

    final activeTimes = SupplementTimeOfDay.values
        .where((time) => day.scheduledForTime(time).isNotEmpty)
        .toList();

    return Card(
      key: Key('upcoming_day_card_${day.dayOffset}'),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    dayTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cycleBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeTimes.isEmpty)
              Text(
                'No definite supplements scheduled.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...activeTimes.map((time) {
                final itemsForTime = day.scheduledForTime(time);
                final summary = itemsForTime
                    .map((item) => '${item.name} (${item.doseForTime(time)})')
                    .join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(time.icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 68,
                        child: Text(
                          time.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (day.conditionalOnPeakSupplements.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConditionalOnPeakSection(
                dayOffset: day.dayOffset,
                items: day.conditionalOnPeakSupplements,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ConditionalOnPeakSection extends StatelessWidget {
  final int dayOffset;
  final List<SupplementItem> items;

  const ConditionalOnPeakSection({
    super.key,
    required this.dayOffset,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: Key('conditional_peak_section_day_$dayOffset'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 15,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Conditional on Peak',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) {
            final doseParts = <String>[
              if (item.takesInMorning) '🌅 ${item.morningDose}',
              if (item.takesInAfternoon) '☀️ ${item.afternoonDose}',
              if (item.takesInEvening) '🌙 ${item.eveningDose}',
            ];
            final doseSummary = doseParts.join(' • ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} ($doseSummary × ${item.quantity})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.scheduleDescription,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
