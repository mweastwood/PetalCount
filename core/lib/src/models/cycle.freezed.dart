// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cycle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Cycle {

@JsonKey(fromJson: _parseCycleIdFromJson) String get id;@JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey) DateTime get startDate;@JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey) DateTime? get endDate;@JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson) List<String> get bipCodes;@JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson) Map<String, DailyEntry> get dailyEntries;
/// Create a copy of Cycle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CycleCopyWith<Cycle> get copyWith => _$CycleCopyWithImpl<Cycle>(this as Cycle, _$identity);

  /// Serializes this Cycle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Cycle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cycle&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&const DeepCollectionEquality().equals(other.bipCodes, _this.bipCodes)&&const DeepCollectionEquality().equals(other.dailyEntries, _this.dailyEntries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Cycle;
  return Object.hash(runtimeType,_this.id,_this.startDate,_this.endDate,const DeepCollectionEquality().hash(_this.bipCodes),const DeepCollectionEquality().hash(_this.dailyEntries));
}

@override
String toString() {
  final _this = this as Cycle;
  return 'Cycle(id: ${_this.id}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, bipCodes: ${_this.bipCodes}, dailyEntries: ${_this.dailyEntries})';
}


}

/// @nodoc
abstract mixin class $CycleCopyWith<$Res>  {
  factory $CycleCopyWith(Cycle value, $Res Function(Cycle) _then) = _$CycleCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _parseCycleIdFromJson) String id,@JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey) DateTime startDate,@JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey) DateTime? endDate,@JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson) List<String> bipCodes,@JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson) Map<String, DailyEntry> dailyEntries
});




}
/// @nodoc
class _$CycleCopyWithImpl<$Res>
    implements $CycleCopyWith<$Res> {
  _$CycleCopyWithImpl(this._self, this._then);

  final Cycle _self;
  final $Res Function(Cycle) _then;

/// Create a copy of Cycle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startDate = null,Object? endDate = freezed,Object? bipCodes = null,Object? dailyEntries = null,}) {
  return _then(Cycle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,bipCodes: null == bipCodes ? _self.bipCodes : bipCodes // ignore: cast_nullable_to_non_nullable
as List<String>,dailyEntries: null == dailyEntries ? _self.dailyEntries : dailyEntries // ignore: cast_nullable_to_non_nullable
as Map<String, DailyEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [Cycle].
extension CyclePatterns on Cycle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Cycle value)?  raw,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Cycle() when raw != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Cycle value)  raw,}){
final _that = this;
switch (_that) {
case _Cycle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Cycle value)?  raw,}){
final _that = this;
switch (_that) {
case _Cycle() when raw != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(fromJson: _parseCycleIdFromJson)  String id, @JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey)  DateTime startDate, @JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey)  DateTime? endDate, @JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson)  List<String> bipCodes, @JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson)  Map<String, DailyEntry> dailyEntries)?  raw,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Cycle() when raw != null:
return raw(_that.id,_that.startDate,_that.endDate,_that.bipCodes,_that.dailyEntries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(fromJson: _parseCycleIdFromJson)  String id, @JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey)  DateTime startDate, @JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey)  DateTime? endDate, @JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson)  List<String> bipCodes, @JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson)  Map<String, DailyEntry> dailyEntries)  raw,}) {final _that = this;
switch (_that) {
case _Cycle():
return raw(_that.id,_that.startDate,_that.endDate,_that.bipCodes,_that.dailyEntries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(fromJson: _parseCycleIdFromJson)  String id, @JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey)  DateTime startDate, @JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey)  DateTime? endDate, @JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson)  List<String> bipCodes, @JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson)  Map<String, DailyEntry> dailyEntries)?  raw,}) {final _that = this;
switch (_that) {
case _Cycle() when raw != null:
return raw(_that.id,_that.startDate,_that.endDate,_that.bipCodes,_that.dailyEntries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Cycle extends Cycle {
  const _Cycle({@JsonKey(fromJson: _parseCycleIdFromJson) this.id = '', @JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey) required this.startDate, @JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey) this.endDate, @JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson)  List<String> bipCodes = const <String>[], @JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson)  Map<String, DailyEntry> dailyEntries = const <String, DailyEntry>{}}): _bipCodes = bipCodes,_dailyEntries = dailyEntries,super._();
  factory _Cycle.fromJson(Map<String, dynamic> json) => _$CycleFromJson(json);

@override@JsonKey(fromJson: _parseCycleIdFromJson) final  String id;
@override@JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey) final  DateTime startDate;
@override@JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey) final  DateTime? endDate;
 final  List<String> _bipCodes;
@override@JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson) List<String> get bipCodes {
  if (_bipCodes is EqualUnmodifiableListView) return _bipCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bipCodes);
}

 final  Map<String, DailyEntry> _dailyEntries;
@override@JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson) Map<String, DailyEntry> get dailyEntries {
  if (_dailyEntries is EqualUnmodifiableMapView) return _dailyEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dailyEntries);
}


/// Create a copy of Cycle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CycleCopyWith<_Cycle> get copyWith => __$CycleCopyWithImpl<_Cycle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CycleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cycle&&(identical(other.id, id) || other.id == id)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.bipCodes, _bipCodes)&&const DeepCollectionEquality().equals(other.dailyEntries, _dailyEntries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,startDate,endDate,const DeepCollectionEquality().hash(_bipCodes),const DeepCollectionEquality().hash(_dailyEntries));
}

@override
String toString() {
    return 'Cycle.raw(id: $id, startDate: $startDate, endDate: $endDate, bipCodes: $bipCodes, dailyEntries: $dailyEntries)';
}


}

/// @nodoc
abstract mixin class _$CycleCopyWith<$Res> implements $CycleCopyWith<$Res> {
  factory _$CycleCopyWith(_Cycle value, $Res Function(_Cycle) _then) = __$CycleCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _parseCycleIdFromJson) String id,@JsonKey(fromJson: _parseCycleStartDateFromJson, toJson: _serializeCycleDateToDateKey) DateTime startDate,@JsonKey(fromJson: _parseCycleEndDateFromJson, toJson: _serializeCycleEndDateToDateKey) DateTime? endDate,@JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson) List<String> bipCodes,@JsonKey(fromJson: _parseDailyEntriesFromJson, toJson: _serializeDailyEntriesToJson) Map<String, DailyEntry> dailyEntries
});




}
/// @nodoc
class __$CycleCopyWithImpl<$Res>
    implements _$CycleCopyWith<$Res> {
  __$CycleCopyWithImpl(this._self, this._then);

  final _Cycle _self;
  final $Res Function(_Cycle) _then;

/// Create a copy of Cycle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startDate = null,Object? endDate = freezed,Object? bipCodes = null,Object? dailyEntries = null,}) {
  return _then(_Cycle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,bipCodes: null == bipCodes ? _self._bipCodes : bipCodes // ignore: cast_nullable_to_non_nullable
as List<String>,dailyEntries: null == dailyEntries ? _self._dailyEntries : dailyEntries // ignore: cast_nullable_to_non_nullable
as Map<String, DailyEntry>,
  ));
}


}

// dart format on
