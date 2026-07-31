import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic/logic.dart';

enum ObservationCategory {
  full('Log Single Observation'),
  mucus('Log Mucus Observation'),
  bleeding('Log Bleeding'),
  intercourse('Log Intercourse'),
  pain('Log Pain');

  final String dialogTitle;
  const ObservationCategory(this.dialogTitle);
}

enum WizardStep {
  bleedingFlow('Bleeding'),
  bleedingColor('Blood Color'),
  sensation('Sensation'),
  lubrication('Lubrication'),
  mucus('Mucus'),
  mucusStretch('Stretch'),
  mucusColor('Mucus Color'),
  mucusConsistency('Consistency'),
  intercourse('Intercourse'),
  pain('Pain'),
  painDetails('Pain Details'),
  comments('Comments & Save');

  final String title;
  const WizardStep(this.title);
}

class AddObservationDialog extends StatefulWidget {
  final Cycle? cycle;
  final DateTime defaultDate;
  final ObservationCategory category;

  const AddObservationDialog({
    super.key,
    this.cycle,
    required this.defaultDate,
    this.category = ObservationCategory.full,
  });

  @override
  State<AddObservationDialog> createState() => _AddObservationDialogState();
}

class _AddObservationDialogState extends State<AddObservationDialog> {
  int _currentStepIndex = 0;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  // Bleeding (nullable so no option is pre-selected)
  bool? _hasBleeding;
  Bleeding? _bleedingFlow;
  String? _bleedingColor;

  // Sensation (nullable so no option is pre-selected)
  Sensation? _sensation;
  bool? _hasLubrication;

  // Mucus Observation (nullable so no option is pre-selected)
  bool? _hasMucus;
  Stretch? _stretch;
  String? _colorSelection; // 'cloudy', 'clear', 'cloudy_clear', 'yellow'
  bool _isGummy = false;
  bool _isPasty = false;
  bool _hasSelectedConsistency = false;

  // Pain (nullable so no option is pre-selected)
  bool? _hasPain;
  final List<String> _painTypes = [];
  bool _abdominalLeft = false;
  bool _abdominalRight = false;
  double _painLevel = 3.0;

  List<String> get _formattedPainTypes {
    final list = <String>[];
    for (final p in _painTypes) {
      if (p == 'Abdominal Pain') {
        if (_abdominalLeft && _abdominalRight) {
          list.add('Abdominal Pain (Left & Right)');
        } else if (_abdominalLeft) {
          list.add('Abdominal Pain (Left)');
        } else if (_abdominalRight) {
          list.add('Abdominal Pain (Right)');
        } else {
          list.add('Abdominal Pain');
        }
      } else {
        list.add(p);
      }
    }
    return list;
  }

  // Intercourse (nullable so no option is pre-selected)
  bool? _hasIntercourse;

  // Comments
  final _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.defaultDate.year,
      widget.defaultDate.month,
      widget.defaultDate.day,
    );
    _selectedTime = TimeOfDay(
      hour: widget.defaultDate.hour,
      minute: widget.defaultDate.minute,
    );

    if (widget.category == ObservationCategory.intercourse) {
      _hasIntercourse = true;
    } else if (widget.category == ObservationCategory.bleeding) {
      _hasBleeding = true;
    } else if (widget.category == ObservationCategory.pain) {
      _hasPain = true;
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  bool get _isHeavyOrModerateBleeding =>
      _hasBleeding == true &&
      (_bleedingFlow == Bleeding.heavy || _bleedingFlow == Bleeding.moderate);

  List<WizardStep> get _activeSteps {
    if (widget.category == ObservationCategory.bleeding) {
      final steps = [WizardStep.bleedingFlow];
      if (_hasBleeding == true) {
        steps.add(WizardStep.bleedingColor);
      }
      steps.add(WizardStep.comments);
      return steps;
    }

    if (widget.category == ObservationCategory.mucus) {
      final steps = <WizardStep>[WizardStep.sensation];
      if (_sensation != null && _sensation != Sensation.dry) {
        steps.add(WizardStep.lubrication);
      }
      steps.add(WizardStep.mucus);
      if (_hasMucus == true) {
        steps.add(WizardStep.mucusStretch);
        steps.add(WizardStep.mucusColor);
        steps.add(WizardStep.mucusConsistency);
      }
      steps.add(WizardStep.comments);
      return steps;
    }

    if (widget.category == ObservationCategory.intercourse) {
      return [WizardStep.comments];
    }

    if (widget.category == ObservationCategory.pain) {
      return [WizardStep.painDetails, WizardStep.comments];
    }

    final steps = [WizardStep.bleedingFlow];
    if (_hasBleeding == true) {
      steps.add(WizardStep.bleedingColor);
    }
    if (!_isHeavyOrModerateBleeding) {
      steps.add(WizardStep.sensation);
      if (_sensation != null && _sensation != Sensation.dry) {
        steps.add(WizardStep.lubrication);
      }
      steps.add(WizardStep.mucus);
      if (_hasMucus == true) {
        steps.add(WizardStep.mucusStretch);
        steps.add(WizardStep.mucusColor);
        steps.add(WizardStep.mucusConsistency);
      }
    }
    steps.add(WizardStep.pain);
    if (_hasPain == true) {
      steps.add(WizardStep.painDetails);
    }
    steps.add(WizardStep.comments);
    return steps;
  }

  WizardStep get _currentStep {
    final steps = _activeSteps;
    if (_currentStepIndex >= steps.length) {
      return steps.last;
    }
    return steps[_currentStepIndex];
  }

  void _nextStep() {
    final steps = _activeSteps;
    if (_currentStepIndex < steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSteps = _activeSteps;
    final step = _currentStep;
    final isFirstStep = _currentStepIndex == 0;
    final isLastStep = _currentStepIndex == activeSteps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.category.dialogTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date / Time Pickers
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 6.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _pickTime,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedTime.format(context),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Step Progress Indicator
              Row(
                children: [
                  Text(
                    'Step ${_currentStepIndex + 1} of ${activeSteps.length}: ${step.title}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (_currentStepIndex + 1) / activeSteps.length,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),

              // Step Content Area
              Expanded(child: _buildStepContent(context, step)),

              if (!isFirstStep ||
                  step == WizardStep.painDetails ||
                  isLastStep ||
                  (step != WizardStep.bleedingFlow &&
                      step != WizardStep.bleedingColor &&
                      step != WizardStep.sensation &&
                      step != WizardStep.lubrication &&
                      step != WizardStep.mucus &&
                      step != WizardStep.mucusStretch &&
                      step != WizardStep.mucusColor &&
                      step != WizardStep.mucusConsistency &&
                      step != WizardStep.intercourse &&
                      step != WizardStep.pain &&
                      step != WizardStep.painDetails)) ...[
                const SizedBox(height: 12),
                // Footer Navigation
                Row(
                  children: [
                    if (!isFirstStep)
                      OutlinedButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back'),
                      ),
                    if (step == WizardStep.painDetails) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _nextStep,
                        child: const Text('Continue'),
                      ),
                    ],
                    const Spacer(),
                    if (isLastStep)
                      _isSaving
                          ? const CircularProgressIndicator()
                          : FilledButton.icon(
                              onPressed: _saveLog,
                              icon: const Icon(Icons.check),
                              label: const Text('Save Observation'),
                            )
                    else if (step != WizardStep.bleedingFlow &&
                        step != WizardStep.bleedingColor &&
                        step != WizardStep.sensation &&
                        step != WizardStep.lubrication &&
                        step != WizardStep.mucus &&
                        step != WizardStep.mucusStretch &&
                        step != WizardStep.mucusColor &&
                        step != WizardStep.mucusConsistency &&
                        step != WizardStep.intercourse &&
                        step != WizardStep.pain &&
                        step != WizardStep.painDetails)
                      TextButton(
                        onPressed: _nextStep,
                        child: const Text('Skip / Next'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionGrid({
    required List<Widget> children,
    int crossAxisCount = 2,
    double childAspectRatio = 1.6,
    List<int>? fullWidthIndexes,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveColumns = constraints.maxWidth < 380
            ? 1
            : crossAxisCount;
        final responsiveAspectRatio = constraints.maxWidth < 380
            ? 2.8
            : childAspectRatio;

        if (fullWidthIndexes != null &&
            fullWidthIndexes.isNotEmpty &&
            responsiveColumns > 1) {
          final gridItems = <Widget>[];
          for (int i = 0; i < children.length; i++) {
            if (fullWidthIndexes.contains(i)) {
              gridItems.add(
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: children[i],
                ),
              );
            } else {
              int pairEnd = i;
              final pair = <Widget>[];
              while (pairEnd < children.length &&
                  !fullWidthIndexes.contains(pairEnd) &&
                  pair.length < responsiveColumns) {
                pair.add(Expanded(child: children[pairEnd]));
                pairEnd++;
              }
              i = pairEnd - 1;
              gridItems.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int p = 0; p < pair.length; p++) ...[
                      if (p > 0) const SizedBox(width: 10),
                      pair[p],
                    ],
                    if (pair.length < responsiveColumns)
                      for (
                        int pad = 0;
                        pad < responsiveColumns - pair.length;
                        pad++
                      ) ...[const SizedBox(width: 10), const Spacer()],
                  ],
                ),
              );
            }
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int k = 0; k < gridItems.length; k++) ...[
                if (k > 0) const SizedBox(height: 10),
                gridItems[k],
              ],
            ],
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: responsiveColumns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: responsiveAspectRatio,
          children: children,
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context, WizardStep step) {
    final theme = Theme.of(context);

    switch (step) {
      case WizardStep.bleedingFlow:
        final showNoBleeding = widget.category != ObservationCategory.bleeding;

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
              _buildOptionGrid(
                fullWidthIndexes: showNoBleeding ? const [0] : null,
                children: [
                  if (showNoBleeding)
                    _OptionCard(
                      label: 'No Bleeding',
                      icon: Icons.block,
                      subtitle: 'No bleeding present',
                      isSelected: _hasBleeding == false,
                      onTap: () {
                        setState(() {
                          _hasBleeding = false;
                          _bleedingFlow = Bleeding.none;
                          _bleedingColor = null;
                        });
                        _nextStep();
                      },
                    ),
                  _OptionCard(
                    label: 'Heavy (H)',
                    icon: Icons.water_drop,
                    subtitle: 'Heavy flow',
                    isSelected:
                        _hasBleeding == true && _bleedingFlow == Bleeding.heavy,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.heavy;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Moderate (M)',
                    icon: Icons.water_drop_outlined,
                    subtitle: 'Moderate flow',
                    isSelected:
                        _hasBleeding == true &&
                        _bleedingFlow == Bleeding.moderate,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.moderate;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Light (L)',
                    icon: Icons.opacity,
                    subtitle: 'Light flow',
                    isSelected:
                        _hasBleeding == true && _bleedingFlow == Bleeding.light,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.light;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Very Light (VL)',
                    icon: Icons.grain,
                    subtitle: 'Very light flow / spotting',
                    isSelected:
                        _hasBleeding == true &&
                        _bleedingFlow == Bleeding.veryLight,
                    onTap: () {
                      setState(() {
                        _hasBleeding = true;
                        _bleedingFlow = Bleeding.veryLight;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.bleedingColor:
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
              _buildOptionGrid(
                fullWidthIndexes: const [0],
                children: [
                  _OptionCard(
                    label: 'Red (R)',
                    icon: Icons.color_lens,
                    subtitle: 'Bright or dark red blood',
                    isSelected: _bleedingColor == 'R',
                    onTap: () {
                      setState(() {
                        _bleedingColor = 'R';
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Brown (B)',
                    icon: Icons.color_lens_outlined,
                    subtitle: 'Brownish discharge',
                    isSelected: _bleedingColor == 'B',
                    onTap: () {
                      setState(() {
                        _bleedingColor = 'B';
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Black (K)',
                    icon: Icons.circle,
                    subtitle: 'Blackish old blood',
                    isSelected: _bleedingColor == 'K',
                    onTap: () {
                      setState(() {
                        _bleedingColor = 'K';
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.sensation:
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
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'Dry',
                    icon: Icons.wb_sunny_outlined,
                    subtitle: 'No sensation of moisture',
                    isSelected: _sensation == Sensation.dry,
                    onTap: () {
                      setState(() {
                        _sensation = Sensation.dry;
                        _hasLubrication = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Wet',
                    icon: Icons.water,
                    subtitle: 'Definite sensation of moisture',
                    isSelected: _sensation == Sensation.wet,
                    onTap: () {
                      setState(() {
                        _sensation = Sensation.wet;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Damp',
                    icon: Icons.opacity,
                    subtitle: 'Slight feeling of dampness',
                    isSelected: _sensation == Sensation.damp,
                    onTap: () {
                      setState(() {
                        _sensation = Sensation.damp;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Shiny / Smooth',
                    icon: Icons.auto_awesome,
                    subtitle: 'Slick or smooth feeling',
                    isSelected: _sensation == Sensation.shiny,
                    onTap: () {
                      setState(() {
                        _sensation = Sensation.shiny;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.lubrication:
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
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'Not Lubricative',
                    icon: Icons.do_not_disturb,
                    subtitle: 'No slippery feeling',
                    isSelected: _hasLubrication == false,
                    onTap: () {
                      setState(() {
                        _hasLubrication = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yes Lubrication',
                    icon: Icons.clean_hands,
                    subtitle: 'Slippery / lubricative feel',
                    isSelected: _hasLubrication == true,
                    onTap: () {
                      setState(() {
                        _hasLubrication = true;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucus:
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
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'No Mucus',
                    icon: Icons.block,
                    subtitle: 'No visible mucus observed',
                    isSelected: _hasMucus == false,
                    onTap: () {
                      setState(() {
                        _hasMucus = false;
                        _stretch = Stretch.none;
                        _colorSelection = null;
                        _isGummy = false;
                        _isPasty = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yes Mucus',
                    icon: Icons.bubble_chart,
                    subtitle: 'Visible mucus present',
                    isSelected: _hasMucus == true,
                    onTap: () {
                      setState(() {
                        _hasMucus = true;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucusStretch:
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
                    child: _OptionCard(
                      label: 'Sticky',
                      icon: Icons.straighten,
                      subtitle: '< 1/4 inch stretch',
                      isSelected: _stretch == Stretch.sticky,
                      onTap: () {
                        setState(() {
                          _stretch = Stretch.sticky;
                        });
                        _nextStep();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 0.75,
                    child: _OptionCard(
                      label: 'Tacky',
                      icon: Icons.height,
                      subtitle: '1/4 to 3/4 inch stretch',
                      isSelected: _stretch == Stretch.tacky,
                      onTap: () {
                        setState(() {
                          _stretch = Stretch.tacky;
                        });
                        _nextStep();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 1.0,
                    child: _OptionCard(
                      label: 'Stretchy (10)',
                      icon: Icons.unfold_more,
                      subtitle: '>= 1 inch stretch',
                      isSelected: _stretch == Stretch.stretchy,
                      onTap: () {
                        setState(() {
                          _stretch = Stretch.stretchy;
                        });
                        _nextStep();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucusColor:
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
              _buildOptionGrid(
                childAspectRatio: 2.1,
                children: [
                  _OptionCard(
                    label: 'Cloudy (C)',
                    icon: Icons.cloud_outlined,
                    subtitle: 'Opaque / off-white',
                    isSelected: _colorSelection == 'cloudy',
                    onTap: () {
                      setState(() {
                        _colorSelection = 'cloudy';
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Clear (K)',
                    icon: Icons.water_drop_outlined,
                    subtitle: 'Transparent egg-white',
                    isSelected: _colorSelection == 'clear',
                    onTap: () {
                      setState(() {
                        _colorSelection = 'clear';
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Cloudy/Clear (C/K)',
                    icon: Icons.wb_cloudy_outlined,
                    subtitle: 'Mix of clear & cloudy',
                    isSelected: _colorSelection == 'cloudy_clear',
                    onTap: () {
                      setState(() {
                        _colorSelection = 'cloudy_clear';
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yellow (Y)',
                    icon: Icons.circle_outlined,
                    subtitle: 'Yellowish tinge',
                    isSelected: _colorSelection == 'yellow',
                    onTap: () {
                      setState(() {
                        _colorSelection = 'yellow';
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Red (R)',
                    icon: Icons.water_drop,
                    subtitle: 'Red-tinged / bleeding',
                    isSelected: _colorSelection == 'red',
                    onTap: () {
                      setState(() {
                        _colorSelection = 'red';
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Black/Brown (B)',
                    icon: Icons.circle,
                    subtitle: 'Brown or blackish',
                    isSelected: _colorSelection == 'brown',
                    onTap: () {
                      setState(() {
                        _colorSelection = 'brown';
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.mucusConsistency:
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
              _buildOptionGrid(
                fullWidthIndexes: const [0],
                children: [
                  _OptionCard(
                    label: 'Neither',
                    icon: Icons.do_not_disturb_alt,
                    subtitle: 'Standard mucus consistency',
                    isSelected:
                        !_isGummy && !_isPasty && _hasSelectedConsistency,
                    onTap: () {
                      setState(() {
                        _isGummy = false;
                        _isPasty = false;
                        _hasSelectedConsistency = true;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Gummy (Gluey)',
                    icon: Icons.bubble_chart_outlined,
                    subtitle: 'Rubber-like or gluey texture',
                    isSelected: _isGummy && !_isPasty,
                    onTap: () {
                      setState(() {
                        _isGummy = true;
                        _isPasty = false;
                        _hasSelectedConsistency = true;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Pasty (Creamy)',
                    icon: Icons.format_paint_outlined,
                    subtitle: 'Creamy or pasty texture',
                    isSelected: _isPasty && !_isGummy,
                    onTap: () {
                      setState(() {
                        _isGummy = false;
                        _isPasty = true;
                        _hasSelectedConsistency = true;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.intercourse:
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
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'Intercourse (I)',
                    icon: Icons.favorite,
                    subtitle: 'Intercourse occurred',
                    isSelected: _hasIntercourse == true,
                    onTap: () {
                      setState(() {
                        _hasIntercourse = true;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'No Intercourse',
                    icon: Icons.do_not_disturb_alt,
                    subtitle: 'No intercourse recorded',
                    isSelected: _hasIntercourse == false,
                    onTap: () {
                      setState(() {
                        _hasIntercourse = false;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.pain:
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
              _buildOptionGrid(
                children: [
                  _OptionCard(
                    label: 'No Pain',
                    icon: Icons.sentiment_satisfied_alt,
                    subtitle: 'No discomfort experienced',
                    isSelected: _hasPain == false,
                    onTap: () {
                      setState(() {
                        _hasPain = false;
                      });
                      _nextStep();
                    },
                  ),
                  _OptionCard(
                    label: 'Yes (Log Pain)',
                    icon: Icons.healing,
                    subtitle: 'Cramps, abdominal pain, etc.',
                    isSelected: _hasPain == true,
                    onTap: () {
                      setState(() {
                        _hasPain = true;
                      });
                      _nextStep();
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case WizardStep.painDetails:
        final isAbdominalSelected = _painTypes.contains('Abdominal Pain');

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
                      final isSelected = _painTypes.contains(p);
                      return FilterChip(
                        showCheckmark: false,
                        label: Text(p),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _painTypes.add(p);
                            } else {
                              _painTypes.remove(p);
                            }
                          });
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
                        selected: _abdominalLeft,
                        onSelected: (val) {
                          setState(() => _abdominalLeft = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        showCheckmark: false,
                        label: const Text('Right'),
                        selected: _abdominalRight,
                        onSelected: (val) {
                          setState(() => _abdominalRight = val);
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
                      value: _painLevel,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: '${_painLevel.toInt()}/10',
                      onChanged: (val) => setState(() => _painLevel = val),
                    ),
                  ),
                  Text(
                    '${_painLevel.toInt()}/10',
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

      case WizardStep.comments:
        final cat = widget.category;
        final showBleeding =
            cat == ObservationCategory.full ||
            cat == ObservationCategory.bleeding;
        final showMucus =
            (cat == ObservationCategory.full ||
                cat == ObservationCategory.mucus) &&
            !_isHeavyOrModerateBleeding;
        final showPain =
            cat == ObservationCategory.full || cat == ObservationCategory.pain;
        final showIntercourse =
            cat == ObservationCategory.full ||
            cat == ObservationCategory.intercourse;

        final hasBleeding = _hasBleeding ?? false;
        final flowLabel = _bleedingFlow != null
            ? _bleedingFlow!.label
            : 'Light';

        String bleedingColorName = '';
        if (_bleedingColor == 'R') bleedingColorName = 'Red';
        if (_bleedingColor == 'B') bleedingColorName = 'Brown';
        if (_bleedingColor == 'K') bleedingColorName = 'Black';

        final hasMucus = _hasMucus ?? false;
        final hasPain = _hasPain ?? false;
        final hasLubrication = _hasLubrication ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary & Additional Notes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Summary Badge Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Observation Summary:',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy • h:mm a').format(_combinedDateTime)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (showBleeding)
                    Text(
                      'Bleeding: ${hasBleeding ? "$flowLabel${bleedingColorName.isNotEmpty ? ', $bleedingColorName' : ''}" : "None"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (showMucus) ...[
                    Text(
                      'Sensation: ${_sensation?.label ?? "Dry"}${hasLubrication ? " (Lubricative)" : ""}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Mucus: ${hasMucus ? "${_stretch?.label ?? 'Sticky'}, ${_colorSelection ?? 'cloudy'}" : "None"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (showPain)
                    Text(
                      'Pain: ${hasPain ? "${_formattedPainTypes.isNotEmpty ? _formattedPainTypes.join(', ') : 'Logged'} (${_painLevel.toInt()}/10)" : "None"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (showIntercourse && _hasIntercourse != null)
                    Text(
                      'Intercourse: ${_hasIntercourse == true ? "Yes" : "No"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comments / Notes (Optional):',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: null,
                minLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Add extra details or observations...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        );
    }
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);

    final bool hasBleeding = _hasBleeding ?? false;
    // Compute bleeding enum
    final Bleeding bleeding = hasBleeding
        ? (_bleedingFlow ?? Bleeding.light)
        : Bleeding.none;
    final String bleedingColorStr = hasBleeding ? (_bleedingColor ?? 'R') : '';

    // Compute sensation, stretch, colors, consistencies
    Sensation sensation = Sensation.dry;
    Stretch stretch = Stretch.none;
    final List<MucusColor> colors = [];
    final List<Consistency> consistencies = [];

    if (!_isHeavyOrModerateBleeding) {
      sensation = _sensation ?? Sensation.dry;

      if ((_hasLubrication ?? false) && sensation != Sensation.dry) {
        consistencies.add(Consistency.lubricative);
      }

      if (_hasMucus ?? false) {
        stretch = _stretch ?? Stretch.sticky;

        // Color mapping
        if (_colorSelection == 'cloudy') {
          colors.add(MucusColor.cloudy);
        } else if (_colorSelection == 'clear') {
          colors.add(MucusColor.clear);
        } else if (_colorSelection == 'cloudy_clear') {
          colors.add(MucusColor.cloudy);
          colors.add(MucusColor.clear);
        } else if (_colorSelection == 'yellow') {
          colors.add(MucusColor.yellow);
        } else if (_colorSelection == 'red') {
          colors.add(MucusColor.red);
        } else if (_colorSelection == 'brown') {
          colors.add(MucusColor.brown);
        }

        // Consistency mapping
        if (_isGummy) consistencies.add(Consistency.gummy);
        if (_isPasty) consistencies.add(Consistency.pasty);
      }
    }

    final bool hasPain = _hasPain ?? false;
    final double painLevel = hasPain ? _painLevel : 0.0;
    final List<String> painTypes = hasPain ? _formattedPainTypes : [];

    String commentText = _commentController.text.trim();
    if (_hasIntercourse == true) {
      if (commentText.isEmpty) {
        commentText = 'Intercourse';
      } else if (!commentText.contains('Intercourse')) {
        commentText = 'Intercourse • $commentText';
      }
    }

    final bool isVdrsExplicit =
        _hasBleeding == true ||
        _sensation != null ||
        _hasMucus == true ||
        widget.category == ObservationCategory.mucus ||
        widget.category == ObservationCategory.bleeding;

    try {
      await Services.db.saveObservation(
        cycleId: widget.cycle?.id,
        date: _combinedDateTime,
        sensation: sensation,
        stretch: stretch,
        colors: colors,
        consistencies: consistencies,
        bleeding: bleeding,
        bleedingColor: bleedingColorStr,
        painLevel: painLevel,
        painTypes: painTypes,
        comment: commentText,
        isVdrsExplicit: isVdrsExplicit,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving observation: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    this.icon,
    this.subtitle,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.85)
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
