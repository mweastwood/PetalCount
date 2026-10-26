import 'package:flutter/material.dart';

import '../../logic/logic.dart';
import 'widgets/supplement_form_sections.dart';

class AddEditSupplementDialog extends StatefulWidget {
  final SupplementItem? supplement;
  final Future<void> Function(SupplementItem item)? onSave;
  final UserRole? defaultRole;

  const AddEditSupplementDialog({
    super.key,
    this.supplement,
    this.onSave,
    this.defaultRole,
  });

  static Future<SupplementItem?> show(
    BuildContext context, [
    SupplementItem? supplement,
    Future<void> Function(SupplementItem item)? onSave,
    UserRole? defaultRole,
  ]) {
    return showDialog<SupplementItem>(
      context: context,
      builder: (context) => AddEditSupplementDialog(
        supplement: supplement,
        onSave: onSave,
        defaultRole: defaultRole,
      ),
    );
  }

  @override
  State<AddEditSupplementDialog> createState() =>
      _AddEditSupplementDialogState();
}

class _AddEditSupplementDialogState extends State<AddEditSupplementDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _startDayController;
  late final TextEditingController _endDayController;
  late final TextEditingController _startPeakController;
  late final TextEditingController _endPeakController;
  late final TextEditingController _durationController;

  late bool _takeWithFood;
  late int _morningDose;
  late int _afternoonDose;
  late int _eveningDose;
  late SupplementScheduleRuleType _ruleType;
  late UserRole _targetRole;

  String? _nameError;
  String? _quantityError;
  String? _doseError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.supplement;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _quantityController = TextEditingController(text: existing?.quantity ?? '');
    _instructionsController = TextEditingController(
      text: existing?.instructions ?? '',
    );
    _takeWithFood = existing?.takeWithFood ?? false;
    _morningDose = existing?.morningDose ?? 1;
    _afternoonDose = existing?.afternoonDose ?? 0;
    _eveningDose = existing?.eveningDose ?? 0;
    _ruleType = existing?.ruleType ?? SupplementScheduleRuleType.allDays;
    _targetRole = existing?.targetRole ?? widget.defaultRole ?? UserRole.wife;

    _startDayController = TextEditingController(
      text: existing?.startCycleDay?.toString() ?? '',
    );
    _endDayController = TextEditingController(
      text: existing?.endCycleDay?.toString() ?? '',
    );
    _startPeakController = TextEditingController(
      text: existing?.startPeakOffset?.toString() ?? '',
    );
    _endPeakController = TextEditingController(
      text: existing?.endPeakOffset?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: existing?.durationDays?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _instructionsController.dispose();
    _startDayController.dispose();
    _endDayController.dispose();
    _startPeakController.dispose();
    _endPeakController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final quantity = _quantityController.text.trim();
    bool hasError = false;

    if (name.isEmpty) {
      _nameError = 'Supplement name is required';
      hasError = true;
    }
    if (quantity.isEmpty) {
      _quantityError = 'Dosage / quantity is required';
      hasError = true;
    }
    if (_morningDose + _afternoonDose + _eveningDose <= 0) {
      _doseError = 'At least one daily dose is required';
      hasError = true;
    } else {
      _doseError = null;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final parsedStartCycleDay = int.tryParse(_startDayController.text.trim());
    final parsedEndCycleDay = int.tryParse(_endDayController.text.trim());
    final parsedStartPeakOffset = int.tryParse(
      _startPeakController.text.trim(),
    );
    final parsedEndPeakOffset = int.tryParse(_endPeakController.text.trim());
    final parsedDurationDays = int.tryParse(_durationController.text.trim());

    final int? effectiveStartCycleDay =
        (_ruleType == SupplementScheduleRuleType.cycleDays ||
            _ruleType == SupplementScheduleRuleType.peakOffset ||
            _ruleType == SupplementScheduleRuleType.cycleDaysOrPeak)
        ? parsedStartCycleDay
        : null;
    final int? effectiveEndCycleDay =
        (_ruleType == SupplementScheduleRuleType.cycleDays ||
            _ruleType == SupplementScheduleRuleType.cycleDaysOrPeak)
        ? parsedEndCycleDay
        : null;
    final int? effectiveStartPeakOffset =
        _ruleType == SupplementScheduleRuleType.peakOffset
        ? parsedStartPeakOffset
        : null;
    final int? effectiveEndPeakOffset =
        _ruleType == SupplementScheduleRuleType.cycleDaysOrPeak
        ? parsedEndPeakOffset
        : null;
    final int? effectiveDurationDays =
        _ruleType == SupplementScheduleRuleType.peakOffset
        ? parsedDurationDays
        : null;

    final id =
        widget.supplement?.id ??
        'supp_${DateTime.now().millisecondsSinceEpoch}';
    final item = SupplementItem(
      id: id,
      name: name,
      quantity: quantity,
      takeWithFood: _takeWithFood,
      morningDose: _morningDose,
      afternoonDose: _afternoonDose,
      eveningDose: _eveningDose,
      ruleType: _ruleType,
      startCycleDay: effectiveStartCycleDay,
      endCycleDay: effectiveEndCycleDay,
      startPeakOffset: effectiveStartPeakOffset,
      endPeakOffset: effectiveEndPeakOffset,
      durationDays: effectiveDurationDays,
      instructions: _instructionsController.text.trim(),
      isActive: widget.supplement?.isActive ?? true,
      targetRole: _targetRole,
    );

    setState(() => _isSaving = true);

    try {
      if (widget.onSave != null) {
        await widget.onSave!(item);
      } else {
        await Services.db.saveSupplement(item);
      }
      if (mounted) {
        Navigator.pop(context, item);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save supplement: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.supplement;

    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(existing == null ? 'Add Supplement' : 'Edit Supplement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SupplementBasicInfoSection(
                targetRole: _targetRole,
                onRoleChanged: (role) => setState(() => _targetRole = role),
                nameController: _nameController,
                nameError: _nameError,
                onNameChanged: () {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
                quantityController: _quantityController,
                quantityError: _quantityError,
                onQuantityChanged: () {
                  if (_quantityError != null) {
                    setState(() => _quantityError = null);
                  }
                },
                takeWithFood: _takeWithFood,
                onTakeWithFoodChanged: (value) {
                  setState(() => _takeWithFood = value);
                },
              ),
              const Divider(height: 24),
              SupplementDailyDosesSection(
                morningDose: _morningDose,
                afternoonDose: _afternoonDose,
                eveningDose: _eveningDose,
                onMorningDoseChanged: (value) => setState(() {
                  _morningDose = value;
                  if (value > 0) _doseError = null;
                }),
                onAfternoonDoseChanged: (value) => setState(() {
                  _afternoonDose = value;
                  if (value > 0) _doseError = null;
                }),
                onEveningDoseChanged: (value) => setState(() {
                  _eveningDose = value;
                  if (value > 0) _doseError = null;
                }),
                doseError: _doseError,
              ),
              const Divider(height: 24),
              SupplementScheduleRuleSection(
                ruleType: _ruleType,
                onRuleTypeChanged: (value) {
                  setState(() => _ruleType = value);
                },
                startDayController: _startDayController,
                endDayController: _endDayController,
                startPeakController: _startPeakController,
                endPeakController: _endPeakController,
                durationController: _durationController,
                instructionsController: _instructionsController,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
