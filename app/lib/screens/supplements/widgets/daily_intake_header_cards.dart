import 'package:flutter/material.dart';

import '../../../logic/logic.dart';

class DailyIntakeDateNavigatorCard extends StatelessWidget {
  final DateTime selectedDate;
  final int cycleDay;
  final int? daysPastPeak;
  final ValueChanged<int>? onDateChanged;
  final VoidCallback? onGoToToday;

  const DailyIntakeDateNavigatorCard({
    super.key,
    required this.selectedDate,
    required this.cycleDay,
    this.daysPastPeak,
    this.onDateChanged,
    this.onGoToToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = AppDateFormats.shortMonthDayYear.format(selectedDate);
    final isToday = DateTime.now().dateKey == selectedDate.dateKey;

    String cycleStatus = 'Cycle Day $cycleDay';
    if (daysPastPeak != null) {
      if (daysPastPeak == 0) {
        cycleStatus += ' • Peak Day (P)';
      } else if (daysPastPeak! > 0) {
        cycleStatus += ' • Post-Peak (P+$daysPastPeak)';
      } else {
        cycleStatus += ' • Pre-Peak (P$daysPastPeak)';
      }
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Day',
              onPressed: onDateChanged != null
                  ? () => onDateChanged!(-1)
                  : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'TODAY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cycleStatus,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isToday)
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Go to Today',
                onPressed: onGoToToday,
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Day',
              onPressed: onDateChanged != null ? () => onDateChanged!(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class DailyIntakeEmptyPlanCard extends StatelessWidget {
  final UserRole selectedRole;

  const DailyIntakeEmptyPlanCard({super.key, required this.selectedRole});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.medication_outlined,
                size: 40,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'No supplements in your ${selectedRole.displayName.toLowerCase()} plan yet.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the edit button to add supplements and schedule rules.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DailyIntakeAdherenceCard extends StatelessWidget {
  final int takenDoses;
  final int totalDoses;

  const DailyIntakeAdherenceCard({
    super.key,
    required this.takenDoses,
    required this.totalDoses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalDoses > 0 ? (takenDoses / totalDoses) : 0.0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Supplements",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$takenDoses / $totalDoses taken',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: takenDoses == totalDoses && totalDoses > 0
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  takenDoses == totalDoses && totalDoses > 0
                      ? Colors.green
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
