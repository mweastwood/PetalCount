import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class DangerZoneCard extends StatelessWidget {
  final String chartId;
  final bool hasOtherCollaborators;

  const DangerZoneCard({
    super.key,
    required this.chartId,
    this.hasOtherCollaborators = false,
  });

  void _confirmDeleteChart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Chart?'),
          content: Text(
            'Are you sure you want to permanently delete the chart "$chartId" and all of its cycles/observations? This will delete the data for all collaborators and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                try {
                  await Services.db.deleteChart(chartId);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error deleting chart: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLeaveChart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Chart?'),
          content: Text(
            'Are you sure you want to leave the chart "$chartId"? You will lose access to its cycles and observations, but the data will remain active for other collaborators.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                try {
                  await Services.db.leaveChart(chartId);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error leaving chart: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Leave Chart'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Danger Zone',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Permanently delete this chart and all associated cycle logs and observations. This action is destructive and cannot be undone.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _confirmDeleteChart(context),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Chart'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                ),
                if (hasOtherCollaborators) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Leave this chart. You will lose access to its observations, but the data will remain active for other collaborators.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmLeaveChart(context),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Chart'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
