import 'package:flutter/material.dart';

import '../../../logic/logic.dart';

class SupplementBasicInfoSection extends StatelessWidget {
  final UserRole targetRole;
  final ValueChanged<UserRole> onRoleChanged;
  final TextEditingController nameController;
  final String? nameError;
  final VoidCallback onNameChanged;
  final TextEditingController quantityController;
  final String? quantityError;
  final VoidCallback onQuantityChanged;
  final bool takeWithFood;
  final ValueChanged<bool> onTakeWithFoodChanged;

  const SupplementBasicInfoSection({
    super.key,
    required this.targetRole,
    required this.onRoleChanged,
    required this.nameController,
    required this.nameError,
    required this.onNameChanged,
    required this.quantityController,
    required this.quantityError,
    required this.onQuantityChanged,
    required this.takeWithFood,
    required this.onTakeWithFoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          selected: {targetRole},
          onSelectionChanged: (Set<UserRole> newSelection) {
            onRoleChanged(newSelection.first);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Supplement Name *',
            hintText: 'e.g. CoQ10, Prenatal, Clomid',
            errorText: nameError,
          ),
          onChanged: (_) => onNameChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: quantityController,
          decoration: InputDecoration(
            labelText: 'Dosage / Quantity *',
            hintText: 'e.g. 200 mg, 1 tablet, 2 g',
            errorText: quantityError,
          ),
          onChanged: (_) => onQuantityChanged(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Take with food?'),
          subtitle: const Text('Required with meals for absorption'),
          value: takeWithFood,
          onChanged: onTakeWithFoodChanged,
        ),
      ],
    );
  }
}

class SupplementDailyDosesSection extends StatelessWidget {
  final int morningDose;
  final int afternoonDose;
  final int eveningDose;
  final ValueChanged<int> onMorningDoseChanged;
  final ValueChanged<int> onAfternoonDoseChanged;
  final ValueChanged<int> onEveningDoseChanged;
  final String? doseError;

  const SupplementDailyDosesSection({
    super.key,
    required this.morningDose,
    required this.afternoonDose,
    required this.eveningDose,
    required this.onMorningDoseChanged,
    required this.onAfternoonDoseChanged,
    required this.onEveningDoseChanged,
    required this.doseError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Doses',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDoseRow(
          label: '🌅 Morning Dose',
          count: morningDose,
          onChanged: onMorningDoseChanged,
        ),
        _buildDoseRow(
          label: '☀️ Afternoon Dose',
          count: afternoonDose,
          onChanged: onAfternoonDoseChanged,
        ),
        _buildDoseRow(
          label: '🌙 Evening Dose',
          count: eveningDose,
          onChanged: onEveningDoseChanged,
        ),
        if (doseError != null) ...[
          const SizedBox(height: 6),
          Text(
            doseError!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
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

class SupplementScheduleRuleSection extends StatelessWidget {
  final SupplementScheduleRuleType ruleType;
  final ValueChanged<SupplementScheduleRuleType> onRuleTypeChanged;
  final TextEditingController startDayController;
  final TextEditingController endDayController;
  final TextEditingController startPeakController;
  final TextEditingController endPeakController;
  final TextEditingController durationController;
  final TextEditingController instructionsController;

  const SupplementScheduleRuleSection({
    super.key,
    required this.ruleType,
    required this.onRuleTypeChanged,
    required this.startDayController,
    required this.endDayController,
    required this.startPeakController,
    required this.endPeakController,
    required this.durationController,
    required this.instructionsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cycle Schedule Rule',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<SupplementScheduleRuleType>(
          initialValue: ruleType,
          decoration: const InputDecoration(labelText: 'Schedule Window'),
          items: SupplementScheduleRuleType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onRuleTypeChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        if (ruleType == SupplementScheduleRuleType.cycleDays) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startDayController,
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
                  controller: endDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'End Cycle Day',
                    hintText: 'e.g. 8',
                  ),
                ),
              ),
            ],
          ),
        ] else if (ruleType == SupplementScheduleRuleType.peakOffset) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startPeakController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peak Offset (e.g. 3 for P+3)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: durationController,
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
            controller: startDayController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Fallback Start Cycle Day (if no peak)',
              hintText: 'e.g. 21',
            ),
          ),
        ] else if (ruleType == SupplementScheduleRuleType.cycleDaysOrPeak) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startDayController,
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
                  controller: endPeakController,
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
            controller: endDayController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Fallback End Cycle Day (if no peak)',
              hintText: 'e.g. 19',
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: instructionsController,
          decoration: const InputDecoration(
            labelText: 'Clinical Notes / Instructions',
            hintText: 'e.g. Take with dinner, sustained release',
          ),
        ),
      ],
    );
  }
}
