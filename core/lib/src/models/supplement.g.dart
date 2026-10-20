// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupplementItem _$SupplementItemFromJson(Map json) => _SupplementItem(
  id: json['id'] == null ? '' : _parseSupplementStringFromJson(json['id']),
  name: json['name'] == null
      ? ''
      : _parseSupplementStringFromJson(json['name']),
  quantity: json['quantity'] == null
      ? ''
      : _parseSupplementStringFromJson(json['quantity']),
  takeWithFood: json['takeWithFood'] == null
      ? false
      : _parseSupplementBoolFalseFromJson(json['takeWithFood']),
  morningDose: json['morningDose'] == null
      ? 0
      : _parseSupplementDoseFromJson(json['morningDose']),
  afternoonDose: json['afternoonDose'] == null
      ? 0
      : _parseSupplementDoseFromJson(json['afternoonDose']),
  eveningDose: json['eveningDose'] == null
      ? 0
      : _parseSupplementDoseFromJson(json['eveningDose']),
  ruleType: json['ruleType'] == null
      ? SupplementScheduleRuleType.allDays
      : _parseRuleTypeFromJson(json['ruleType']),
  startCycleDay: _parseNullableIntFromJson(json['startCycleDay']),
  endCycleDay: _parseNullableIntFromJson(json['endCycleDay']),
  startPeakOffset: _parseNullableIntFromJson(json['startPeakOffset']),
  endPeakOffset: _parseNullableIntFromJson(json['endPeakOffset']),
  durationDays: _parseNullableIntFromJson(json['durationDays']),
  instructions: json['instructions'] == null
      ? ''
      : _parseSupplementStringFromJson(json['instructions']),
  isActive: json['isActive'] == null
      ? true
      : _parseSupplementBoolTrueFromJson(json['isActive']),
  targetRole: json['targetRole'] == null
      ? UserRole.wife
      : _parseTargetRoleFromJson(json['targetRole']),
);

Map<String, dynamic> _$SupplementItemToJson(_SupplementItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'takeWithFood': instance.takeWithFood,
      'morningDose': instance.morningDose,
      'afternoonDose': instance.afternoonDose,
      'eveningDose': instance.eveningDose,
      'ruleType': _serializeRuleTypeToJson(instance.ruleType),
      'startCycleDay': instance.startCycleDay,
      'endCycleDay': instance.endCycleDay,
      'startPeakOffset': instance.startPeakOffset,
      'endPeakOffset': instance.endPeakOffset,
      'durationDays': instance.durationDays,
      'instructions': instance.instructions,
      'isActive': instance.isActive,
      'targetRole': _serializeTargetRoleToJson(instance.targetRole),
    };

_DailySupplementLog _$DailySupplementLogFromJson(Map json) =>
    _DailySupplementLog(
      date: _parseSupplementLogDateFromJson(json['date']),
      takenDoses: json['takenDoses'] == null
          ? const <String, List<SupplementTimeOfDay>>{}
          : _parseTakenDosesFromJson(json['takenDoses']),
    );

Map<String, dynamic> _$DailySupplementLogToJson(_DailySupplementLog instance) =>
    <String, dynamic>{
      'date': _serializeSupplementLogDateToDateKey(instance.date),
      'takenDoses': _serializeTakenDosesToJson(instance.takenDoses),
    };
