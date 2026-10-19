// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'observation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Observation {

@JsonKey(fromJson: _parseStringWithDefaultEmpty) String get id;@JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson) DateTime get timestamp;@JsonKey(fromJson: _parseSensationFromJson) Sensation get sensation;@JsonKey(fromJson: _parseStretchFromJson) Stretch get stretch;@JsonKey(fromJson: _parseMucusColorsFromJson) List<MucusColor> get colors;@JsonKey(fromJson: _parseConsistenciesFromJson) List<Consistency> get consistencies;@JsonKey(fromJson: _parseBleedingFromJson) Bleeding get bleeding;@JsonKey(fromJson: _parseStringWithDefaultEmpty) String get bleedingColor;@JsonKey(fromJson: _parseFrequencyFromJson) Frequency get frequency;@JsonKey(fromJson: _parseBooleanWithDefaultFalse) bool get intercourse;@JsonKey(fromJson: _parseDoubleWithDefaultZero) double get painLevel;@JsonKey(fromJson: _parseStringListFromJson) List<String> get painTypes;@JsonKey(fromJson: _parseStringWithDefaultEmpty) String get comment;@JsonKey(fromJson: _parseStringWithDefaultEmpty) String get userId;@JsonKey(includeIfNull: false) String? get userRole; bool get isVdrsExplicit;
/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ObservationCopyWith<Observation> get copyWith => _$ObservationCopyWithImpl<Observation>(this as Observation, _$identity);

  /// Serializes this Observation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Observation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Observation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp)&&(identical(other.sensation, _this.sensation) || other.sensation == _this.sensation)&&(identical(other.stretch, _this.stretch) || other.stretch == _this.stretch)&&const DeepCollectionEquality().equals(other.colors, _this.colors)&&const DeepCollectionEquality().equals(other.consistencies, _this.consistencies)&&(identical(other.bleeding, _this.bleeding) || other.bleeding == _this.bleeding)&&(identical(other.bleedingColor, _this.bleedingColor) || other.bleedingColor == _this.bleedingColor)&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.intercourse, _this.intercourse) || other.intercourse == _this.intercourse)&&(identical(other.painLevel, _this.painLevel) || other.painLevel == _this.painLevel)&&const DeepCollectionEquality().equals(other.painTypes, _this.painTypes)&&(identical(other.comment, _this.comment) || other.comment == _this.comment)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.userRole, _this.userRole) || other.userRole == _this.userRole)&&(identical(other.isVdrsExplicit, _this.isVdrsExplicit) || other.isVdrsExplicit == _this.isVdrsExplicit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Observation;
  return Object.hash(runtimeType,_this.id,_this.timestamp,_this.sensation,_this.stretch,const DeepCollectionEquality().hash(_this.colors),const DeepCollectionEquality().hash(_this.consistencies),_this.bleeding,_this.bleedingColor,_this.frequency,_this.intercourse,_this.painLevel,const DeepCollectionEquality().hash(_this.painTypes),_this.comment,_this.userId,_this.userRole,_this.isVdrsExplicit);
}

@override
String toString() {
  final _this = this as Observation;
  return 'Observation(id: ${_this.id}, timestamp: ${_this.timestamp}, sensation: ${_this.sensation}, stretch: ${_this.stretch}, colors: ${_this.colors}, consistencies: ${_this.consistencies}, bleeding: ${_this.bleeding}, bleedingColor: ${_this.bleedingColor}, frequency: ${_this.frequency}, intercourse: ${_this.intercourse}, painLevel: ${_this.painLevel}, painTypes: ${_this.painTypes}, comment: ${_this.comment}, userId: ${_this.userId}, userRole: ${_this.userRole}, isVdrsExplicit: ${_this.isVdrsExplicit})';
}


}

/// @nodoc
abstract mixin class $ObservationCopyWith<$Res>  {
  factory $ObservationCopyWith(Observation value, $Res Function(Observation) _then) = _$ObservationCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _parseStringWithDefaultEmpty) String id,@JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson) DateTime timestamp,@JsonKey(fromJson: _parseSensationFromJson) Sensation sensation,@JsonKey(fromJson: _parseStretchFromJson) Stretch stretch,@JsonKey(fromJson: _parseMucusColorsFromJson) List<MucusColor> colors,@JsonKey(fromJson: _parseConsistenciesFromJson) List<Consistency> consistencies,@JsonKey(fromJson: _parseBleedingFromJson) Bleeding bleeding,@JsonKey(fromJson: _parseStringWithDefaultEmpty) String bleedingColor,@JsonKey(fromJson: _parseFrequencyFromJson) Frequency frequency,@JsonKey(fromJson: _parseBooleanWithDefaultFalse) bool intercourse,@JsonKey(fromJson: _parseDoubleWithDefaultZero) double painLevel,@JsonKey(fromJson: _parseStringListFromJson) List<String> painTypes,@JsonKey(fromJson: _parseStringWithDefaultEmpty) String comment,@JsonKey(fromJson: _parseStringWithDefaultEmpty) String userId,@JsonKey(includeIfNull: false) String? userRole, bool isVdrsExplicit
});




}
/// @nodoc
class _$ObservationCopyWithImpl<$Res>
    implements $ObservationCopyWith<$Res> {
  _$ObservationCopyWithImpl(this._self, this._then);

  final Observation _self;
  final $Res Function(Observation) _then;

/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? timestamp = null,Object? sensation = null,Object? stretch = null,Object? colors = null,Object? consistencies = null,Object? bleeding = null,Object? bleedingColor = null,Object? frequency = null,Object? intercourse = null,Object? painLevel = null,Object? painTypes = null,Object? comment = null,Object? userId = null,Object? userRole = freezed,Object? isVdrsExplicit = null,}) {
  return _then(Observation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,sensation: null == sensation ? _self.sensation : sensation // ignore: cast_nullable_to_non_nullable
as Sensation,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as Stretch,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as List<MucusColor>,consistencies: null == consistencies ? _self.consistencies : consistencies // ignore: cast_nullable_to_non_nullable
as List<Consistency>,bleeding: null == bleeding ? _self.bleeding : bleeding // ignore: cast_nullable_to_non_nullable
as Bleeding,bleedingColor: null == bleedingColor ? _self.bleedingColor : bleedingColor // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,intercourse: null == intercourse ? _self.intercourse : intercourse // ignore: cast_nullable_to_non_nullable
as bool,painLevel: null == painLevel ? _self.painLevel : painLevel // ignore: cast_nullable_to_non_nullable
as double,painTypes: null == painTypes ? _self.painTypes : painTypes // ignore: cast_nullable_to_non_nullable
as List<String>,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userRole: freezed == userRole ? _self.userRole : userRole // ignore: cast_nullable_to_non_nullable
as String?,isVdrsExplicit: freezed == isVdrsExplicit ? _self.isVdrsExplicit! : isVdrsExplicit // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [Observation].
extension ObservationPatterns on Observation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Observation value)?  raw,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Observation() when raw != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Observation value)  raw,}){
final _that = this;
switch (_that) {
case _Observation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Observation value)?  raw,}){
final _that = this;
switch (_that) {
case _Observation() when raw != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(fromJson: _parseStringWithDefaultEmpty)  String id, @JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson)  DateTime timestamp, @JsonKey(fromJson: _parseSensationFromJson)  Sensation sensation, @JsonKey(fromJson: _parseStretchFromJson)  Stretch stretch, @JsonKey(fromJson: _parseMucusColorsFromJson)  List<MucusColor> colors, @JsonKey(fromJson: _parseConsistenciesFromJson)  List<Consistency> consistencies, @JsonKey(fromJson: _parseBleedingFromJson)  Bleeding bleeding, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String bleedingColor, @JsonKey(fromJson: _parseFrequencyFromJson)  Frequency frequency, @JsonKey(fromJson: _parseBooleanWithDefaultFalse)  bool intercourse, @JsonKey(fromJson: _parseDoubleWithDefaultZero)  double painLevel, @JsonKey(fromJson: _parseStringListFromJson)  List<String> painTypes, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String comment, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String userId, @JsonKey(includeIfNull: false)  String? userRole,  bool isVdrsExplicit)?  raw,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Observation() when raw != null:
return raw(_that.id,_that.timestamp,_that.sensation,_that.stretch,_that.colors,_that.consistencies,_that.bleeding,_that.bleedingColor,_that.frequency,_that.intercourse,_that.painLevel,_that.painTypes,_that.comment,_that.userId,_that.userRole,_that.isVdrsExplicit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(fromJson: _parseStringWithDefaultEmpty)  String id, @JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson)  DateTime timestamp, @JsonKey(fromJson: _parseSensationFromJson)  Sensation sensation, @JsonKey(fromJson: _parseStretchFromJson)  Stretch stretch, @JsonKey(fromJson: _parseMucusColorsFromJson)  List<MucusColor> colors, @JsonKey(fromJson: _parseConsistenciesFromJson)  List<Consistency> consistencies, @JsonKey(fromJson: _parseBleedingFromJson)  Bleeding bleeding, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String bleedingColor, @JsonKey(fromJson: _parseFrequencyFromJson)  Frequency frequency, @JsonKey(fromJson: _parseBooleanWithDefaultFalse)  bool intercourse, @JsonKey(fromJson: _parseDoubleWithDefaultZero)  double painLevel, @JsonKey(fromJson: _parseStringListFromJson)  List<String> painTypes, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String comment, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String userId, @JsonKey(includeIfNull: false)  String? userRole,  bool isVdrsExplicit)  raw,}) {final _that = this;
switch (_that) {
case _Observation():
return raw(_that.id,_that.timestamp,_that.sensation,_that.stretch,_that.colors,_that.consistencies,_that.bleeding,_that.bleedingColor,_that.frequency,_that.intercourse,_that.painLevel,_that.painTypes,_that.comment,_that.userId,_that.userRole,_that.isVdrsExplicit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(fromJson: _parseStringWithDefaultEmpty)  String id, @JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson)  DateTime timestamp, @JsonKey(fromJson: _parseSensationFromJson)  Sensation sensation, @JsonKey(fromJson: _parseStretchFromJson)  Stretch stretch, @JsonKey(fromJson: _parseMucusColorsFromJson)  List<MucusColor> colors, @JsonKey(fromJson: _parseConsistenciesFromJson)  List<Consistency> consistencies, @JsonKey(fromJson: _parseBleedingFromJson)  Bleeding bleeding, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String bleedingColor, @JsonKey(fromJson: _parseFrequencyFromJson)  Frequency frequency, @JsonKey(fromJson: _parseBooleanWithDefaultFalse)  bool intercourse, @JsonKey(fromJson: _parseDoubleWithDefaultZero)  double painLevel, @JsonKey(fromJson: _parseStringListFromJson)  List<String> painTypes, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String comment, @JsonKey(fromJson: _parseStringWithDefaultEmpty)  String userId, @JsonKey(includeIfNull: false)  String? userRole,  bool isVdrsExplicit)?  raw,}) {final _that = this;
switch (_that) {
case _Observation() when raw != null:
return raw(_that.id,_that.timestamp,_that.sensation,_that.stretch,_that.colors,_that.consistencies,_that.bleeding,_that.bleedingColor,_that.frequency,_that.intercourse,_that.painLevel,_that.painTypes,_that.comment,_that.userId,_that.userRole,_that.isVdrsExplicit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Observation extends Observation {
  const _Observation({@JsonKey(fromJson: _parseStringWithDefaultEmpty) this.id = '', @JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson) required this.timestamp, @JsonKey(fromJson: _parseSensationFromJson) this.sensation = Sensation.dry, @JsonKey(fromJson: _parseStretchFromJson) this.stretch = Stretch.none, @JsonKey(fromJson: _parseMucusColorsFromJson)  List<MucusColor> colors = const <MucusColor>[], @JsonKey(fromJson: _parseConsistenciesFromJson)  List<Consistency> consistencies = const <Consistency>[], @JsonKey(fromJson: _parseBleedingFromJson) this.bleeding = Bleeding.none, @JsonKey(fromJson: _parseStringWithDefaultEmpty) this.bleedingColor = '', @JsonKey(fromJson: _parseFrequencyFromJson) this.frequency = Frequency.none, @JsonKey(fromJson: _parseBooleanWithDefaultFalse) this.intercourse = false, @JsonKey(fromJson: _parseDoubleWithDefaultZero) this.painLevel = 0.0, @JsonKey(fromJson: _parseStringListFromJson)  List<String> painTypes = const <String>[], @JsonKey(fromJson: _parseStringWithDefaultEmpty) this.comment = '', @JsonKey(fromJson: _parseStringWithDefaultEmpty) this.userId = '', @JsonKey(includeIfNull: false) this.userRole, required this.isVdrsExplicit}): _colors = colors,_consistencies = consistencies,_painTypes = painTypes,super._();
  factory _Observation.fromJson(Map<String, dynamic> json) => _$ObservationFromJson(json);

@override@JsonKey(fromJson: _parseStringWithDefaultEmpty) final  String id;
@override@JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson) final  DateTime timestamp;
@override@JsonKey(fromJson: _parseSensationFromJson) final  Sensation sensation;
@override@JsonKey(fromJson: _parseStretchFromJson) final  Stretch stretch;
 final  List<MucusColor> _colors;
@override@JsonKey(fromJson: _parseMucusColorsFromJson) List<MucusColor> get colors {
  if (_colors is EqualUnmodifiableListView) return _colors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colors);
}

 final  List<Consistency> _consistencies;
@override@JsonKey(fromJson: _parseConsistenciesFromJson) List<Consistency> get consistencies {
  if (_consistencies is EqualUnmodifiableListView) return _consistencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_consistencies);
}

@override@JsonKey(fromJson: _parseBleedingFromJson) final  Bleeding bleeding;
@override@JsonKey(fromJson: _parseStringWithDefaultEmpty) final  String bleedingColor;
@override@JsonKey(fromJson: _parseFrequencyFromJson) final  Frequency frequency;
@override@JsonKey(fromJson: _parseBooleanWithDefaultFalse) final  bool intercourse;
@override@JsonKey(fromJson: _parseDoubleWithDefaultZero) final  double painLevel;
 final  List<String> _painTypes;
@override@JsonKey(fromJson: _parseStringListFromJson) List<String> get painTypes {
  if (_painTypes is EqualUnmodifiableListView) return _painTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_painTypes);
}

@override@JsonKey(fromJson: _parseStringWithDefaultEmpty) final  String comment;
@override@JsonKey(fromJson: _parseStringWithDefaultEmpty) final  String userId;
@override@JsonKey(includeIfNull: false) final  String? userRole;
@override final  bool isVdrsExplicit;

/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ObservationCopyWith<_Observation> get copyWith => __$ObservationCopyWithImpl<_Observation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ObservationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Observation&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.sensation, sensation) || other.sensation == sensation)&&(identical(other.stretch, stretch) || other.stretch == stretch)&&const DeepCollectionEquality().equals(other.colors, _colors)&&const DeepCollectionEquality().equals(other.consistencies, _consistencies)&&(identical(other.bleeding, bleeding) || other.bleeding == bleeding)&&(identical(other.bleedingColor, bleedingColor) || other.bleedingColor == bleedingColor)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.intercourse, intercourse) || other.intercourse == intercourse)&&(identical(other.painLevel, painLevel) || other.painLevel == painLevel)&&const DeepCollectionEquality().equals(other.painTypes, _painTypes)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userRole, userRole) || other.userRole == userRole)&&(identical(other.isVdrsExplicit, isVdrsExplicit) || other.isVdrsExplicit == isVdrsExplicit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,timestamp,sensation,stretch,const DeepCollectionEquality().hash(_colors),const DeepCollectionEquality().hash(_consistencies),bleeding,bleedingColor,frequency,intercourse,painLevel,const DeepCollectionEquality().hash(_painTypes),comment,userId,userRole,isVdrsExplicit);
}

@override
String toString() {
    return 'Observation.raw(id: $id, timestamp: $timestamp, sensation: $sensation, stretch: $stretch, colors: $colors, consistencies: $consistencies, bleeding: $bleeding, bleedingColor: $bleedingColor, frequency: $frequency, intercourse: $intercourse, painLevel: $painLevel, painTypes: $painTypes, comment: $comment, userId: $userId, userRole: $userRole, isVdrsExplicit: $isVdrsExplicit)';
}


}

/// @nodoc
abstract mixin class _$ObservationCopyWith<$Res> implements $ObservationCopyWith<$Res> {
  factory _$ObservationCopyWith(_Observation value, $Res Function(_Observation) _then) = __$ObservationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _parseStringWithDefaultEmpty) String id,@JsonKey(fromJson: _parseTimestampFromJson, toJson: _serializeTimestampToJson) DateTime timestamp,@JsonKey(fromJson: _parseSensationFromJson) Sensation sensation,@JsonKey(fromJson: _parseStretchFromJson) Stretch stretch,@JsonKey(fromJson: _parseMucusColorsFromJson) List<MucusColor> colors,@JsonKey(fromJson: _parseConsistenciesFromJson) List<Consistency> consistencies,@JsonKey(fromJson: _parseBleedingFromJson) Bleeding bleeding,@JsonKey(fromJson: _parseStringWithDefaultEmpty) String bleedingColor,@JsonKey(fromJson: _parseFrequencyFromJson) Frequency frequency,@JsonKey(fromJson: _parseBooleanWithDefaultFalse) bool intercourse,@JsonKey(fromJson: _parseDoubleWithDefaultZero) double painLevel,@JsonKey(fromJson: _parseStringListFromJson) List<String> painTypes,@JsonKey(fromJson: _parseStringWithDefaultEmpty) String comment,@JsonKey(fromJson: _parseStringWithDefaultEmpty) String userId,@JsonKey(includeIfNull: false) String? userRole, bool isVdrsExplicit
});




}
/// @nodoc
class __$ObservationCopyWithImpl<$Res>
    implements _$ObservationCopyWith<$Res> {
  __$ObservationCopyWithImpl(this._self, this._then);

  final _Observation _self;
  final $Res Function(_Observation) _then;

/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? timestamp = null,Object? sensation = null,Object? stretch = null,Object? colors = null,Object? consistencies = null,Object? bleeding = null,Object? bleedingColor = null,Object? frequency = null,Object? intercourse = null,Object? painLevel = null,Object? painTypes = null,Object? comment = null,Object? userId = null,Object? userRole = freezed,Object? isVdrsExplicit = null,}) {
  return _then(_Observation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,sensation: null == sensation ? _self.sensation : sensation // ignore: cast_nullable_to_non_nullable
as Sensation,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as Stretch,colors: null == colors ? _self._colors : colors // ignore: cast_nullable_to_non_nullable
as List<MucusColor>,consistencies: null == consistencies ? _self._consistencies : consistencies // ignore: cast_nullable_to_non_nullable
as List<Consistency>,bleeding: null == bleeding ? _self.bleeding : bleeding // ignore: cast_nullable_to_non_nullable
as Bleeding,bleedingColor: null == bleedingColor ? _self.bleedingColor : bleedingColor // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,intercourse: null == intercourse ? _self.intercourse : intercourse // ignore: cast_nullable_to_non_nullable
as bool,painLevel: null == painLevel ? _self.painLevel : painLevel // ignore: cast_nullable_to_non_nullable
as double,painTypes: null == painTypes ? _self._painTypes : painTypes // ignore: cast_nullable_to_non_nullable
as List<String>,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userRole: freezed == userRole ? _self.userRole : userRole // ignore: cast_nullable_to_non_nullable
as String?,isVdrsExplicit: null == isVdrsExplicit ? _self.isVdrsExplicit : isVdrsExplicit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
