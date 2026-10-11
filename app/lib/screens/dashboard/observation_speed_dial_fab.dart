import 'package:flutter/material.dart';

import '../../widgets/wizard/wizard_controller.dart';

/// Speed-dial floating action button menu for logging observations.
///
/// When closed, displays an add icon button that triggers [onToggle].
/// When open, displays quick-log action options for each [ObservationCategory]
/// (intercourse, pain, bleeding, mucus) and a close icon button.
class ObservationSpeedDialFab extends StatelessWidget {
  /// Whether the speed dial menu is currently expanded to show options.
  final bool isOpen;

  /// Callback invoked when the user taps the main floating action button to
  /// toggle between open and closed states.
  final VoidCallback onToggle;

  /// Callback invoked when the user selects a specific [ObservationCategory] option.
  final void Function(ObservationCategory category) onSelectCategory;

  /// Creates an [ObservationSpeedDialFab].
  const ObservationSpeedDialFab({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isOpen) ...[
          _buildSpeedDialOption(
            context: context,
            label: 'Log intercourse',
            icon: Icons.favorite,
            color: Colors.pink.shade400,
            onTap: () => onSelectCategory(ObservationCategory.intercourse),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            context: context,
            label: 'Log pain',
            icon: Icons.healing,
            color: Colors.orange.shade700,
            onTap: () => onSelectCategory(ObservationCategory.pain),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            context: context,
            label: 'Log bleeding',
            icon: Icons.water_drop,
            color: Colors.red.shade600,
            onTap: () => onSelectCategory(ObservationCategory.bleeding),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            context: context,
            label: 'Log mucus',
            icon: Icons.bubble_chart,
            color: Colors.teal.shade600,
            onTap: () => onSelectCategory(ObservationCategory.mucus),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          key: const Key('fab_log_observation_toggle'),
          tooltip: 'Log Observation',
          onPressed: onToggle,
          child: Icon(isOpen ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  Widget _buildSpeedDialOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: label,
          tooltip: label,
          onPressed: onTap,
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}
