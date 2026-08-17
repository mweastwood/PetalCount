import 'package:flutter/material.dart';

import '../../logic/logic.dart';

/// Month divider row in the timeline with calendar icon, uppercase month/year header,
/// divider line, and continuous 56px vertical connector line track.
class TimelineMonthHeader extends StatelessWidget {
  final DateTime date;

  const TimelineMonthHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthYearStr = AppDateFormats.monthYear.format(date).toUpperCase();

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
}
