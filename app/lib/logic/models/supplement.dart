import '../utils/date_utils.dart';

enum SupplementTimeOfDay {
  morning('Morning', '🌅'),
  afternoon('Afternoon', '☀️'),
  evening('Evening', '🌙');

  final String label;
  final String icon;
  const SupplementTimeOfDay(this.label, this.icon);
}

enum SupplementScheduleRuleType {
  allDays('All Days (Daily)', 'Taken every day throughout the cycle'),
  cycleDays(
    'Cycle Days Window',
    'Active between specific cycle days (e.g. Days 4–8)',
  ),
  peakOffset(
    'Peak Day Window',
    'Active starting at Peak offset (e.g. P+3 for 10 days)',
  ),
  cycleDaysOrPeak(
    'Cycle Days to Peak Window',
    'Active starting on cycle day until Peak offset (e.g. Day 8 to P+1 or Day 19)',
  );

  final String label;
  final String description;
  const SupplementScheduleRuleType(this.label, this.description);
}

class SupplementItem {
  final String id;
  final String name;
  final String quantity;
  final bool takeWithFood;
  final int morningDose;
  final int afternoonDose;
  final int eveningDose;
  final SupplementScheduleRuleType ruleType;
  final int? startCycleDay;
  final int? endCycleDay;
  final int? startPeakOffset;
  final int? endPeakOffset;
  final int? durationDays;
  final String instructions;
  final bool isActive;

  const SupplementItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.takeWithFood = false,
    this.morningDose = 0,
    this.afternoonDose = 0,
    this.eveningDose = 0,
    this.ruleType = SupplementScheduleRuleType.allDays,
    this.startCycleDay,
    this.endCycleDay,
    this.startPeakOffset,
    this.endPeakOffset,
    this.durationDays,
    this.instructions = '',
    this.isActive = true,
  });

  bool get takesInMorning => morningDose > 0;
  bool get takesInAfternoon => afternoonDose > 0;
  bool get takesInEvening => eveningDose > 0;
  int get totalDailyDoses => morningDose + afternoonDose + eveningDose;

  int doseForTime(SupplementTimeOfDay time) {
    switch (time) {
      case SupplementTimeOfDay.morning:
        return morningDose;
      case SupplementTimeOfDay.afternoon:
        return afternoonDose;
      case SupplementTimeOfDay.evening:
        return eveningDose;
    }
  }

  /// Determines whether this supplement is scheduled for a given cycle day and peak status
  bool isScheduledFor({
    required int cycleDay,
    int? daysPastPeak,
    bool hasPeakOccurred = false,
  }) {
    if (!isActive) return false;

    switch (ruleType) {
      case SupplementScheduleRuleType.allDays:
        return true;

      case SupplementScheduleRuleType.cycleDays:
        if (startCycleDay != null && cycleDay < startCycleDay!) return false;
        if (endCycleDay != null && cycleDay > endCycleDay!) return false;
        return true;

      case SupplementScheduleRuleType.peakOffset:
        if (hasPeakOccurred &&
            daysPastPeak != null &&
            startPeakOffset != null) {
          final start = startPeakOffset!;
          final end = durationDays != null
              ? (start + durationDays! - 1)
              : start;
          return daysPastPeak >= start && daysPastPeak <= end;
        }
        // Fallback to cycle day rule if peak not yet identified (e.g. Day 21+ for 10 days)
        if (startCycleDay != null) {
          final start = startCycleDay!;
          final end = durationDays != null
              ? (start + durationDays! - 1)
              : (endCycleDay ?? start);
          return cycleDay >= start && cycleDay <= end;
        }
        return false;

      case SupplementScheduleRuleType.cycleDaysOrPeak:
        if (startCycleDay != null && cycleDay < startCycleDay!) return false;
        if (hasPeakOccurred && daysPastPeak != null && endPeakOffset != null) {
          return daysPastPeak <= endPeakOffset!;
        }
        if (endCycleDay != null && cycleDay > endCycleDay!) return false;
        return true;
    }
  }

  String get scheduleDescription {
    switch (ruleType) {
      case SupplementScheduleRuleType.allDays:
        return 'Daily (All Days)';
      case SupplementScheduleRuleType.cycleDays:
        final start = startCycleDay ?? 1;
        final end = endCycleDay != null ? ' – Day $endCycleDay' : '+';
        return 'Cycle Day $start$end';
      case SupplementScheduleRuleType.peakOffset:
        final dur = durationDays != null ? ' for $durationDays days' : '';
        final fallback = startCycleDay != null
            ? ' (or Day $startCycleDay)'
            : '';
        final peakPrefix = (startPeakOffset ?? 0) >= 0
            ? 'P+${startPeakOffset ?? 0}'
            : 'P${startPeakOffset ?? 0}';
        return '$peakPrefix$fallback$dur';
      case SupplementScheduleRuleType.cycleDaysOrPeak:
        final start = startCycleDay ?? 1;
        final peakEnd = endPeakOffset != null ? 'P+$endPeakOffset' : 'Peak';
        final fallback = endCycleDay != null ? ' (or Day $endCycleDay)' : '';
        return 'Day $start to $peakEnd$fallback';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'takeWithFood': takeWithFood,
      'morningDose': morningDose,
      'afternoonDose': afternoonDose,
      'eveningDose': eveningDose,
      'ruleType': ruleType.name,
      'startCycleDay': startCycleDay,
      'endCycleDay': endCycleDay,
      'startPeakOffset': startPeakOffset,
      'endPeakOffset': endPeakOffset,
      'durationDays': durationDays,
      'instructions': instructions,
      'isActive': isActive,
    };
  }

  factory SupplementItem.fromMap(Map<String, dynamic> map) {
    final ruleTypeName = map['ruleType']?.toString() ?? '';
    final ruleType = SupplementScheduleRuleType.values.firstWhere(
      (e) => e.name == ruleTypeName,
      orElse: () => SupplementScheduleRuleType.allDays,
    );

    return SupplementItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      quantity: map['quantity']?.toString() ?? '',
      takeWithFood: map['takeWithFood'] as bool? ?? false,
      morningDose: (map['morningDose'] as num?)?.toInt() ?? 0,
      afternoonDose: (map['afternoonDose'] as num?)?.toInt() ?? 0,
      eveningDose: (map['eveningDose'] as num?)?.toInt() ?? 0,
      ruleType: ruleType,
      startCycleDay: (map['startCycleDay'] as num?)?.toInt(),
      endCycleDay: (map['endCycleDay'] as num?)?.toInt(),
      startPeakOffset: (map['startPeakOffset'] as num?)?.toInt(),
      endPeakOffset: (map['endPeakOffset'] as num?)?.toInt(),
      durationDays: (map['durationDays'] as num?)?.toInt(),
      instructions: map['instructions']?.toString() ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  SupplementItem copyWith({
    String? id,
    String? name,
    String? quantity,
    bool? takeWithFood,
    int? morningDose,
    int? afternoonDose,
    int? eveningDose,
    SupplementScheduleRuleType? ruleType,
    int? startCycleDay,
    int? endCycleDay,
    int? startPeakOffset,
    int? endPeakOffset,
    int? durationDays,
    String? instructions,
    bool? isActive,
  }) {
    return SupplementItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      takeWithFood: takeWithFood ?? this.takeWithFood,
      morningDose: morningDose ?? this.morningDose,
      afternoonDose: afternoonDose ?? this.afternoonDose,
      eveningDose: eveningDose ?? this.eveningDose,
      ruleType: ruleType ?? this.ruleType,
      startCycleDay: startCycleDay ?? this.startCycleDay,
      endCycleDay: endCycleDay ?? this.endCycleDay,
      startPeakOffset: startPeakOffset ?? this.startPeakOffset,
      endPeakOffset: endPeakOffset ?? this.endPeakOffset,
      durationDays: durationDays ?? this.durationDays,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
    );
  }
}

class DailySupplementLog {
  final DateTime date;
  final Map<String, List<SupplementTimeOfDay>> takenDoses;

  DailySupplementLog({required DateTime date, required this.takenDoses})
    : date = date.toNormalizedDate();

  bool isTaken(String supplementId, SupplementTimeOfDay time) {
    final times = takenDoses[supplementId];
    return times != null && times.contains(time);
  }

  DailySupplementLog withToggled(
    String supplementId,
    SupplementTimeOfDay time,
    bool taken,
  ) {
    final updated = Map<String, List<SupplementTimeOfDay>>.from(
      takenDoses.map((k, v) => MapEntry(k, List<SupplementTimeOfDay>.from(v))),
    );
    final currentList = updated[supplementId] ?? [];
    if (taken) {
      if (!currentList.contains(time)) {
        currentList.add(time);
      }
      updated[supplementId] = currentList;
    } else {
      currentList.remove(time);
      if (currentList.isEmpty) {
        updated.remove(supplementId);
      } else {
        updated[supplementId] = currentList;
      }
    }
    return DailySupplementLog(date: date, takenDoses: updated);
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.dateKey,
      'takenDoses': takenDoses.map(
        (k, v) => MapEntry(k, v.map((time) => time.name).toList()),
      ),
    };
  }

  factory DailySupplementLog.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date']?.toString() ?? '';
    final parsedDate = parseIsoDate(dateStr);

    final rawDoses = map['takenDoses'] as Map? ?? {};
    final doses = <String, List<SupplementTimeOfDay>>{};
    rawDoses.forEach((k, v) {
      final list = ((v as List?) ?? [])
          .map(
            (item) => SupplementTimeOfDay.values
                .cast<SupplementTimeOfDay?>()
                .firstWhere((e) => e?.name == item, orElse: () => null),
          )
          .whereType<SupplementTimeOfDay>()
          .toList();
      doses[k.toString()] = list;
    });

    return DailySupplementLog(date: parsedDate, takenDoses: doses);
  }
}

class SupplementPresets {
  static const List<SupplementItem> defaultList = [
    SupplementItem(
      id: 'preset_prenatal',
      name: 'Prenatal',
      quantity: 'tablet',
      takeWithFood: false,
      morningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Baseline nutritional support',
    ),
    SupplementItem(
      id: 'preset_coq10',
      name: 'CoQ10',
      quantity: '200 mg',
      takeWithFood: false,
      morningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Oocyte quality & mitochondrial support',
    ),
    SupplementItem(
      id: 'preset_vitamind',
      name: 'Vitamin D',
      quantity: '3000 units',
      takeWithFood: false,
      morningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Endocrine & immune support',
    ),
    SupplementItem(
      id: 'preset_nac',
      name: 'NAC (N-Acetyl Cysteine)',
      quantity: '500 mg',
      takeWithFood: true,
      morningDose: 1,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Antioxidant & cellular health',
    ),
    SupplementItem(
      id: 'preset_folate_b12',
      name: 'L-methylfolate and sublingual B12',
      quantity: '1/2 lozenge',
      takeWithFood: false,
      morningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Methylation support',
    ),
    SupplementItem(
      id: 'preset_myo_inositol',
      name: 'Myo-inositol',
      quantity: '2 g (2/3 tsp)',
      takeWithFood: true,
      morningDose: 1,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Insulin sensitivity & ovarian function',
    ),
    SupplementItem(
      id: 'preset_berberine',
      name: 'Berberine',
      quantity: '500 mg (1 tablet)',
      takeWithFood: true,
      morningDose: 1,
      afternoonDose: 1,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Metabolic & glucose regulation',
    ),
    SupplementItem(
      id: 'preset_fatty15',
      name: 'Fatty 15',
      quantity: '1 tablet',
      takeWithFood: false,
      morningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Cellular membrane support',
    ),
    SupplementItem(
      id: 'preset_magnesium',
      name: 'Magnesium L-Theonate',
      quantity: '2000mg (1 tablet)',
      takeWithFood: false,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Sleep & nervous system support',
    ),
    SupplementItem(
      id: 'preset_perfect_amino',
      name: 'Perfect Amino',
      quantity: '1 tablet',
      takeWithFood: true,
      morningDose: 1,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Essential amino acid support',
    ),
    SupplementItem(
      id: 'preset_clomid',
      name: 'Clomid',
      quantity: '50 mg (1 tablet)',
      takeWithFood: false,
      morningDose: 1,
      ruleType: SupplementScheduleRuleType.cycleDays,
      startCycleDay: 4,
      endCycleDay: 8,
      instructions: 'Follicular recruitment & ovulation induction (Days 4–8)',
    ),
    SupplementItem(
      id: 'preset_fertilecm',
      name: 'FertileCM',
      quantity: 'tablet',
      takeWithFood: false,
      morningDose: 1,
      afternoonDose: 1,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.cycleDaysOrPeak,
      startCycleDay: 8,
      endCycleDay: 19,
      endPeakOffset: 1,
      instructions:
          'Cervical mucus hydration & vascular flow (Day 8 to P+1 or Day 19)',
    ),
    SupplementItem(
      id: 'preset_mucinex',
      name: 'Mucinex ER',
      quantity: '600mg',
      takeWithFood: false,
      morningDose: 1,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.cycleDaysOrPeak,
      startCycleDay: 9,
      endCycleDay: 19,
      endPeakOffset: 1,
      instructions: 'Mucus thinning (Day 9 to P+1 or Day 19)',
    ),
    SupplementItem(
      id: 'preset_progesterone',
      name: 'Progesterone (sustained release)',
      quantity: '400mg (2 tablets)',
      takeWithFood: false,
      morningDose: 1,
      eveningDose: 1,
      ruleType: SupplementScheduleRuleType.peakOffset,
      startPeakOffset: 3,
      startCycleDay: 21,
      durationDays: 10,
      instructions: 'Luteal phase support (P+3 or Day 21 for 10 days)',
    ),
  ];
}
