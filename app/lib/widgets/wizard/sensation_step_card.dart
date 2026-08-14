import 'package:flutter/material.dart';
import '../../logic/models/observation.dart';
import 'option_card.dart';

class SensationStepCard extends StatelessWidget {
  final bool isLubricationStep;
  final Sensation? sensation;
  final bool? hasLubrication;
  final ValueChanged<Sensation>? onSelectSensation;
  final ValueChanged<bool>? onSelectLubrication;

  const SensationStepCard({
    super.key,
    this.isLubricationStep = false,
    this.sensation,
    this.hasLubrication,
    this.onSelectSensation,
    this.onSelectLubrication,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLubricationStep) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lubricative Sensation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Was there a distinctly lubricative or slippery sensation?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            OptionGrid(
              children: [
                OptionCard(
                  label: 'Not Lubricative',
                  icon: Icons.do_not_disturb,
                  subtitle: 'No slippery feeling',
                  isSelected: hasLubrication == false,
                  onTap: () => onSelectLubrication?.call(false),
                ),
                OptionCard(
                  label: 'Yes Lubrication',
                  icon: Icons.clean_hands,
                  subtitle: 'Slippery / lubricative feel',
                  isSelected: hasLubrication == true,
                  onTap: () => onSelectLubrication?.call(true),
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
            'Sensation at Vulva',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What sensation do you feel at the vulva right now during normal daily routine?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OptionGrid(
            children: [
              OptionCard(
                label: 'Dry',
                icon: Icons.wb_sunny_outlined,
                subtitle: 'No sensation of moisture',
                isSelected: sensation == Sensation.dry,
                onTap: () => onSelectSensation?.call(Sensation.dry),
              ),
              OptionCard(
                label: 'Wet',
                icon: Icons.water,
                subtitle: 'Definite sensation of moisture',
                isSelected: sensation == Sensation.wet,
                onTap: () => onSelectSensation?.call(Sensation.wet),
              ),
              OptionCard(
                label: 'Damp',
                icon: Icons.opacity,
                subtitle: 'Slight feeling of dampness',
                isSelected: sensation == Sensation.damp,
                onTap: () => onSelectSensation?.call(Sensation.damp),
              ),
              OptionCard(
                label: 'Shiny / Smooth',
                icon: Icons.auto_awesome,
                subtitle: 'Slick or smooth feeling',
                isSelected: sensation == Sensation.shiny,
                onTap: () => onSelectSensation?.call(Sensation.shiny),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
