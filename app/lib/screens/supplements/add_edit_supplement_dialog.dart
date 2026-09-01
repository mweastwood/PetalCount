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
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _startDayCtrl;
  late final TextEditingController _endDayCtrl;
  late final TextEditingController _startPeakCtrl;
  late final TextEditingController _endPeakCtrl;
  late final TextEditingController _durationCtrl;

  late bool _takeWithFood;
  late int _morningDose;
  late int _afternoonDose;
  late int _eveningDose;
  late SupplementScheduleRuleType _ruleType;
  late UserRole _targetRole;

  String? _nameError;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    final existing = widget.supplement;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _quantityCtrl = TextEditingController(text: existing?.quantity ?? '');
    _instructionsCtrl = TextEditingController(
      text: existing?.instructions ?? '',
    );
    _takeWithFood = existing?.takeWithFood ?? false;
    _morningDose = existing?.morningDose ?? 1;
    _afternoonDose = existing?.afternoonDose ?? 0;
    _eveningDose = existing?.eveningDose ?? 0;
    _ruleType = existing?.ruleType ?? SupplementScheduleRuleType.allDays;
    _targetRole = existing?.targetRole ?? widget.defaultRole ?? UserRole.wife;

    _startDayCtrl = TextEditingController(
      text: existing?.startCycleDay?.toString() ?? '',
    );
    _endDayCtrl = TextEditingController(
      text: existing?.endCycleDay?.toString() ?? '',
    );
    _startPeakCtrl = TextEditingController(
      text: existing?.startPeakOffset?.toString() ?? '',
    );
    _endPeakCtrl = TextEditingController(
      text: existing?.endPeakOffset?.toString() ?? '',
    );
    _durationCtrl = TextEditingController(
      text: existing?.durationDays?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _instructionsCtrl.dispose();
    _startDayCtrl.dispose();
    _endDayCtrl.dispose();
    _startPeakCtrl.dispose();
    _endPeakCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    final quantity = _quantityCtrl.text.trim();
    bool hasError = false;

    if (name.isEmpty) {
      _nameError = 'Supplement name is required';
      hasError = true;
    }
    if (quantity.isEmpty) {
      _quantityError = 'Dosage / quantity is required';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

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
      startCycleDay: int.tryParse(_startDayCtrl.text.trim()),
      endCycleDay: int.tryParse(_endDayCtrl.text.trim()),
      startPeakOffset: int.tryParse(_startPeakCtrl.text.trim()),
      endPeakOffset: int.tryParse(_endPeakCtrl.text.trim()),
      durationDays: int.tryParse(_durationCtrl.text.trim()),
      instructions: _instructionsCtrl.text.trim(),
      isActive: widget.supplement?.isActive ?? true,
      targetRole: _targetRole,
    );

    Navigator.pop(context, item);
    if (widget.onSave != null) {
      await widget.onSave!(item);
    } else {
      await Services.db.saveSupplement(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.supplement;

    return AlertDialog(
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
              controller: _nameCtrl,
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
              controller: _quantityCtrl,
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
              onChanged: (val) {
                setState(() {
                  _takeWithFood = val;
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
              onChanged: (val) => setState(() => _morningDose = val),
            ),
            _buildDoseRow(
              label: '☀️ Afternoon Dose',
              count: _afternoonDose,
              onChanged: (val) => setState(() => _afternoonDose = val),
            ),
            _buildDoseRow(
              label: '🌙 Evening Dose',
              count: _eveningDose,
              onChanged: (val) => setState(() => _eveningDose = val),
            ),
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
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _ruleType = val;
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
                      controller: _startDayCtrl,
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
                      controller: _endDayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'End Cycle Day',
                        hintText: 'e.g. 8',
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_ruleType == SupplementScheduleRuleType.peakOffset) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startPeakCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peak Offset (e.g. 3 for P+3)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _durationCtrl,
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
                controller: _startDayCtrl,
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
                      controller: _startDayCtrl,
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
                      controller: _endPeakCtrl,
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
                controller: _endDayCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fallback End Cycle Day (if no peak)',
                  hintText: 'e.g. 19',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsCtrl,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _handleSave, child: const Text('Save')),
      ],
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
