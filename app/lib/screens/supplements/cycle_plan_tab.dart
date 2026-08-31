import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class CyclePlanTab extends StatelessWidget {
  final List<SupplementItem> supplements;
  final Cycle? cycle;
  final int maxCycleDays;

  const CyclePlanTab({
    super.key,
    required this.supplements,
    this.cycle,
    this.maxCycleDays = kSupplementPlanTotalCycleDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCycleDays = maxCycleDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Text(
          'Cycle Protocol Matrix',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Schedule of prescribed supplements across cycle days 1 to $totalCycleDays.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: Peak-based supplement schedules (e.g. P+3 or P+1) are displayed using standard cycle-day fallback ranges in this matrix overview until Peak Day is recorded in the active cycle.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...SupplementTimeOfDay.values.map((time) {
          final itemsWithDose = supplements
              .where((s) => s.doseForTime(time) > 0)
              .toList();

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(time.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '${time.label} Schedule',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 38,
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 44,
                      columnSpacing: 16,
                      columns: [
                        const DataColumn(
                          label: Text(
                            'Supplement',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Dose',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Schedule Rule',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...List.generate(totalCycleDays, (i) {
                          final day = i + 1;
                          return DataColumn(
                            label: Text(
                              'D$day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }),
                      ],
                      rows: itemsWithDose.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text(item.quantity)),
                            DataCell(Text(item.scheduleDescription)),
                            ...List.generate(totalCycleDays, (i) {
                              final day = i + 1;
                              final isActive = item.isScheduledFor(
                                cycleDay: day,
                              );
                              return DataCell(
                                Center(
                                  child: isActive
                                      ? Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green.shade600,
                                        )
                                      : Icon(
                                          Icons.remove,
                                          size: 14,
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
