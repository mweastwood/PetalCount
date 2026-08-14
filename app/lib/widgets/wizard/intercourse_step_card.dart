import 'package:flutter/material.dart';
import 'option_card.dart';

class IntercourseStepCard extends StatelessWidget {
  final bool? hasIntercourse;
  final ValueChanged<bool>? onSelectIntercourse;

  const IntercourseStepCard({
    super.key,
    this.hasIntercourse,
    this.onSelectIntercourse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Intercourse / Intimacy',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Record whether intercourse occurred at this observation time:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OptionGrid(
            children: [
              OptionCard(
                label: 'Intercourse (I)',
                icon: Icons.favorite,
                subtitle: 'Intercourse occurred',
                isSelected: hasIntercourse == true,
                onTap: () => onSelectIntercourse?.call(true),
              ),
              OptionCard(
                label: 'No Intercourse',
                icon: Icons.do_not_disturb_alt,
                subtitle: 'No intercourse recorded',
                isSelected: hasIntercourse == false,
                onTap: () => onSelectIntercourse?.call(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
