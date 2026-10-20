// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyEntry {

@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey) DateTime get date;@JsonKey(fromJson: _parseStringFromJson) String get resolvedVdrsCode;@JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson) StampType get stampType;@JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson) List<Observation> get observations;@JsonKey(fromJson: _parsePainLevelFromJson) double get painLevel;@JsonKey(fromJson: _parsePainTypesFromJson) List<String> get painTypes;@JsonKey(fromJson: _parseStringFromJson) String get comments; String? get peakDayLabel;
/// Create a copy of DailyEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyEntryCopyWith<DailyEntry> get copyWith => _$DailyEntryCopyWithImpl<DailyEntry>(this as DailyEntry, _$identity);

  /// Serializes this DailyEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DailyEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyEntry&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.resolvedVdrsCode, _this.resolvedVdrsCode) || other.resolvedVdrsCode == _this.resolvedVdrsCode)&&(identical(other.stampType, _this.stampType) || other.stampType == _this.stampType)&&const DeepCollectionEquality().equals(other.observations, _this.observations)&&(identical(other.painLevel, _this.painLevel) || other.painLevel == _this.painLevel)&&const DeepCollectionEquality().equals(other.painTypes, _this.painTypes)&&(identical(other.comments, _this.comments) || other.comments == _this.comments)&&(identical(other.peakDayLabel, _this.peakDayLabel) || other.peakDayLabel == _this.peakDayLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DailyEntry;
  return Object.hash(runtimeType,_this.date,_this.resolvedVdrsCode,_this.stampType,const DeepCollectionEquality().hash(_this.observations),_this.painLevel,const DeepCollectionEquality().hash(_this.painTypes),_this.comments,_this.peakDayLabel);
}

@override
String toString() {
  final _this = this as DailyEntry;
  return 'DailyEntry(date: ${_this.date}, resolvedVdrsCode: ${_this.resolvedVdrsCode}, stampType: ${_this.stampType}, observations: ${_this.observations}, painLevel: ${_this.painLevel}, painTypes: ${_this.painTypes}, comments: ${_this.comments}, peakDayLabel: ${_this.peakDayLabel})';
}


}

/// @nodoc
abstract mixin class $DailyEntryCopyWith<$Res>  {
  factory $DailyEntryCopyWith(DailyEntry value, $Res Function(DailyEntry) _then) = _$DailyEntryCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey) DateTime date,@JsonKey(fromJson: _parseStringFromJson) String resolvedVdrsCode,@JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson) StampType stampType,@JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson) List<Observation> observations,@JsonKey(fromJson: _parsePainLevelFromJson) double painLevel,@JsonKey(fromJson: _parsePainTypesFromJson) List<String> painTypes,@JsonKey(fromJson: _parseStringFromJson) String comments, String? peakDayLabel
});




}
/// @nodoc
class _$DailyEntryCopyWithImpl<$Res>
    implements $DailyEntryCopyWith<$Res> {
  _$DailyEntryCopyWithImpl(this._self, this._then);

  final DailyEntry _self;
  final $Res Function(DailyEntry) _then;

/// Create a copy of DailyEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? resolvedVdrsCode = null,Object? stampType = null,Object? observations = null,Object? painLevel = null,Object? painTypes = null,Object? comments = null,Object? peakDayLabel = freezed,}) {
  return _then(DailyEntry(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedVdrsCode: null == resolvedVdrsCode ? _self.resolvedVdrsCode : resolvedVdrsCode // ignore: cast_nullable_to_non_nullable
as String,stampType: null == stampType ? _self.stampType : stampType // ignore: cast_nullable_to_non_nullable
as StampType,observations: null == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as List<Observation>,painLevel: null == painLevel ? _self.painLevel : painLevel // ignore: cast_nullable_to_non_nullable
as double,painTypes: null == painTypes ? _self.painTypes : painTypes // ignore: cast_nullable_to_non_nullable
as List<String>,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as String,peakDayLabel: freezed == peakDayLabel ? _self.peakDayLabel : peakDayLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyEntry].
extension DailyEntryPatterns on DailyEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _DailyEntry value)?  raw,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyEntry() when raw != null:
return raw(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _DailyEntry value)  raw,}){
final _that = this;
switch (_that) {
case _DailyEntry():
return raw(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _DailyEntry value)?  raw,}){
final _that = this;
switch (_that) {
case _DailyEntry() when raw != null:
return raw(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey)  DateTime date, @JsonKey(fromJson: _parseStringFromJson)  String resolvedVdrsCode, @JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson)  StampType stampType, @JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson)  List<Observation> observations, @JsonKey(fromJson: _parsePainLevelFromJson)  double painLevel, @JsonKey(fromJson: _parsePainTypesFromJson)  List<String> painTypes, @JsonKey(fromJson: _parseStringFromJson)  String comments,  String? peakDayLabel)?  raw,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyEntry() when raw != null:
return raw(_that.date,_that.resolvedVdrsCode,_that.stampType,_that.observations,_that.painLevel,_that.painTypes,_that.comments,_that.peakDayLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey)  DateTime date, @JsonKey(fromJson: _parseStringFromJson)  String resolvedVdrsCode, @JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson)  StampType stampType, @JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson)  List<Observation> observations, @JsonKey(fromJson: _parsePainLevelFromJson)  double painLevel, @JsonKey(fromJson: _parsePainTypesFromJson)  List<String> painTypes, @JsonKey(fromJson: _parseStringFromJson)  String comments,  String? peakDayLabel)  raw,}) {final _that = this;
switch (_that) {
case _DailyEntry():
return raw(_that.date,_that.resolvedVdrsCode,_that.stampType,_that.observations,_that.painLevel,_that.painTypes,_that.comments,_that.peakDayLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey)  DateTime date, @JsonKey(fromJson: _parseStringFromJson)  String resolvedVdrsCode, @JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson)  StampType stampType, @JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson)  List<Observation> observations, @JsonKey(fromJson: _parsePainLevelFromJson)  double painLevel, @JsonKey(fromJson: _parsePainTypesFromJson)  List<String> painTypes, @JsonKey(fromJson: _parseStringFromJson)  String comments,  String? peakDayLabel)?  raw,}) {final _that = this;
switch (_that) {
case _DailyEntry() when raw != null:
return raw(_that.date,_that.resolvedVdrsCode,_that.stampType,_that.observations,_that.painLevel,_that.painTypes,_that.comments,_that.peakDayLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyEntry extends DailyEntry {
  const _DailyEntry({@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey) required this.date, @JsonKey(fromJson: _parseStringFromJson) this.resolvedVdrsCode = '', @JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson) this.stampType = StampType.green, @JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson)  List<Observation> observations = const <Observation>[], @JsonKey(fromJson: _parsePainLevelFromJson) this.painLevel = 0.0, @JsonKey(fromJson: _parsePainTypesFromJson)  List<String> painTypes = const <String>[], @JsonKey(fromJson: _parseStringFromJson) this.comments = '', this.peakDayLabel}): _observations = observations,_painTypes = painTypes,super._();
  factory _DailyEntry.fromJson(Map<String, dynamic> json) => _$DailyEntryFromJson(json);

@override@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey) final  DateTime date;
@override@JsonKey(fromJson: _parseStringFromJson) final  String resolvedVdrsCode;
@override@JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson) final  StampType stampType;
 final  List<Observation> _observations;
@override@JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson) List<Observation> get observations {
  if (_observations is EqualUnmodifiableListView) return _observations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_observations);
}

@override@JsonKey(fromJson: _parsePainLevelFromJson) final  double painLevel;
 final  List<String> _painTypes;
@override@JsonKey(fromJson: _parsePainTypesFromJson) List<String> get painTypes {
  if (_painTypes is EqualUnmodifiableListView) return _painTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_painTypes);
}

@override@JsonKey(fromJson: _parseStringFromJson) final  String comments;
@override final  String? peakDayLabel;

/// Create a copy of DailyEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyEntryCopyWith<_DailyEntry> get copyWith => __$DailyEntryCopyWithImpl<_DailyEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyEntry&&(identical(other.date, date) || other.date == date)&&(identical(other.resolvedVdrsCode, resolvedVdrsCode) || other.resolvedVdrsCode == resolvedVdrsCode)&&(identical(other.stampType, stampType) || other.stampType == stampType)&&const DeepCollectionEquality().equals(other.observations, _observations)&&(identical(other.painLevel, painLevel) || other.painLevel == painLevel)&&const DeepCollectionEquality().equals(other.painTypes, _painTypes)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.peakDayLabel, peakDayLabel) || other.peakDayLabel == peakDayLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,resolvedVdrsCode,stampType,const DeepCollectionEquality().hash(_observations),painLevel,const DeepCollectionEquality().hash(_painTypes),comments,peakDayLabel);
}

@override
String toString() {
    return 'DailyEntry.raw(date: $date, resolvedVdrsCode: $resolvedVdrsCode, stampType: $stampType, observations: $observations, painLevel: $painLevel, painTypes: $painTypes, comments: $comments, peakDayLabel: $peakDayLabel)';
}


}

/// @nodoc
abstract mixin class _$DailyEntryCopyWith<$Res> implements $DailyEntryCopyWith<$Res> {
  factory _$DailyEntryCopyWith(_DailyEntry value, $Res Function(_DailyEntry) _then) = __$DailyEntryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _parseNormalizedDateFromJson, toJson: _serializeDateToDateKey) DateTime date,@JsonKey(fromJson: _parseStringFromJson) String resolvedVdrsCode,@JsonKey(fromJson: _parseStampTypeFromJson, toJson: _serializeStampTypeToJson) StampType stampType,@JsonKey(fromJson: _parseObservationsFromJson, toJson: _serializeObservationsToJson) List<Observation> observations,@JsonKey(fromJson: _parsePainLevelFromJson) double painLevel,@JsonKey(fromJson: _parsePainTypesFromJson) List<String> painTypes,@JsonKey(fromJson: _parseStringFromJson) String comments, String? peakDayLabel
});




}
/// @nodoc
class __$DailyEntryCopyWithImpl<$Res>
    implements _$DailyEntryCopyWith<$Res> {
  __$DailyEntryCopyWithImpl(this._self, this._then);

  final _DailyEntry _self;
  final $Res Function(_DailyEntry) _then;

/// Create a copy of DailyEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? resolvedVdrsCode = null,Object? stampType = null,Object? observations = null,Object? painLevel = null,Object? painTypes = null,Object? comments = null,Object? peakDayLabel = freezed,}) {
  return _then(_DailyEntry(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedVdrsCode: null == resolvedVdrsCode ? _self.resolvedVdrsCode : resolvedVdrsCode // ignore: cast_nullable_to_non_nullable
as String,stampType: null == stampType ? _self.stampType : stampType // ignore: cast_nullable_to_non_nullable
as StampType,observations: null == observations ? _self._observations : observations // ignore: cast_nullable_to_non_nullable
as List<Observation>,painLevel: null == painLevel ? _self.painLevel : painLevel // ignore: cast_nullable_to_non_nullable
as double,painTypes: null == painTypes ? _self._painTypes : painTypes // ignore: cast_nullable_to_non_nullable
as List<String>,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as String,peakDayLabel: freezed == peakDayLabel ? _self.peakDayLabel : peakDayLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
