import 'package:flutter/material.dart';

/// Zero-state dashboard view displayed when no cycles or observations have been logged.
///
/// Prompts the user with introductory text and a primary call-to-action button
/// to record their first observation.
class EmptyDashboardView extends StatelessWidget {
  /// Callback invoked when the user taps the call-to-action button to log
  /// their first observation.
  final VoidCallback onLogFirstObservation;

  /// Creates an [EmptyDashboardView].
  const EmptyDashboardView({super.key, required this.onLogFirstObservation});

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
