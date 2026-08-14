import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/models/cycle.dart';
import '../logic/services/services.dart';

class CycleOptionsDialog extends StatelessWidget {
  final Cycle cycle;
  final List<Cycle> cycles;
  final DateTime? targetDate;

  const CycleOptionsDialog({
    super.key,
    required this.cycle,
    required this.cycles,
    this.targetDate,
  });

  static Future<void> show(
    BuildContext context, {
    required Cycle cycle,
    required List<Cycle> cycles,
    DateTime? targetDate,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CycleOptionsDialog(
        cycle: cycle,
        cycles: cycles,
        targetDate: targetDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedCycles = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final isFirstCycle =
        sortedCycles.isNotEmpty && sortedCycles.first.id == cycle.id;
    final formattedDate = DateFormat('MMMM dd, yyyy').format(cycle.startDate);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings_suggest,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cycle Boundary Options',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Current cycle start: $formattedDate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Divider(height: 24),
              if (targetDate != null &&
                  DateFormat('yyyy-MM-dd').format(targetDate!) !=
                      DateFormat('yyyy-MM-dd').format(cycle.startDate)) ...[
                ListTile(
                  leading: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Start New Cycle on ${DateFormat('MMM dd, yyyy').format(targetDate!)}',
                  ),
                  subtitle: const Text(
                    'Splits cycle and starts a new cycle boundary on this date',
                  ),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    await Services.db.startNewCycle(
                      targetDate!,
                      cycle.bipCodes,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'New cycle started on ${DateFormat('MMM dd, yyyy').format(targetDate!)}',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: Icon(
                  Icons.edit_calendar,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Adjust Cycle Start Date'),
                subtitle: const Text('Change the start date for this cycle'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  final picked = await showDatePicker(
                    context: navigator.context,
                    initialDate: cycle.startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    await Services.db.updateCycleStartDate(cycle.id, picked);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cycle start date updated to ${DateFormat('MMM dd, yyyy').format(picked)}',
                        ),
                      ),
                    );
                  }
                },
              ),
              if (!isFirstCycle) ...[
                ListTile(
                  leading: Icon(
                    Icons.merge_type,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Cycle Boundary',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text(
                    'Merges observations from this cycle into the previous cycle',
                  ),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    navigator.pop();
                    final confirm = await showDialog<bool>(
                      context: navigator.context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Delete Cycle Boundary?'),
                        content: Text(
                          'This will merge the cycle starting on $formattedDate into the previous cycle. All observations will be preserved.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Delete Boundary'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await Services.db.mergeCycleWithPrevious(cycle.id);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Cycle merged into previous cycle'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
