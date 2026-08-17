import 'package:flutter/material.dart';

import '../logic/logic.dart';
import 'add_observation_dialog.dart';
import 'creighton_stamp_widget.dart';

class DailyDetailSheet extends StatelessWidget {
  final DailyEntry entry;
  final Cycle cycle;

  const DailyDetailSheet({super.key, required this.entry, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final observations = entry.observations;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Observations for ${AppDateFormats.weekdayMonthDay.format(entry.date)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CreightonStampWidget.badge(
                stampType: entry.stampType,
                peakDayLabel: entry.peakDayLabel,
              ),
              const SizedBox(width: 12),
              Text(
                'Resolved Code: ${entry.resolvedVdrsCode}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (entry.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes Summary: ${entry.comments}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          if (entry.painLevel > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pain Level: ${entry.painLevel.toInt()}/10 (${entry.painTypes.join(", ")})',
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Logged Entries (${observations.length}):',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (observations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No individual observations. (Click grid to add)',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final obs = observations[index];
                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    title: Text('Code: ${obs.vdrsCode}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensation: ${obs.sensation.label} | Stretch: ${obs.stretch.label}',
                        ),
                        if (obs.comment.isNotEmpty)
                          Text('Notes: ${obs.comment}'),
                        Text(
                          'Logged at ${AppDateFormats.timeOfDayPadded.format(obs.timestamp)} by ${obs.userId == "husband_uid" ? "Husband" : "Wife"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await Services.db.deleteObservation(
                          cycleId: cycle.id,
                          date: entry.date,
                          observationId: obs.id,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) =>
                    AddObservationDialog(cycle: cycle, defaultDate: entry.date),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Another Observation for This Day'),
          ),
        ],
      ),
    );
  }
}
