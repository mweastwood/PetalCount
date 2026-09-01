import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class FormularyTab extends StatefulWidget {
  final List<SupplementItem> supplements;
  final ValueChanged<SupplementItem>? onEdit;
  final ValueChanged<SupplementItem>? onDelete;
  final UserRole? initialRoleFilter;

  const FormularyTab({
    super.key,
    required this.supplements,
    this.onEdit,
    this.onDelete,
    this.initialRoleFilter,
  });

  @override
  State<FormularyTab> createState() => _FormularyTabState();
}

class _FormularyTabState extends State<FormularyTab> {
  UserRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _filterRole = widget.initialRoleFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wifeCount = widget.supplements
        .where((s) => s.targetRole == UserRole.wife)
        .length;
    final husbandCount = widget.supplements
        .where((s) => s.targetRole == UserRole.husband)
        .length;

    final displayedSupplements = _filterRole == null
        ? widget.supplements
        : widget.supplements.where((s) => s.targetRole == _filterRole).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        // Role filter segment
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SegmentedButton<UserRole?>(
            key: const Key('formulary_filter_segmented_button'),
            segments: [
              ButtonSegment<UserRole?>(
                value: null,
                label: Text('All (${widget.supplements.length})'),
              ),
              ButtonSegment<UserRole?>(
                value: UserRole.wife,
                label: Text('👩 Wife ($wifeCount)'),
              ),
              ButtonSegment<UserRole?>(
                value: UserRole.husband,
                label: Text('👨 Husband ($husbandCount)'),
              ),
            ],
            selected: {_filterRole},
            onSelectionChanged: (Set<UserRole?> newSelection) {
              setState(() {
                _filterRole = newSelection.first;
              });
            },
          ),
        ),

        if (displayedSupplements.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 40,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No supplements found for this filter.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...displayedSupplements.map((item) {
            final isWife = item.targetRole == UserRole.wife;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isWife
                                          ? theme.colorScheme.primaryContainer
                                                .withValues(alpha: 0.7)
                                          : theme.colorScheme.secondaryContainer
                                                .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isWife ? '👩 Wife' : '👨 Husband',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isWife
                                            ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                            : theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
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
                          onPressed: widget.onEdit != null
                              ? () => widget.onEdit!(item)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: theme.colorScheme.error,
                          tooltip: 'Delete Supplement',
                          onPressed: widget.onDelete != null
                              ? () => widget.onDelete!(item)
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
          }),
      ],
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
