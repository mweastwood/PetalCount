import 'package:flutter/material.dart';
import 'option_card.dart';

class PainStepCard extends StatelessWidget {
  final bool isDetailsStep;
  final bool? hasPain;
  final List<String> painTypes;
  final bool abdominalLeft;
  final bool abdominalRight;
  final double painLevel;
  final ValueChanged<bool>? onSelectHasPain;
  final void Function(String type, bool isSelected)? onTogglePainType;
  final ValueChanged<bool>? onToggleAbdominalLeft;
  final ValueChanged<bool>? onToggleAbdominalRight;
  final ValueChanged<double>? onPainLevelChanged;

  const PainStepCard({
    super.key,
    this.isDetailsStep = false,
    this.hasPain,
    this.painTypes = const [],
    this.abdominalLeft = false,
    this.abdominalRight = false,
    this.painLevel = 3.0,
    this.onSelectHasPain,
    this.onTogglePainType,
    this.onToggleAbdominalLeft,
    this.onToggleAbdominalRight,
    this.onPainLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isDetailsStep) {
      final isAbdominalSelected = painTypes.contains('Abdominal Pain');

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pain Location & Severity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select pain location and severity rating:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Location / Type:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Cramps',
                    'Abdominal Pain',
                    'Backache',
                    'Headache',
                    'Pelvic Pain',
                  ].map((p) {
                    final isSelected = painTypes.contains(p);
                    return FilterChip(
                      showCheckmark: false,
                      label: Text(p),
                      selected: isSelected,
                      onSelected: (val) {
                        onTogglePainType?.call(p, val);
                      },
                    );
                  }).toList(),
            ),
            if (isAbdominalSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Abdominal Side (Optional):',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      showCheckmark: false,
                      label: const Text('Left'),
                      selected: abdominalLeft,
                      onSelected: (val) {
                        onToggleAbdominalLeft?.call(val);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      showCheckmark: false,
                      label: const Text('Right'),
                      selected: abdominalRight,
                      onSelected: (val) {
                        onToggleAbdominalRight?.call(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Severity Rating:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: painLevel,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: '${painLevel.toInt()}/10',
                    onChanged: (val) => onPainLevelChanged?.call(val),
                  ),
                ),
                Text(
                  '${painLevel.toInt()}/10',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pain or Symptoms',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Are you experiencing any physical pain or cramps right now?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OptionGrid(
            children: [
              OptionCard(
                label: 'No Pain',
                icon: Icons.sentiment_satisfied_alt,
                subtitle: 'No discomfort experienced',
                isSelected: hasPain == false,
                onTap: () => onSelectHasPain?.call(false),
              ),
              OptionCard(
                label: 'Yes (Log Pain)',
                icon: Icons.healing,
                subtitle: 'Cramps, abdominal pain, etc.',
                isSelected: hasPain == true,
                onTap: () => onSelectHasPain?.call(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
