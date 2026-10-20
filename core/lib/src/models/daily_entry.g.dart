// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyEntry _$DailyEntryFromJson(Map json) => _DailyEntry(
  date: _parseNormalizedDateFromJson(json['date']),
  resolvedVdrsCode: json['resolvedVdrsCode'] == null
      ? ''
      : _parseStringFromJson(json['resolvedVdrsCode']),
  stampType: json['stampType'] == null
      ? StampType.green
      : _parseStampTypeFromJson(json['stampType']),
  observations: json['observations'] == null
      ? const <Observation>[]
      : _parseObservationsFromJson(json['observations']),
  painLevel: json['painLevel'] == null
      ? 0.0
      : _parsePainLevelFromJson(json['painLevel']),
  painTypes: json['painTypes'] == null
      ? const <String>[]
      : _parsePainTypesFromJson(json['painTypes']),
  comments: json['comments'] == null
      ? ''
      : _parseStringFromJson(json['comments']),
  peakDayLabel: json['peakDayLabel'] as String?,
);

Map<String, dynamic> _$DailyEntryToJson(_DailyEntry instance) =>
    <String, dynamic>{
      'date': _serializeDateToDateKey(instance.date),
      'resolvedVdrsCode': instance.resolvedVdrsCode,
      'stampType': _serializeStampTypeToJson(instance.stampType),
      'observations': _serializeObservationsToJson(instance.observations),
      'painLevel': instance.painLevel,
      'painTypes': instance.painTypes,
      'comments': instance.comments,
      'peakDayLabel': instance.peakDayLabel,
    };
