import 'package:flutter/material.dart';

import '../../logic/models/observation.dart';
import 'option_card.dart';

class FrequencyStepCard extends StatelessWidget {
  final Frequency frequency;
  final ValueChanged<Frequency> onSelectFrequency;

  const FrequencyStepCard({
    super.key,
    required this.frequency,
    required this.onSelectFrequency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observation Frequency',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How often did you observe this symptom or mucus today?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OptionGrid(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            children: [
              OptionCard(
                label: 'All Day (AD)',
                subtitle: 'Continuous / throughout day',
                icon: Icons.all_inclusive,
                isSelected: frequency == Frequency.allDay,
                onTap: () => onSelectFrequency(Frequency.allDay),
              ),
              OptionCard(
                label: 'Once (x1)',
                subtitle: 'Observed 1 time',
                icon: Icons.looks_one_outlined,
                isSelected: frequency == Frequency.once,
                onTap: () => onSelectFrequency(Frequency.once),
              ),
              OptionCard(
                label: 'Twice (x2)',
                subtitle: 'Observed 2 times',
                icon: Icons.looks_two_outlined,
                isSelected: frequency == Frequency.twice,
                onTap: () => onSelectFrequency(Frequency.twice),
              ),
              OptionCard(
                label: 'Three Times (x3)',
                subtitle: 'Observed 3 times',
                icon: Icons.looks_3_outlined,
                isSelected: frequency == Frequency.thrice,
                onTap: () => onSelectFrequency(Frequency.thrice),
              ),
              OptionCard(
                label: 'None / Unspecified',
                subtitle: 'Single observation timestamp',
                icon: Icons.remove_circle_outline,
                isSelected: frequency == Frequency.none,
                onTap: () => onSelectFrequency(Frequency.none),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
