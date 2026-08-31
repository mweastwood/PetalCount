import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class FormularyTab extends StatelessWidget {
  final List<SupplementItem> supplements;
  final ValueChanged<SupplementItem>? onEdit;
  final ValueChanged<SupplementItem>? onDelete;

  const FormularyTab({
    super.key,
    required this.supplements,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: supplements.map((item) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quantity: ${item.quantity}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit Supplement',
                      onPressed: onEdit != null ? () => onEdit!(item) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.error,
                      tooltip: 'Delete Supplement',
                      onPressed: onDelete != null
                          ? () => onDelete!(item)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (item.takesInMorning)
                      _buildDoseBadge(
                        '🌅 Morning (${item.morningDose})',
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.onPrimaryContainer,
                      ),
                    if (item.takesInAfternoon)
                      _buildDoseBadge(
                        '☀️ Afternoon (${item.afternoonDose})',
                        theme.colorScheme.secondaryContainer,
                        theme.colorScheme.onSecondaryContainer,
                      ),
                    if (item.takesInEvening)
                      _buildDoseBadge(
                        '🌙 Evening (${item.eveningDose})',
                        theme.colorScheme.tertiaryContainer,
                        theme.colorScheme.onTertiaryContainer,
                      ),
                    if (item.takeWithFood)
                      _buildDoseBadge(
                        '🍽️ Take with food',
                        Colors.amber.shade100,
                        Colors.amber.shade900,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Schedule: ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.scheduleDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.instructions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.instructions,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDoseBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
