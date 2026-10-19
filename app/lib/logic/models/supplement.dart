import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/date_utils.dart';
import 'user_role.dart';

part 'supplement.freezed.dart';
part 'supplement.g.dart';

/// Default total cycle days represented in the supplement schedule matrix.
const int kSupplementPlanTotalCycleDays = 35;

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

String _parseSupplementStringFromJson(Object? rawValue) =>
    rawValue?.toString() ?? '';

bool _parseSupplementBoolFalseFromJson(Object? rawValue) {
  if (rawValue is bool) return rawValue;
  if (rawValue is String) return rawValue.trim().toLowerCase() == 'true';
  if (rawValue is num) return rawValue != 0;
  return false;
}

bool _parseSupplementBoolTrueFromJson(Object? rawValue) {
  if (rawValue is bool) return rawValue;
  if (rawValue is String) return rawValue.trim().toLowerCase() != 'false';
  if (rawValue is num) return rawValue != 0;
  return true;
}

int _parseSupplementDoseFromJson(Object? rawValue) {
  if (rawValue is num) return rawValue.toInt();
  if (rawValue is String) return int.tryParse(rawValue) ?? 0;
  return 0;
}

int? _parseNullableIntFromJson(Object? rawValue) {
  if (rawValue is num) return rawValue.toInt();
  if (rawValue is String) return int.tryParse(rawValue);
  return null;
}

SupplementScheduleRuleType _parseRuleTypeFromJson(Object? rawValue) {
  final ruleTypeName = rawValue?.toString() ?? '';
  return SupplementScheduleRuleType.values.firstWhere(
    (element) => element.name == ruleTypeName,
    orElse: () => SupplementScheduleRuleType.allDays,
  );
}

String _serializeRuleTypeToJson(SupplementScheduleRuleType ruleType) =>
    ruleType.name;

UserRole _parseTargetRoleFromJson(Object? rawValue) =>
    UserRole.fromString(rawValue?.toString());

String _serializeTargetRoleToJson(UserRole role) => role.code;

@freezed
abstract class SupplementItem with _$SupplementItem {
  const SupplementItem._();

  const factory SupplementItem({
    @Default('') @JsonKey(fromJson: _parseSupplementStringFromJson) String id,
    @Default('') @JsonKey(fromJson: _parseSupplementStringFromJson) String name,
    @Default('')
    @JsonKey(fromJson: _parseSupplementStringFromJson)
    String quantity,
    @Default(false)
    @JsonKey(fromJson: _parseSupplementBoolFalseFromJson)
    bool takeWithFood,
    @Default(0)
    @JsonKey(fromJson: _parseSupplementDoseFromJson)
    int morningDose,
    @Default(0)
    @JsonKey(fromJson: _parseSupplementDoseFromJson)
    int afternoonDose,
    @Default(0)
    @JsonKey(fromJson: _parseSupplementDoseFromJson)
    int eveningDose,
    @Default(SupplementScheduleRuleType.allDays)
    @JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson)
    SupplementScheduleRuleType ruleType,
    @JsonKey(fromJson: _parseNullableIntFromJson) int? startCycleDay,
    @JsonKey(fromJson: _parseNullableIntFromJson) int? endCycleDay,
    @JsonKey(fromJson: _parseNullableIntFromJson) int? startPeakOffset,
    @JsonKey(fromJson: _parseNullableIntFromJson) int? endPeakOffset,
    @JsonKey(fromJson: _parseNullableIntFromJson) int? durationDays,
    @Default('')
    @JsonKey(fromJson: _parseSupplementStringFromJson)
    String instructions,
    @Default(true)
    @JsonKey(fromJson: _parseSupplementBoolTrueFromJson)
    bool isActive,
    @Default(UserRole.wife)
    @JsonKey(
      fromJson: _parseTargetRoleFromJson,
      toJson: _serializeTargetRoleToJson,
    )
    UserRole targetRole,
  }) = _SupplementItem;

  bool get takesInMorning => morningDose > 0;
  bool get takesInAfternoon => afternoonDose > 0;
  bool get takesInEvening => eveningDose > 0;
  int get totalDailyDoses => morningDose + afternoonDose + eveningDose;

  int doseForTime(SupplementTimeOfDay timeOfDay) {
    switch (timeOfDay) {
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
          final startOffset = startPeakOffset!;
          final endOffset = durationDays != null
              ? (startOffset + durationDays! - 1)
              : (endPeakOffset ?? startOffset);
          return daysPastPeak >= startOffset && daysPastPeak <= endOffset;
        }
        // Fallback to cycle day rule if peak not yet identified (e.g. Day 21+ for 10 days)
        if (startCycleDay != null) {
          final startDay = startCycleDay!;
          final endDay = durationDays != null
              ? (startDay + durationDays! - 1)
              : (endCycleDay ?? startDay);
          return cycleDay >= startDay && cycleDay <= endDay;
        }
        return false;

      case SupplementScheduleRuleType.cycleDaysOrPeak:
        if (startCycleDay != null && cycleDay < startCycleDay!) return false;
        if (hasPeakOccurred &&
            daysPastPeak != null &&
            daysPastPeak >= 0 &&
            endPeakOffset != null) {
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
        final startDay = startCycleDay ?? 1;
        final endSuffix = endCycleDay != null ? ' – Day $endCycleDay' : '+';
        return 'Cycle Day $startDay$endSuffix';
      case SupplementScheduleRuleType.peakOffset:
        final durationSuffix = durationDays != null
            ? ' for $durationDays days'
            : (endPeakOffset != null ? ' to P+$endPeakOffset' : '');
        final fallbackSuffix = startCycleDay != null
            ? ' (or Day $startCycleDay)'
            : '';
        final peakPrefix = (startPeakOffset ?? 0) >= 0
            ? 'P+${startPeakOffset ?? 0}'
            : 'P${startPeakOffset ?? 0}';
        return '$peakPrefix$fallbackSuffix$durationSuffix';
      case SupplementScheduleRuleType.cycleDaysOrPeak:
        final startDay = startCycleDay ?? 1;
        final peakEnd = endPeakOffset != null
            ? (endPeakOffset! >= 0 ? 'P+$endPeakOffset' : 'P$endPeakOffset')
            : 'Peak';
        final fallbackSuffix = endCycleDay != null
            ? ' (or Day $endCycleDay)'
            : '';
        return 'Day $startDay to $peakEnd$fallbackSuffix';
    }
  }

  factory SupplementItem.fromJson(Map<String, dynamic> json) =>
      _$SupplementItemFromJson(json);

  factory SupplementItem.fromMap(Map<String, dynamic> map) =>
      SupplementItem.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}

DateTime _parseSupplementLogDateFromJson(Object? rawDate) =>
    parseIsoDate(rawDate?.toString() ?? '');

String _serializeSupplementLogDateToDateKey(DateTime date) => date.dateKey;

Map<String, List<SupplementTimeOfDay>> _parseTakenDosesFromJson(
  Object? rawDoses,
) {
  if (rawDoses is! Map) return const {};
  final doses = <String, List<SupplementTimeOfDay>>{};
  rawDoses.forEach((key, value) {
    final list = ((value is List ? value : const []))
        .map((item) {
          return SupplementTimeOfDay.values
              .cast<SupplementTimeOfDay?>()
              .firstWhere(
                (element) => element?.name == item,
                orElse: () => null,
              );
        })
        .whereType<SupplementTimeOfDay>()
        .toList();
    doses[key.toString()] = list;
  });
  return doses;
}

Map<String, List<String>> _serializeTakenDosesToJson(
  Map<String, List<SupplementTimeOfDay>> takenDoses,
) => takenDoses.map(
  (key, times) =>
      MapEntry(key, times.map((timeOfDay) => timeOfDay.name).toList()),
);

@freezed
abstract class DailySupplementLog with _$DailySupplementLog {
  const DailySupplementLog._();

  const factory DailySupplementLog.raw({
    @JsonKey(
      fromJson: _parseSupplementLogDateFromJson,
      toJson: _serializeSupplementLogDateToDateKey,
    )
    required DateTime date,
    @Default(<String, List<SupplementTimeOfDay>>{})
    @JsonKey(
      fromJson: _parseTakenDosesFromJson,
      toJson: _serializeTakenDosesToJson,
    )
    Map<String, List<SupplementTimeOfDay>> takenDoses,
  }) = _DailySupplementLog;

  factory DailySupplementLog({
    required DateTime date,
    required Map<String, List<SupplementTimeOfDay>> takenDoses,
  }) {
    return DailySupplementLog.raw(
      date: date.toNormalizedDate(),
      takenDoses: takenDoses,
    );
  }

  bool isTaken(String supplementId, SupplementTimeOfDay timeOfDay) {
    final times = takenDoses[supplementId];
    return times != null && times.contains(timeOfDay);
  }

  DailySupplementLog withToggled(
    String supplementId,
    SupplementTimeOfDay timeOfDay,
    bool taken,
  ) {
    final updatedDoses = Map<String, List<SupplementTimeOfDay>>.from(
      takenDoses.map(
        (key, value) => MapEntry(key, List<SupplementTimeOfDay>.from(value)),
      ),
    );
    final currentList = updatedDoses[supplementId] ?? [];
    if (taken) {
      if (!currentList.contains(timeOfDay)) {
        currentList.add(timeOfDay);
      }
      updatedDoses[supplementId] = currentList;
    } else {
      currentList.remove(timeOfDay);
      if (currentList.isEmpty) {
        updatedDoses.remove(supplementId);
      } else {
        updatedDoses[supplementId] = currentList;
      }
    }
    return DailySupplementLog(date: date, takenDoses: updatedDoses);
  }

  factory DailySupplementLog.fromJson(Map<String, dynamic> json) =>
      _$DailySupplementLogFromJson(json);

  factory DailySupplementLog.fromMap(Map<String, dynamic> map) =>
      DailySupplementLog.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}

class SupplementPresets {
  static const List<SupplementItem> defaultList = [
    // Wife Presets (14 standard Creighton / NaPro items)
    SupplementItem(
      id: 'preset_prenatal',
      name: 'Prenatal',
      quantity: 'tablet',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Baseline nutritional support',
    ),
    SupplementItem(
      id: 'preset_coq10',
      name: 'CoQ10',
      quantity: '200 mg',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Oocyte quality & mitochondrial support',
    ),
    SupplementItem(
      id: 'preset_vitamind',
      name: 'Vitamin D',
      quantity: '3000 units',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.wife,
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
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Antioxidant & cellular health',
    ),
    SupplementItem(
      id: 'preset_folate_b12',
      name: 'L-methylfolate and sublingual B12',
      quantity: '1/2 lozenge',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.wife,
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
      targetRole: UserRole.wife,
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
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Metabolic & glucose regulation',
    ),
    SupplementItem(
      id: 'preset_fatty15',
      name: 'Fatty 15',
      quantity: '1 tablet',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Cellular membrane support',
    ),
    SupplementItem(
      id: 'preset_magnesium',
      name: 'Magnesium L-Theonate',
      quantity: '2000mg (1 tablet)',
      takeWithFood: false,
      eveningDose: 1,
      targetRole: UserRole.wife,
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
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Essential amino acid support',
    ),
    SupplementItem(
      id: 'preset_clomid',
      name: 'Clomid',
      quantity: '50 mg (1 tablet)',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.wife,
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
      targetRole: UserRole.wife,
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
      targetRole: UserRole.wife,
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
      targetRole: UserRole.wife,
      ruleType: SupplementScheduleRuleType.peakOffset,
      startPeakOffset: 3,
      startCycleDay: 21,
      durationDays: 10,
      instructions: 'Luteal phase support (P+3 or Day 21 for 10 days)',
    ),

    // Husband Presets (Standard male fertility & health support)
    SupplementItem(
      id: 'preset_mens_multi',
      name: "Men's Multivitamin",
      quantity: '1 tablet',
      takeWithFood: true,
      morningDose: 1,
      targetRole: UserRole.husband,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Baseline male nutritional & energy support',
    ),
    SupplementItem(
      id: 'preset_mens_coq10',
      name: 'CoQ10 (Male Support)',
      quantity: '200 mg',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.husband,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Sperm motility & mitochondrial antioxidant support',
    ),
    SupplementItem(
      id: 'preset_mens_zinc_folate',
      name: 'Zinc & L-Methylfolate',
      quantity: '30 mg / 400 mcg',
      takeWithFood: true,
      morningDose: 1,
      targetRole: UserRole.husband,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Sperm morphology & cellular DNA integrity',
    ),
    SupplementItem(
      id: 'preset_mens_lcarnitine',
      name: 'L-Carnitine',
      quantity: '1000 mg',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.husband,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Sperm motility & energetic metabolism',
    ),
    SupplementItem(
      id: 'preset_mens_ashwagandha',
      name: 'Ashwagandha (KSM-66)',
      quantity: '600 mg',
      takeWithFood: false,
      eveningDose: 1,
      targetRole: UserRole.husband,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Cortisol regulation & reproductive vitality',
    ),
    SupplementItem(
      id: 'preset_mens_vitamind',
      name: 'Vitamin D3',
      quantity: '2000 units',
      takeWithFood: false,
      morningDose: 1,
      targetRole: UserRole.husband,
      ruleType: SupplementScheduleRuleType.allDays,
      instructions: 'Endocrine & testosterone support',
    ),
  ];
}
