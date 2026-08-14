import 'package:flutter/material.dart';
import '../../logic/models/observation.dart';
import 'option_card.dart';

enum MucusSubStep { presence, stretch, color, consistency }

class MucusStepCard extends StatelessWidget {
  final MucusSubStep subStep;
  final bool? hasMucus;
  final Stretch? stretch;
  final List<MucusColor> selectedColors;
  final bool isGummy;
  final bool isPasty;
  final bool hasSelectedConsistency;
  final ValueChanged<bool>? onSelectHasMucus;
  final ValueChanged<Stretch>? onSelectStretch;
  final ValueChanged<List<MucusColor>>? onSelectColors;
  final void Function({required bool isGummy, required bool isPasty})?
  onSelectConsistency;

  const MucusStepCard({
    super.key,
    required this.subStep,
    this.hasMucus,
    this.stretch,
    this.selectedColors = const [],
    this.isGummy = false,
    this.isPasty = false,
    this.hasSelectedConsistency = false,
    this.onSelectHasMucus,
    this.onSelectStretch,
    this.onSelectColors,
    this.onSelectConsistency,
  });

  bool _isColorSelected(List<MucusColor> target) {
    if (selectedColors.length != target.length) return false;
    for (final c in target) {
      if (!selectedColors.contains(c)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (subStep) {
      case MucusSubStep.presence:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mucus Observation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Do you observe any visible mucus at this observation?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              OptionGrid(
                children: [
                  OptionCard(
                    label: 'No Mucus',
                    icon: Icons.block,
                    subtitle: 'No visible mucus observed',
                    isSelected: hasMucus == false,
                    onTap: () => onSelectHasMucus?.call(false),
                  ),
                  OptionCard(
                    label: 'Yes Mucus',
                    icon: Icons.bubble_chart,
                    subtitle: 'Visible mucus present',
                    isSelected: hasMucus == true,
                    onTap: () => onSelectHasMucus?.call(true),
                  ),
                ],
              ),
            ],
          ),
        );

      case MucusSubStep.stretch:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finger Test Stretch',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'When performing the finger test, how far does the mucus stretch before breaking?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: OptionCard(
                      label: 'Sticky',
                      icon: Icons.straighten,
                      subtitle: '< 1/4 inch stretch',
                      isSelected: stretch == Stretch.sticky,
                      onTap: () => onSelectStretch?.call(Stretch.sticky),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 0.75,
                    child: OptionCard(
                      label: 'Tacky',
                      icon: Icons.height,
                      subtitle: '1/4 to 3/4 inch stretch',
                      isSelected: stretch == Stretch.tacky,
                      onTap: () => onSelectStretch?.call(Stretch.tacky),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 1.0,
                    child: OptionCard(
                      label: 'Stretchy (10)',
                      icon: Icons.unfold_more,
                      subtitle: '>= 1 inch stretch',
                      isSelected: stretch == Stretch.stretchy,
                      onTap: () => onSelectStretch?.call(Stretch.stretchy),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case MucusSubStep.color:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mucus Color',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the observed color of the mucus:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              OptionGrid(
                childAspectRatio: 2.1,
                children: [
                  OptionCard(
                    label: 'Cloudy (C)',
                    icon: Icons.cloud_outlined,
                    subtitle: 'Opaque / off-white',
                    isSelected: _isColorSelected([MucusColor.cloudy]),
                    onTap: () => onSelectColors?.call([MucusColor.cloudy]),
                  ),
                  OptionCard(
                    label: 'Clear (K)',
                    icon: Icons.water_drop_outlined,
                    subtitle: 'Transparent egg-white',
                    isSelected: _isColorSelected([MucusColor.clear]),
                    onTap: () => onSelectColors?.call([MucusColor.clear]),
                  ),
                  OptionCard(
                    label: 'Cloudy/Clear (C/K)',
                    icon: Icons.wb_cloudy_outlined,
                    subtitle: 'Mix of clear & cloudy',
                    isSelected: _isColorSelected([
                      MucusColor.cloudy,
                      MucusColor.clear,
                    ]),
                    onTap: () => onSelectColors?.call([
                      MucusColor.cloudy,
                      MucusColor.clear,
                    ]),
                  ),
                  OptionCard(
                    label: 'Yellow (Y)',
                    icon: Icons.circle_outlined,
                    subtitle: 'Yellowish tinge',
                    isSelected: _isColorSelected([MucusColor.yellow]),
                    onTap: () => onSelectColors?.call([MucusColor.yellow]),
                  ),
                  OptionCard(
                    label: 'Red (R)',
                    icon: Icons.water_drop,
                    subtitle: 'Red-tinged / bleeding',
                    isSelected: _isColorSelected([MucusColor.red]),
                    onTap: () => onSelectColors?.call([MucusColor.red]),
                  ),
                  OptionCard(
                    label: 'Black/Brown (B)',
                    icon: Icons.circle,
                    subtitle: 'Brown or blackish',
                    isSelected: _isColorSelected([MucusColor.brown]),
                    onTap: () => onSelectColors?.call([MucusColor.brown]),
                  ),
                ],
              ),
            ],
          ),
        );

      case MucusSubStep.consistency:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mucus Consistency',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Optionally select special physical characteristics of the mucus:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              OptionGrid(
                fullWidthIndexes: const [0],
                children: [
                  OptionCard(
                    label: 'Neither',
                    icon: Icons.do_not_disturb_alt,
                    subtitle: 'Standard mucus consistency',
                    isSelected:
                        !isGummy && !isPasty && hasSelectedConsistency,
                    onTap: () => onSelectConsistency?.call(
                      isGummy: false,
                      isPasty: false,
                    ),
                  ),
                  OptionCard(
                    label: 'Gummy (Gluey)',
                    icon: Icons.bubble_chart_outlined,
                    subtitle: 'Rubber-like or gluey texture',
                    isSelected: isGummy && !isPasty,
                    onTap: () => onSelectConsistency?.call(
                      isGummy: true,
                      isPasty: false,
                    ),
                  ),
                  OptionCard(
                    label: 'Pasty (Creamy)',
                    icon: Icons.format_paint_outlined,
                    subtitle: 'Creamy or pasty texture',
                    isSelected: isPasty && !isGummy,
                    onTap: () => onSelectConsistency?.call(
                      isGummy: false,
                      isPasty: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }
}
