// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Cycle _$CycleFromJson(Map json) => _Cycle(
  id: json['id'] == null ? '' : _parseCycleIdFromJson(json['id']),
  startDate: _parseCycleStartDateFromJson(json['startDate']),
  endDate: _parseCycleEndDateFromJson(json['endDate']),
  bipCodes: json['bipCodes'] == null
      ? const <String>[]
      : _parseBasicInfertilePatternCodesFromJson(json['bipCodes']),
  dailyEntries: json['dailyEntries'] == null
      ? const <String, DailyEntry>{}
      : _parseDailyEntriesFromJson(json['dailyEntries']),
);

Map<String, dynamic> _$CycleToJson(_Cycle instance) => <String, dynamic>{
  'id': instance.id,
  'startDate': _serializeCycleDateToDateKey(instance.startDate),
  'endDate': _serializeCycleEndDateToDateKey(instance.endDate),
  'bipCodes': instance.bipCodes,
  'dailyEntries': _serializeDailyEntriesToJson(instance.dailyEntries),
};
