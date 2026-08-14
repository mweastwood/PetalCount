import 'package:flutter/material.dart';

import '../../logic/models/observation.dart';
import 'option_card.dart';

class BleedingStepCard extends StatelessWidget {
  final bool isFlowStep;
  final bool showNoBleeding;
  final bool? hasBleeding;
  final Bleeding? bleedingFlow;
  final String? bleedingColor;
  final VoidCallback? onSelectNoBleeding;
  final ValueChanged<Bleeding>? onSelectFlow;
  final ValueChanged<String>? onSelectColor;

  const BleedingStepCard({
    super.key,
    this.isFlowStep = true,
    this.showNoBleeding = true,
    this.hasBleeding,
    this.bleedingFlow,
    this.bleedingColor,
    this.onSelectNoBleeding,
    this.onSelectFlow,
    this.onSelectColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isFlowStep) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showNoBleeding
                  ? 'Are you experiencing bleeding at this point in time?'
                  : 'Select Bleeding Flow Level',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              showNoBleeding
                  ? 'Select "No Bleeding" or choose the bleeding flow level observed right now:'
                  : 'Choose the bleeding flow level observed right now:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            OptionGrid(
              fullWidthIndexes: showNoBleeding ? const [0] : null,
              children: [
                if (showNoBleeding)
                  OptionCard(
                    label: 'No Bleeding',
                    icon: Icons.block,
                    subtitle: 'No bleeding present',
                    isSelected: hasBleeding == false,
                    onTap: () => onSelectNoBleeding?.call(),
                  ),
                OptionCard(
                  label: 'Heavy (H)',
                  icon: Icons.water_drop,
                  subtitle: 'Heavy flow',
                  isSelected:
                      hasBleeding == true && bleedingFlow == Bleeding.heavy,
                  onTap: () => onSelectFlow?.call(Bleeding.heavy),
                ),
                OptionCard(
                  label: 'Moderate (M)',
                  icon: Icons.water_drop_outlined,
                  subtitle: 'Moderate flow',
                  isSelected:
                      hasBleeding == true && bleedingFlow == Bleeding.moderate,
                  onTap: () => onSelectFlow?.call(Bleeding.moderate),
                ),
                OptionCard(
                  label: 'Light (L)',
                  icon: Icons.opacity,
                  subtitle: 'Light flow',
                  isSelected:
                      hasBleeding == true && bleedingFlow == Bleeding.light,
                  onTap: () => onSelectFlow?.call(Bleeding.light),
                ),
                OptionCard(
                  label: 'Very Light (VL)',
                  icon: Icons.grain,
                  subtitle: 'Very light flow / spotting',
                  isSelected:
                      hasBleeding == true && bleedingFlow == Bleeding.veryLight,
                  onTap: () => onSelectFlow?.call(Bleeding.veryLight),
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
            'Blood Color',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the observed color of blood:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OptionGrid(
            fullWidthIndexes: const [0],
            children: [
              OptionCard(
                label: 'Red (R)',
                icon: Icons.color_lens,
                subtitle: 'Bright or dark red blood',
                isSelected: bleedingColor == Bleeding.red.code,
                onTap: () => onSelectColor?.call(Bleeding.red.code),
              ),
              OptionCard(
                label: 'Brown (B)',
                icon: Icons.color_lens_outlined,
                subtitle: 'Brownish discharge',
                isSelected: bleedingColor == Bleeding.brown.code,
                onTap: () => onSelectColor?.call(Bleeding.brown.code),
              ),
              OptionCard(
                label: 'Black (K)',
                icon: Icons.circle,
                subtitle: 'Blackish old blood',
                isSelected: bleedingColor == MucusColor.clear.code,
                onTap: () => onSelectColor?.call(MucusColor.clear.code),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
