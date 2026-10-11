import 'package:flutter/material.dart';

class EmptyDashboardView extends StatelessWidget {
  final VoidCallback onLogFirstObservation;

  const EmptyDashboardView({
    super.key,
    required this.onLogFirstObservation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Observations Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your self-reported observations to automatically track and detect your cycles.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onLogFirstObservation,
              icon: const Icon(Icons.add),
              label: const Text('Log First Observation'),
            ),
          ],
        ),
      ),
    );
  }
}
