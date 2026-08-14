import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/logic.dart';
import 'wizard/wizard.dart';

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
  List<MucusColor> _selectedColors = [];
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
        if (_stretch == Stretch.sticky) {
          steps.add(WizardStep.mucusConsistency);
        }
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
        if (_stretch == Stretch.sticky) {
          steps.add(WizardStep.mucusConsistency);
        }
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

  Widget _buildStepContent(BuildContext context, WizardStep step) {
    switch (step) {
      case WizardStep.bleedingFlow:
        final showNoBleeding = widget.category != ObservationCategory.bleeding;
        return BleedingStepCard(
          isFlowStep: true,
          showNoBleeding: showNoBleeding,
          hasBleeding: _hasBleeding,
          bleedingFlow: _bleedingFlow,
          onSelectNoBleeding: () {
            setState(() {
              _hasBleeding = false;
              _bleedingFlow = Bleeding.none;
              _bleedingColor = null;
            });
            _nextStep();
          },
          onSelectFlow: (flow) {
            setState(() {
              _hasBleeding = true;
              _bleedingFlow = flow;
            });
            _nextStep();
          },
        );

      case WizardStep.bleedingColor:
        return BleedingStepCard(
          isFlowStep: false,
          bleedingColor: _bleedingColor,
          onSelectColor: (color) {
            setState(() {
              _bleedingColor = color;
            });
            _nextStep();
          },
        );

      case WizardStep.sensation:
        return SensationStepCard(
          isLubricationStep: false,
          sensation: _sensation,
          onSelectSensation: (sens) {
            setState(() {
              _sensation = sens;
              if (sens == Sensation.dry) {
                _hasLubrication = false;
              }
            });
            _nextStep();
          },
        );

      case WizardStep.lubrication:
        return SensationStepCard(
          isLubricationStep: true,
          hasLubrication: _hasLubrication,
          onSelectLubrication: (lub) {
            setState(() {
              _hasLubrication = lub;
            });
            _nextStep();
          },
        );

      case WizardStep.mucus:
        return MucusStepCard(
          subStep: MucusSubStep.presence,
          hasMucus: _hasMucus,
          onSelectHasMucus: (has) {
            setState(() {
              _hasMucus = has;
              if (!has) {
                _stretch = Stretch.none;
                _selectedColors = [];
                _isGummy = false;
                _isPasty = false;
              }
            });
            _nextStep();
          },
        );

      case WizardStep.mucusStretch:
        return MucusStepCard(
          subStep: MucusSubStep.stretch,
          stretch: _stretch,
          onSelectStretch: (s) {
            setState(() {
              _stretch = s;
            });
            _nextStep();
          },
        );

      case WizardStep.mucusColor:
        return MucusStepCard(
          subStep: MucusSubStep.color,
          selectedColors: _selectedColors,
          onSelectColors: (colors) {
            setState(() {
              _selectedColors = colors;
            });
            _nextStep();
          },
        );

      case WizardStep.mucusConsistency:
        return MucusStepCard(
          subStep: MucusSubStep.consistency,
          isGummy: _isGummy,
          isPasty: _isPasty,
          hasSelectedConsistency: _hasSelectedConsistency,
          onSelectConsistency: ({required isGummy, required isPasty}) {
            setState(() {
              _isGummy = isGummy;
              _isPasty = isPasty;
              _hasSelectedConsistency = true;
            });
            _nextStep();
          },
        );

      case WizardStep.intercourse:
        return IntercourseStepCard(
          hasIntercourse: _hasIntercourse,
          onSelectIntercourse: (val) {
            setState(() {
              _hasIntercourse = val;
            });
            _nextStep();
          },
        );

      case WizardStep.pain:
        return PainStepCard(
          isDetailsStep: false,
          hasPain: _hasPain,
          onSelectHasPain: (has) {
            setState(() {
              _hasPain = has;
            });
            _nextStep();
          },
        );

      case WizardStep.painDetails:
        return PainStepCard(
          isDetailsStep: true,
          painTypes: _painTypes,
          abdominalLeft: _abdominalLeft,
          abdominalRight: _abdominalRight,
          painLevel: _painLevel,
          onTogglePainType: (p, selected) {
            setState(() {
              if (selected) {
                _painTypes.add(p);
              } else {
                _painTypes.remove(p);
              }
            });
          },
          onToggleAbdominalLeft: (val) {
            setState(() => _abdominalLeft = val);
          },
          onToggleAbdominalRight: (val) {
            setState(() => _abdominalRight = val);
          },
          onPainLevelChanged: (val) {
            setState(() => _painLevel = val);
          },
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

        return ObservationSummaryStepCard(
          combinedDateTime: _combinedDateTime,
          showBleeding: showBleeding,
          hasBleeding: _hasBleeding ?? false,
          bleedingFlow: _bleedingFlow,
          bleedingColor: _bleedingColor,
          showMucus: showMucus,
          sensation: _sensation,
          hasLubrication: _hasLubrication ?? false,
          hasMucus: _hasMucus ?? false,
          stretch: _stretch,
          selectedColors: _selectedColors,
          showPain: showPain,
          hasPain: _hasPain ?? false,
          formattedPainTypes: _formattedPainTypes,
          painLevel: _painLevel,
          showIntercourse: showIntercourse,
          hasIntercourse: _hasIntercourse,
          commentController: _commentController,
        );
    }
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);

    final bool hasBleeding = _hasBleeding ?? false;
    final Bleeding bleeding = hasBleeding
        ? (_bleedingFlow ?? Bleeding.light)
        : Bleeding.none;
    final String bleedingColorStr = hasBleeding ? (_bleedingColor ?? 'R') : '';

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
        colors.addAll(
          _selectedColors.isNotEmpty ? _selectedColors : [MucusColor.cloudy],
        );

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
