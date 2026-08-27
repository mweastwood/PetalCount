import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class DebugDiagnosticsCard extends StatelessWidget {
  const DebugDiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Debug & Diagnostics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Export a complete, structured JSON diagnostic snapshot containing current Firestore documents, auth state, rule permission checks, and in-memory event logs to assist with troubleshooting.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () =>
                      AppStateExporter.instance.shareDebugState(context),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Export Debug State (JSON)'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
