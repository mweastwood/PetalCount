import 'package:flutter/material.dart';

import '../logic/logic.dart';
import 'wizard/wizard.dart';

export 'wizard/wizard_controller.dart'
    show ObservationCategory, WizardStep, WizardController;

class AddObservationDialog extends StatefulWidget {
  final Cycle? cycle;
  final DateTime defaultDate;
  final ObservationCategory category;
  final DatabaseService? dbService;
  final WizardController? controller;

  const AddObservationDialog({
    super.key,
    this.cycle,
    required this.defaultDate,
    this.category = ObservationCategory.full,
    this.dbService,
    this.controller,
  });

  @override
  State<AddObservationDialog> createState() => _AddObservationDialogState();
}

class _AddObservationDialogState extends State<AddObservationDialog> {
  late WizardController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = WizardController(
        category: widget.category,
        cycle: widget.cycle,
        defaultDate: widget.defaultDate,
        dbService: widget.dbService,
      );
      _ownsController = true;
    }
  }

  @override
  void didUpdateWidget(AddObservationDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _controller.setSelectedDate(picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _controller.selectedTime,
    );
    if (picked != null) {
      _controller.setSelectedTime(picked);
    }
  }

  Future<void> _saveLog() async {
    try {
      final success = await _controller.saveObservation();
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving observation: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final activeSteps = _controller.activeSteps;
        final step = _controller.currentStep;
        final isFirstStep = _controller.isFirstStep;
        final isLastStep = _controller.isLastStep;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                        _controller.category.dialogTitle,
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
                            AppDateFormats.fullDate.format(
                              _controller.selectedDate,
                            ),
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
                                  _controller.selectedTime.format(context),
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
                        'Step ${_controller.currentStepIndex + 1} of ${activeSteps.length}: ${step.title}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _controller.progress,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),

                  // Step Content Area
                  Expanded(child: _buildStepContent(context, step)),

                  if (!isFirstStep ||
                      step == WizardStep.painDetails ||
                      isLastStep ||
                      !step.isSelfAdvancing) ...[
                    const SizedBox(height: 12),
                    // Footer Navigation
                    Row(
                      children: [
                        if (!isFirstStep)
                          OutlinedButton.icon(
                            onPressed: _controller.previousStep,
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Back'),
                          ),
                        if (step == WizardStep.painDetails) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _controller.nextStep,
                            child: const Text('Continue'),
                          ),
                        ],
                        const Spacer(),
                        if (isLastStep)
                          _controller.isSaving
                              ? const CircularProgressIndicator()
                              : FilledButton.icon(
                                  onPressed: _saveLog,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Save Observation'),
                                )
                        else if (!step.isSelfAdvancing)
                          TextButton(
                            onPressed: _controller.nextStep,
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
      },
    );
  }

  Widget _buildStepContent(BuildContext context, WizardStep step) {
    switch (step) {
      case WizardStep.bleedingFlow:
        final showNoBleeding =
            _controller.category != ObservationCategory.bleeding;
        return BleedingStepCard(
          isFlowStep: true,
          showNoBleeding: showNoBleeding,
          hasBleeding: _controller.hasBleeding,
          bleedingFlow: _controller.bleedingFlow,
          onSelectNoBleeding: () {
            _controller.setNoBleeding();
            _controller.nextStep();
          },
          onSelectFlow: (flow) {
            _controller.setBleedingFlow(flow);
            _controller.nextStep();
          },
        );

      case WizardStep.bleedingColor:
        return BleedingStepCard(
          isFlowStep: false,
          bleedingColor: _controller.bleedingColor,
          onSelectColor: (color) {
            _controller.setBleedingColor(color);
            _controller.nextStep();
          },
        );

      case WizardStep.sensation:
        return SensationStepCard(
          isLubricationStep: false,
          sensation: _controller.sensation,
          onSelectSensation: (sens) {
            _controller.setSensation(sens);
            _controller.nextStep();
          },
        );

      case WizardStep.lubrication:
        return SensationStepCard(
          isLubricationStep: true,
          hasLubrication: _controller.hasLubrication,
          onSelectLubrication: (lub) {
            _controller.setLubrication(lub);
            _controller.nextStep();
          },
        );

      case WizardStep.mucus:
        return MucusStepCard(
          subStep: MucusSubStep.presence,
          hasMucus: _controller.hasMucus,
          onSelectHasMucus: (has) {
            _controller.setHasMucus(has);
            _controller.nextStep();
          },
        );

      case WizardStep.mucusStretch:
        return MucusStepCard(
          subStep: MucusSubStep.stretch,
          stretch: _controller.stretch,
          onSelectStretch: (s) {
            _controller.setStretch(s);
            _controller.nextStep();
          },
        );

      case WizardStep.mucusColor:
        return MucusStepCard(
          subStep: MucusSubStep.color,
          selectedColors: _controller.selectedColors,
          onSelectColors: (colors) {
            _controller.setSelectedColors(colors);
            _controller.nextStep();
          },
        );

      case WizardStep.mucusConsistency:
        return MucusStepCard(
          subStep: MucusSubStep.consistency,
          isGummy: _controller.isGummy,
          isPasty: _controller.isPasty,
          hasSelectedConsistency: _controller.hasSelectedConsistency,
          onSelectConsistency: ({required isGummy, required isPasty}) {
            _controller.setConsistency(isGummy: isGummy, isPasty: isPasty);
            _controller.nextStep();
          },
        );

      case WizardStep.frequency:
        return FrequencyStepCard(
          frequency: _controller.frequency,
          onSelectFrequency: (f) {
            _controller.setFrequency(f);
            _controller.nextStep();
          },
        );

      case WizardStep.intercourse:
        return IntercourseStepCard(
          hasIntercourse: _controller.hasIntercourse,
          onSelectIntercourse: (val) {
            _controller.setHasIntercourse(val);
            _controller.nextStep();
          },
        );

      case WizardStep.pain:
        return PainStepCard(
          isDetailsStep: false,
          hasPain: _controller.hasPain,
          onSelectHasPain: (has) {
            _controller.setHasPain(has);
            _controller.nextStep();
          },
        );

      case WizardStep.painDetails:
        return PainStepCard(
          isDetailsStep: true,
          painTypes: _controller.painTypes,
          abdominalLeft: _controller.abdominalLeft,
          abdominalRight: _controller.abdominalRight,
          painLevel: _controller.painLevel,
          onTogglePainType: (p, selected) {
            _controller.togglePainType(p, selected);
          },
          onToggleAbdominalLeft: (val) {
            _controller.setAbdominalLeft(val);
          },
          onToggleAbdominalRight: (val) {
            _controller.setAbdominalRight(val);
          },
          onPainLevelChanged: (val) {
            _controller.setPainLevel(val);
          },
        );

      case WizardStep.comments:
        return ObservationSummaryStepCard(
          combinedDateTime: _controller.combinedDateTime,
          showBleeding: _controller.showBleeding,
          hasBleeding: _controller.hasBleeding ?? false,
          bleedingFlow: _controller.bleedingFlow,
          bleedingColor: _controller.bleedingColor,
          showMucus: _controller.showMucus,
          sensation: _controller.sensation,
          hasLubrication: _controller.hasLubrication ?? false,
          hasMucus: _controller.hasMucus ?? false,
          stretch: _controller.stretch,
          selectedColors: _controller.selectedColors,
          frequency: _controller.frequency,
          showPain: _controller.showPain,
          hasPain: _controller.hasPain ?? false,
          formattedPainTypes: _controller.formattedPainTypes,
          painLevel: _controller.painLevel,
          showIntercourse: _controller.showIntercourse,
          hasIntercourse: _controller.hasIntercourse,
          commentController: _controller.commentController,
        );
    }
  }
}
