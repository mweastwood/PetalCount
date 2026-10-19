import 'package:flutter/material.dart';

import '../../logic/logic.dart';

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
              Text(
                'Person / Assigned Partner',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                key: const Key('supplement_role_segmented_button'),
                segments: const [
                  ButtonSegment<UserRole>(
                    value: UserRole.wife,
                    label: Text('👩 Wife'),
                    icon: Icon(Icons.female),
                  ),
                  ButtonSegment<UserRole>(
                    value: UserRole.husband,
                    label: Text('👨 Husband'),
                    icon: Icon(Icons.male),
                  ),
                ],
                selected: {_targetRole},
                onSelectionChanged: (Set<UserRole> newSelection) {
                  setState(() {
                    _targetRole = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Supplement Name *',
                  hintText: 'e.g. CoQ10, Prenatal, Clomid',
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Dosage / Quantity *',
                  hintText: 'e.g. 200 mg, 1 tablet, 2 g',
                  errorText: _quantityError,
                ),
                onChanged: (_) {
                  if (_quantityError != null) {
                    setState(() => _quantityError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Take with food?'),
                subtitle: const Text('Required with meals for absorption'),
                value: _takeWithFood,
                onChanged: (value) {
                  setState(() {
                    _takeWithFood = value;
                  });
                },
              ),
              const Divider(height: 24),
              Text(
                'Daily Doses',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDoseRow(
                label: '🌅 Morning Dose',
                count: _morningDose,
                onChanged: (value) => setState(() {
                  _morningDose = value;
                  if (value > 0) _doseError = null;
                }),
              ),
              _buildDoseRow(
                label: '☀️ Afternoon Dose',
                count: _afternoonDose,
                onChanged: (value) => setState(() {
                  _afternoonDose = value;
                  if (value > 0) _doseError = null;
                }),
              ),
              _buildDoseRow(
                label: '🌙 Evening Dose',
                count: _eveningDose,
                onChanged: (value) => setState(() {
                  _eveningDose = value;
                  if (value > 0) _doseError = null;
                }),
              ),
              if (_doseError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _doseError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const Divider(height: 24),
              Text(
                'Cycle Schedule Rule',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SupplementScheduleRuleType>(
                initialValue: _ruleType,
                decoration: const InputDecoration(labelText: 'Schedule Window'),
                items: SupplementScheduleRuleType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _ruleType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              if (_ruleType == SupplementScheduleRuleType.cycleDays) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Start Cycle Day',
                          hintText: 'e.g. 4',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _endDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'End Cycle Day',
                          hintText: 'e.g. 8',
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_ruleType ==
                  SupplementScheduleRuleType.peakOffset) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startPeakController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peak Offset (e.g. 3 for P+3)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (Days)',
                          hintText: 'e.g. 10',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _startDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fallback Start Cycle Day (if no peak)',
                    hintText: 'e.g. 21',
                  ),
                ),
              ] else if (_ruleType ==
                  SupplementScheduleRuleType.cycleDaysOrPeak) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Start Cycle Day',
                          hintText: 'e.g. 8',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _endPeakController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'End Peak Offset',
                          hintText: 'e.g. 1 for P+1',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _endDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fallback End Cycle Day (if no peak)',
                    hintText: 'e.g. 19',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Clinical Notes / Instructions',
                  hintText: 'e.g. Take with dinner, sustained release',
                ),
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

  Widget _buildDoseRow({
    required String label,
    required int count,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 14),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: count > 0 ? () => onChanged(count - 1) : null,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 14),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => onChanged(count + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
