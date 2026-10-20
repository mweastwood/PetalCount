import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/date_utils.dart';
import 'user_role.dart';

export 'supplement_presets.dart';

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
