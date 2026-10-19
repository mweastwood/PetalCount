// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Observation _$ObservationFromJson(Map json) => _Observation(
  id: json['id'] == null ? '' : _parseStringWithDefaultEmpty(json['id']),
  timestamp: _parseTimestampFromJson(json['timestamp']),
  sensation: json['sensation'] == null
      ? Sensation.dry
      : _parseSensationFromJson(json['sensation']),
  stretch: json['stretch'] == null
      ? Stretch.none
      : _parseStretchFromJson(json['stretch']),
  colors: json['colors'] == null
      ? const <MucusColor>[]
      : _parseMucusColorsFromJson(json['colors']),
  consistencies: json['consistencies'] == null
      ? const <Consistency>[]
      : _parseConsistenciesFromJson(json['consistencies']),
  bleeding: json['bleeding'] == null
      ? Bleeding.none
      : _parseBleedingFromJson(json['bleeding']),
  bleedingColor: json['bleedingColor'] == null
      ? ''
      : _parseStringWithDefaultEmpty(json['bleedingColor']),
  frequency: json['frequency'] == null
      ? Frequency.none
      : _parseFrequencyFromJson(json['frequency']),
  intercourse: json['intercourse'] == null
      ? false
      : _parseBooleanWithDefaultFalse(json['intercourse']),
  painLevel: json['painLevel'] == null
      ? 0.0
      : _parseDoubleWithDefaultZero(json['painLevel']),
  painTypes: json['painTypes'] == null
      ? const <String>[]
      : _parseStringListFromJson(json['painTypes']),
  comment: json['comment'] == null
      ? ''
      : _parseStringWithDefaultEmpty(json['comment']),
  userId: json['userId'] == null
      ? ''
      : _parseStringWithDefaultEmpty(json['userId']),
  userRole: json['userRole'] as String?,
  isVdrsExplicit: json['isVdrsExplicit'] as bool,
);

Map<String, dynamic> _$ObservationToJson(_Observation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': _serializeTimestampToJson(instance.timestamp),
      'sensation': _$SensationEnumMap[instance.sensation]!,
      'stretch': _$StretchEnumMap[instance.stretch]!,
      'colors': instance.colors.map((e) => _$MucusColorEnumMap[e]!).toList(),
      'consistencies': instance.consistencies
          .map((e) => _$ConsistencyEnumMap[e]!)
          .toList(),
      'bleeding': _$BleedingEnumMap[instance.bleeding]!,
      'bleedingColor': instance.bleedingColor,
      'frequency': _$FrequencyEnumMap[instance.frequency]!,
      'intercourse': instance.intercourse,
      'painLevel': instance.painLevel,
      'painTypes': instance.painTypes,
      'comment': instance.comment,
      'userId': instance.userId,
      'userRole': ?instance.userRole,
      'isVdrsExplicit': instance.isVdrsExplicit,
    };

const _$SensationEnumMap = {
  Sensation.dry: 'dry',
  Sensation.damp: 'damp',
  Sensation.wet: 'wet',
  Sensation.shiny: 'shiny',
};

const _$StretchEnumMap = {
  Stretch.none: 'none',
  Stretch.sticky: 'sticky',
  Stretch.tacky: 'tacky',
  Stretch.stretchy: 'stretchy',
};

const _$MucusColorEnumMap = {
  MucusColor.clear: 'clear',
  MucusColor.cloudy: 'cloudy',
  MucusColor.yellow: 'yellow',
  MucusColor.red: 'red',
  MucusColor.brown: 'brown',
};

const _$ConsistencyEnumMap = {
  Consistency.gummy: 'gummy',
  Consistency.pasty: 'pasty',
  Consistency.lubricative: 'lubricative',
};

const _$BleedingEnumMap = {
  Bleeding.none: 'none',
  Bleeding.heavy: 'heavy',
  Bleeding.moderate: 'moderate',
  Bleeding.light: 'light',
  Bleeding.veryLight: 'veryLight',
  Bleeding.spotting: 'spotting',
  Bleeding.black: 'black',
  Bleeding.brown: 'brown',
  Bleeding.red: 'red',
};

const _$FrequencyEnumMap = {
  Frequency.none: 'none',
  Frequency.once: 'once',
  Frequency.twice: 'twice',
  Frequency.thrice: 'thrice',
  Frequency.allDay: 'allDay',
};
