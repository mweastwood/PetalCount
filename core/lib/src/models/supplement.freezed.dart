// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'supplement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupplementItem {

@JsonKey(fromJson: _parseSupplementStringFromJson) String get id;@JsonKey(fromJson: _parseSupplementStringFromJson) String get name;@JsonKey(fromJson: _parseSupplementStringFromJson) String get quantity;@JsonKey(fromJson: _parseSupplementBoolFalseFromJson) bool get takeWithFood;@JsonKey(fromJson: _parseSupplementDoseFromJson) int get morningDose;@JsonKey(fromJson: _parseSupplementDoseFromJson) int get afternoonDose;@JsonKey(fromJson: _parseSupplementDoseFromJson) int get eveningDose;@JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson) SupplementScheduleRuleType get ruleType;@JsonKey(fromJson: _parseNullableIntFromJson) int? get startCycleDay;@JsonKey(fromJson: _parseNullableIntFromJson) int? get endCycleDay;@JsonKey(fromJson: _parseNullableIntFromJson) int? get startPeakOffset;@JsonKey(fromJson: _parseNullableIntFromJson) int? get endPeakOffset;@JsonKey(fromJson: _parseNullableIntFromJson) int? get durationDays;@JsonKey(fromJson: _parseSupplementStringFromJson) String get instructions;@JsonKey(fromJson: _parseSupplementBoolTrueFromJson) bool get isActive;@JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson) UserRole get targetRole;
/// Create a copy of SupplementItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupplementItemCopyWith<SupplementItem> get copyWith => _$SupplementItemCopyWithImpl<SupplementItem>(this as SupplementItem, _$identity);

  /// Serializes this SupplementItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SupplementItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupplementItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.takeWithFood, _this.takeWithFood) || other.takeWithFood == _this.takeWithFood)&&(identical(other.morningDose, _this.morningDose) || other.morningDose == _this.morningDose)&&(identical(other.afternoonDose, _this.afternoonDose) || other.afternoonDose == _this.afternoonDose)&&(identical(other.eveningDose, _this.eveningDose) || other.eveningDose == _this.eveningDose)&&(identical(other.ruleType, _this.ruleType) || other.ruleType == _this.ruleType)&&(identical(other.startCycleDay, _this.startCycleDay) || other.startCycleDay == _this.startCycleDay)&&(identical(other.endCycleDay, _this.endCycleDay) || other.endCycleDay == _this.endCycleDay)&&(identical(other.startPeakOffset, _this.startPeakOffset) || other.startPeakOffset == _this.startPeakOffset)&&(identical(other.endPeakOffset, _this.endPeakOffset) || other.endPeakOffset == _this.endPeakOffset)&&(identical(other.durationDays, _this.durationDays) || other.durationDays == _this.durationDays)&&(identical(other.instructions, _this.instructions) || other.instructions == _this.instructions)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.targetRole, _this.targetRole) || other.targetRole == _this.targetRole));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupplementItem;
  return Object.hash(runtimeType,_this.id,_this.name,_this.quantity,_this.takeWithFood,_this.morningDose,_this.afternoonDose,_this.eveningDose,_this.ruleType,_this.startCycleDay,_this.endCycleDay,_this.startPeakOffset,_this.endPeakOffset,_this.durationDays,_this.instructions,_this.isActive,_this.targetRole);
}

@override
String toString() {
  final _this = this as SupplementItem;
  return 'SupplementItem(id: ${_this.id}, name: ${_this.name}, quantity: ${_this.quantity}, takeWithFood: ${_this.takeWithFood}, morningDose: ${_this.morningDose}, afternoonDose: ${_this.afternoonDose}, eveningDose: ${_this.eveningDose}, ruleType: ${_this.ruleType}, startCycleDay: ${_this.startCycleDay}, endCycleDay: ${_this.endCycleDay}, startPeakOffset: ${_this.startPeakOffset}, endPeakOffset: ${_this.endPeakOffset}, durationDays: ${_this.durationDays}, instructions: ${_this.instructions}, isActive: ${_this.isActive}, targetRole: ${_this.targetRole})';
}


}

/// @nodoc
abstract mixin class $SupplementItemCopyWith<$Res>  {
  factory $SupplementItemCopyWith(SupplementItem value, $Res Function(SupplementItem) _then) = _$SupplementItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _parseSupplementStringFromJson) String id,@JsonKey(fromJson: _parseSupplementStringFromJson) String name,@JsonKey(fromJson: _parseSupplementStringFromJson) String quantity,@JsonKey(fromJson: _parseSupplementBoolFalseFromJson) bool takeWithFood,@JsonKey(fromJson: _parseSupplementDoseFromJson) int morningDose,@JsonKey(fromJson: _parseSupplementDoseFromJson) int afternoonDose,@JsonKey(fromJson: _parseSupplementDoseFromJson) int eveningDose,@JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson) SupplementScheduleRuleType ruleType,@JsonKey(fromJson: _parseNullableIntFromJson) int? startCycleDay,@JsonKey(fromJson: _parseNullableIntFromJson) int? endCycleDay,@JsonKey(fromJson: _parseNullableIntFromJson) int? startPeakOffset,@JsonKey(fromJson: _parseNullableIntFromJson) int? endPeakOffset,@JsonKey(fromJson: _parseNullableIntFromJson) int? durationDays,@JsonKey(fromJson: _parseSupplementStringFromJson) String instructions,@JsonKey(fromJson: _parseSupplementBoolTrueFromJson) bool isActive,@JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson) UserRole targetRole
});




}
/// @nodoc
class _$SupplementItemCopyWithImpl<$Res>
    implements $SupplementItemCopyWith<$Res> {
  _$SupplementItemCopyWithImpl(this._self, this._then);

  final SupplementItem _self;
  final $Res Function(SupplementItem) _then;

/// Create a copy of SupplementItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? quantity = null,Object? takeWithFood = null,Object? morningDose = null,Object? afternoonDose = null,Object? eveningDose = null,Object? ruleType = null,Object? startCycleDay = freezed,Object? endCycleDay = freezed,Object? startPeakOffset = freezed,Object? endPeakOffset = freezed,Object? durationDays = freezed,Object? instructions = null,Object? isActive = null,Object? targetRole = null,}) {
  return _then(SupplementItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,takeWithFood: null == takeWithFood ? _self.takeWithFood : takeWithFood // ignore: cast_nullable_to_non_nullable
as bool,morningDose: null == morningDose ? _self.morningDose : morningDose // ignore: cast_nullable_to_non_nullable
as int,afternoonDose: null == afternoonDose ? _self.afternoonDose : afternoonDose // ignore: cast_nullable_to_non_nullable
as int,eveningDose: null == eveningDose ? _self.eveningDose : eveningDose // ignore: cast_nullable_to_non_nullable
as int,ruleType: null == ruleType ? _self.ruleType : ruleType // ignore: cast_nullable_to_non_nullable
as SupplementScheduleRuleType,startCycleDay: freezed == startCycleDay ? _self.startCycleDay : startCycleDay // ignore: cast_nullable_to_non_nullable
as int?,endCycleDay: freezed == endCycleDay ? _self.endCycleDay : endCycleDay // ignore: cast_nullable_to_non_nullable
as int?,startPeakOffset: freezed == startPeakOffset ? _self.startPeakOffset : startPeakOffset // ignore: cast_nullable_to_non_nullable
as int?,endPeakOffset: freezed == endPeakOffset ? _self.endPeakOffset : endPeakOffset // ignore: cast_nullable_to_non_nullable
as int?,durationDays: freezed == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int?,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,targetRole: null == targetRole ? _self.targetRole : targetRole // ignore: cast_nullable_to_non_nullable
as UserRole,
  ));
}

}


/// Adds pattern-matching-related methods to [SupplementItem].
extension SupplementItemPatterns on SupplementItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupplementItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupplementItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupplementItem value)  $default,){
final _that = this;
switch (_that) {
case _SupplementItem():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupplementItem value)?  $default,){
final _that = this;
switch (_that) {
case _SupplementItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _parseSupplementStringFromJson)  String id, @JsonKey(fromJson: _parseSupplementStringFromJson)  String name, @JsonKey(fromJson: _parseSupplementStringFromJson)  String quantity, @JsonKey(fromJson: _parseSupplementBoolFalseFromJson)  bool takeWithFood, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int morningDose, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int afternoonDose, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int eveningDose, @JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson)  SupplementScheduleRuleType ruleType, @JsonKey(fromJson: _parseNullableIntFromJson)  int? startCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson)  int? endCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson)  int? startPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson)  int? endPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson)  int? durationDays, @JsonKey(fromJson: _parseSupplementStringFromJson)  String instructions, @JsonKey(fromJson: _parseSupplementBoolTrueFromJson)  bool isActive, @JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson)  UserRole targetRole)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupplementItem() when $default != null:
return $default(_that.id,_that.name,_that.quantity,_that.takeWithFood,_that.morningDose,_that.afternoonDose,_that.eveningDose,_that.ruleType,_that.startCycleDay,_that.endCycleDay,_that.startPeakOffset,_that.endPeakOffset,_that.durationDays,_that.instructions,_that.isActive,_that.targetRole);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _parseSupplementStringFromJson)  String id, @JsonKey(fromJson: _parseSupplementStringFromJson)  String name, @JsonKey(fromJson: _parseSupplementStringFromJson)  String quantity, @JsonKey(fromJson: _parseSupplementBoolFalseFromJson)  bool takeWithFood, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int morningDose, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int afternoonDose, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int eveningDose, @JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson)  SupplementScheduleRuleType ruleType, @JsonKey(fromJson: _parseNullableIntFromJson)  int? startCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson)  int? endCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson)  int? startPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson)  int? endPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson)  int? durationDays, @JsonKey(fromJson: _parseSupplementStringFromJson)  String instructions, @JsonKey(fromJson: _parseSupplementBoolTrueFromJson)  bool isActive, @JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson)  UserRole targetRole)  $default,) {final _that = this;
switch (_that) {
case _SupplementItem():
return $default(_that.id,_that.name,_that.quantity,_that.takeWithFood,_that.morningDose,_that.afternoonDose,_that.eveningDose,_that.ruleType,_that.startCycleDay,_that.endCycleDay,_that.startPeakOffset,_that.endPeakOffset,_that.durationDays,_that.instructions,_that.isActive,_that.targetRole);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _parseSupplementStringFromJson)  String id, @JsonKey(fromJson: _parseSupplementStringFromJson)  String name, @JsonKey(fromJson: _parseSupplementStringFromJson)  String quantity, @JsonKey(fromJson: _parseSupplementBoolFalseFromJson)  bool takeWithFood, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int morningDose, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int afternoonDose, @JsonKey(fromJson: _parseSupplementDoseFromJson)  int eveningDose, @JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson)  SupplementScheduleRuleType ruleType, @JsonKey(fromJson: _parseNullableIntFromJson)  int? startCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson)  int? endCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson)  int? startPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson)  int? endPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson)  int? durationDays, @JsonKey(fromJson: _parseSupplementStringFromJson)  String instructions, @JsonKey(fromJson: _parseSupplementBoolTrueFromJson)  bool isActive, @JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson)  UserRole targetRole)?  $default,) {final _that = this;
switch (_that) {
case _SupplementItem() when $default != null:
return $default(_that.id,_that.name,_that.quantity,_that.takeWithFood,_that.morningDose,_that.afternoonDose,_that.eveningDose,_that.ruleType,_that.startCycleDay,_that.endCycleDay,_that.startPeakOffset,_that.endPeakOffset,_that.durationDays,_that.instructions,_that.isActive,_that.targetRole);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupplementItem extends SupplementItem {
  const _SupplementItem({@JsonKey(fromJson: _parseSupplementStringFromJson) this.id = '', @JsonKey(fromJson: _parseSupplementStringFromJson) this.name = '', @JsonKey(fromJson: _parseSupplementStringFromJson) this.quantity = '', @JsonKey(fromJson: _parseSupplementBoolFalseFromJson) this.takeWithFood = false, @JsonKey(fromJson: _parseSupplementDoseFromJson) this.morningDose = 0, @JsonKey(fromJson: _parseSupplementDoseFromJson) this.afternoonDose = 0, @JsonKey(fromJson: _parseSupplementDoseFromJson) this.eveningDose = 0, @JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson) this.ruleType = SupplementScheduleRuleType.allDays, @JsonKey(fromJson: _parseNullableIntFromJson) this.startCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson) this.endCycleDay, @JsonKey(fromJson: _parseNullableIntFromJson) this.startPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson) this.endPeakOffset, @JsonKey(fromJson: _parseNullableIntFromJson) this.durationDays, @JsonKey(fromJson: _parseSupplementStringFromJson) this.instructions = '', @JsonKey(fromJson: _parseSupplementBoolTrueFromJson) this.isActive = true, @JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson) this.targetRole = UserRole.wife}): super._();
  factory _SupplementItem.fromJson(Map<String, dynamic> json) => _$SupplementItemFromJson(json);

@override@JsonKey(fromJson: _parseSupplementStringFromJson) final  String id;
@override@JsonKey(fromJson: _parseSupplementStringFromJson) final  String name;
@override@JsonKey(fromJson: _parseSupplementStringFromJson) final  String quantity;
@override@JsonKey(fromJson: _parseSupplementBoolFalseFromJson) final  bool takeWithFood;
@override@JsonKey(fromJson: _parseSupplementDoseFromJson) final  int morningDose;
@override@JsonKey(fromJson: _parseSupplementDoseFromJson) final  int afternoonDose;
@override@JsonKey(fromJson: _parseSupplementDoseFromJson) final  int eveningDose;
@override@JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson) final  SupplementScheduleRuleType ruleType;
@override@JsonKey(fromJson: _parseNullableIntFromJson) final  int? startCycleDay;
@override@JsonKey(fromJson: _parseNullableIntFromJson) final  int? endCycleDay;
@override@JsonKey(fromJson: _parseNullableIntFromJson) final  int? startPeakOffset;
@override@JsonKey(fromJson: _parseNullableIntFromJson) final  int? endPeakOffset;
@override@JsonKey(fromJson: _parseNullableIntFromJson) final  int? durationDays;
@override@JsonKey(fromJson: _parseSupplementStringFromJson) final  String instructions;
@override@JsonKey(fromJson: _parseSupplementBoolTrueFromJson) final  bool isActive;
@override@JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson) final  UserRole targetRole;

/// Create a copy of SupplementItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupplementItemCopyWith<_SupplementItem> get copyWith => __$SupplementItemCopyWithImpl<_SupplementItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupplementItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupplementItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.takeWithFood, takeWithFood) || other.takeWithFood == takeWithFood)&&(identical(other.morningDose, morningDose) || other.morningDose == morningDose)&&(identical(other.afternoonDose, afternoonDose) || other.afternoonDose == afternoonDose)&&(identical(other.eveningDose, eveningDose) || other.eveningDose == eveningDose)&&(identical(other.ruleType, ruleType) || other.ruleType == ruleType)&&(identical(other.startCycleDay, startCycleDay) || other.startCycleDay == startCycleDay)&&(identical(other.endCycleDay, endCycleDay) || other.endCycleDay == endCycleDay)&&(identical(other.startPeakOffset, startPeakOffset) || other.startPeakOffset == startPeakOffset)&&(identical(other.endPeakOffset, endPeakOffset) || other.endPeakOffset == endPeakOffset)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.targetRole, targetRole) || other.targetRole == targetRole));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,quantity,takeWithFood,morningDose,afternoonDose,eveningDose,ruleType,startCycleDay,endCycleDay,startPeakOffset,endPeakOffset,durationDays,instructions,isActive,targetRole);
}

@override
String toString() {
    return 'SupplementItem(id: $id, name: $name, quantity: $quantity, takeWithFood: $takeWithFood, morningDose: $morningDose, afternoonDose: $afternoonDose, eveningDose: $eveningDose, ruleType: $ruleType, startCycleDay: $startCycleDay, endCycleDay: $endCycleDay, startPeakOffset: $startPeakOffset, endPeakOffset: $endPeakOffset, durationDays: $durationDays, instructions: $instructions, isActive: $isActive, targetRole: $targetRole)';
}


}

/// @nodoc
abstract mixin class _$SupplementItemCopyWith<$Res> implements $SupplementItemCopyWith<$Res> {
  factory _$SupplementItemCopyWith(_SupplementItem value, $Res Function(_SupplementItem) _then) = __$SupplementItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _parseSupplementStringFromJson) String id,@JsonKey(fromJson: _parseSupplementStringFromJson) String name,@JsonKey(fromJson: _parseSupplementStringFromJson) String quantity,@JsonKey(fromJson: _parseSupplementBoolFalseFromJson) bool takeWithFood,@JsonKey(fromJson: _parseSupplementDoseFromJson) int morningDose,@JsonKey(fromJson: _parseSupplementDoseFromJson) int afternoonDose,@JsonKey(fromJson: _parseSupplementDoseFromJson) int eveningDose,@JsonKey(fromJson: _parseRuleTypeFromJson, toJson: _serializeRuleTypeToJson) SupplementScheduleRuleType ruleType,@JsonKey(fromJson: _parseNullableIntFromJson) int? startCycleDay,@JsonKey(fromJson: _parseNullableIntFromJson) int? endCycleDay,@JsonKey(fromJson: _parseNullableIntFromJson) int? startPeakOffset,@JsonKey(fromJson: _parseNullableIntFromJson) int? endPeakOffset,@JsonKey(fromJson: _parseNullableIntFromJson) int? durationDays,@JsonKey(fromJson: _parseSupplementStringFromJson) String instructions,@JsonKey(fromJson: _parseSupplementBoolTrueFromJson) bool isActive,@JsonKey(fromJson: _parseTargetRoleFromJson, toJson: _serializeTargetRoleToJson) UserRole targetRole
});




}
/// @nodoc
class __$SupplementItemCopyWithImpl<$Res>
    implements _$SupplementItemCopyWith<$Res> {
  __$SupplementItemCopyWithImpl(this._self, this._then);

  final _SupplementItem _self;
  final $Res Function(_SupplementItem) _then;

/// Create a copy of SupplementItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? quantity = null,Object? takeWithFood = null,Object? morningDose = null,Object? afternoonDose = null,Object? eveningDose = null,Object? ruleType = null,Object? startCycleDay = freezed,Object? endCycleDay = freezed,Object? startPeakOffset = freezed,Object? endPeakOffset = freezed,Object? durationDays = freezed,Object? instructions = null,Object? isActive = null,Object? targetRole = null,}) {
  return _then(_SupplementItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,takeWithFood: null == takeWithFood ? _self.takeWithFood : takeWithFood // ignore: cast_nullable_to_non_nullable
as bool,morningDose: null == morningDose ? _self.morningDose : morningDose // ignore: cast_nullable_to_non_nullable
as int,afternoonDose: null == afternoonDose ? _self.afternoonDose : afternoonDose // ignore: cast_nullable_to_non_nullable
as int,eveningDose: null == eveningDose ? _self.eveningDose : eveningDose // ignore: cast_nullable_to_non_nullable
as int,ruleType: null == ruleType ? _self.ruleType : ruleType // ignore: cast_nullable_to_non_nullable
as SupplementScheduleRuleType,startCycleDay: freezed == startCycleDay ? _self.startCycleDay : startCycleDay // ignore: cast_nullable_to_non_nullable
as int?,endCycleDay: freezed == endCycleDay ? _self.endCycleDay : endCycleDay // ignore: cast_nullable_to_non_nullable
as int?,startPeakOffset: freezed == startPeakOffset ? _self.startPeakOffset : startPeakOffset // ignore: cast_nullable_to_non_nullable
as int?,endPeakOffset: freezed == endPeakOffset ? _self.endPeakOffset : endPeakOffset // ignore: cast_nullable_to_non_nullable
as int?,durationDays: freezed == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int?,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,targetRole: null == targetRole ? _self.targetRole : targetRole // ignore: cast_nullable_to_non_nullable
as UserRole,
  ));
}


}


/// @nodoc
mixin _$DailySupplementLog {

@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey) DateTime get date;@JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson) Map<String, List<SupplementTimeOfDay>> get takenDoses;
/// Create a copy of DailySupplementLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailySupplementLogCopyWith<DailySupplementLog> get copyWith => _$DailySupplementLogCopyWithImpl<DailySupplementLog>(this as DailySupplementLog, _$identity);

  /// Serializes this DailySupplementLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DailySupplementLog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailySupplementLog&&(identical(other.date, _this.date) || other.date == _this.date)&&const DeepCollectionEquality().equals(other.takenDoses, _this.takenDoses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DailySupplementLog;
  return Object.hash(runtimeType,_this.date,const DeepCollectionEquality().hash(_this.takenDoses));
}

@override
String toString() {
  final _this = this as DailySupplementLog;
  return 'DailySupplementLog(date: ${_this.date}, takenDoses: ${_this.takenDoses})';
}


}

/// @nodoc
abstract mixin class $DailySupplementLogCopyWith<$Res>  {
  factory $DailySupplementLogCopyWith(DailySupplementLog value, $Res Function(DailySupplementLog) _then) = _$DailySupplementLogCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey) DateTime date,@JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson) Map<String, List<SupplementTimeOfDay>> takenDoses
});




}
/// @nodoc
class _$DailySupplementLogCopyWithImpl<$Res>
    implements $DailySupplementLogCopyWith<$Res> {
  _$DailySupplementLogCopyWithImpl(this._self, this._then);

  final DailySupplementLog _self;
  final $Res Function(DailySupplementLog) _then;

/// Create a copy of DailySupplementLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? takenDoses = null,}) {
  return _then(DailySupplementLog(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,takenDoses: null == takenDoses ? _self.takenDoses : takenDoses // ignore: cast_nullable_to_non_nullable
as Map<String, List<SupplementTimeOfDay>>,
  ));
}

}


/// Adds pattern-matching-related methods to [DailySupplementLog].
extension DailySupplementLogPatterns on DailySupplementLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _DailySupplementLog value)?  raw,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailySupplementLog() when raw != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _DailySupplementLog value)  raw,}){
final _that = this;
switch (_that) {
case _DailySupplementLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _DailySupplementLog value)?  raw,}){
final _that = this;
switch (_that) {
case _DailySupplementLog() when raw != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey)  DateTime date, @JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson)  Map<String, List<SupplementTimeOfDay>> takenDoses)?  raw,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailySupplementLog() when raw != null:
return raw(_that.date,_that.takenDoses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey)  DateTime date, @JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson)  Map<String, List<SupplementTimeOfDay>> takenDoses)  raw,}) {final _that = this;
switch (_that) {
case _DailySupplementLog():
return raw(_that.date,_that.takenDoses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey)  DateTime date, @JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson)  Map<String, List<SupplementTimeOfDay>> takenDoses)?  raw,}) {final _that = this;
switch (_that) {
case _DailySupplementLog() when raw != null:
return raw(_that.date,_that.takenDoses);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailySupplementLog extends DailySupplementLog {
  const _DailySupplementLog({@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey) required this.date, @JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson)  Map<String, List<SupplementTimeOfDay>> takenDoses = const <String, List<SupplementTimeOfDay>>{}}): _takenDoses = takenDoses,super._();
  factory _DailySupplementLog.fromJson(Map<String, dynamic> json) => _$DailySupplementLogFromJson(json);

@override@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey) final  DateTime date;
 final  Map<String, List<SupplementTimeOfDay>> _takenDoses;
@override@JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson) Map<String, List<SupplementTimeOfDay>> get takenDoses {
  if (_takenDoses is EqualUnmodifiableMapView) return _takenDoses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_takenDoses);
}


/// Create a copy of DailySupplementLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailySupplementLogCopyWith<_DailySupplementLog> get copyWith => __$DailySupplementLogCopyWithImpl<_DailySupplementLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailySupplementLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailySupplementLog&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.takenDoses, _takenDoses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_takenDoses));
}

@override
String toString() {
    return 'DailySupplementLog.raw(date: $date, takenDoses: $takenDoses)';
}


}

/// @nodoc
abstract mixin class _$DailySupplementLogCopyWith<$Res> implements $DailySupplementLogCopyWith<$Res> {
  factory _$DailySupplementLogCopyWith(_DailySupplementLog value, $Res Function(_DailySupplementLog) _then) = __$DailySupplementLogCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _parseSupplementLogDateFromJson, toJson: _serializeSupplementLogDateToDateKey) DateTime date,@JsonKey(fromJson: _parseTakenDosesFromJson, toJson: _serializeTakenDosesToJson) Map<String, List<SupplementTimeOfDay>> takenDoses
});




}
/// @nodoc
class __$DailySupplementLogCopyWithImpl<$Res>
    implements _$DailySupplementLogCopyWith<$Res> {
  __$DailySupplementLogCopyWithImpl(this._self, this._then);

  final _DailySupplementLog _self;
  final $Res Function(_DailySupplementLog) _then;

/// Create a copy of DailySupplementLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? takenDoses = null,}) {
  return _then(_DailySupplementLog(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,takenDoses: null == takenDoses ? _self._takenDoses : takenDoses // ignore: cast_nullable_to_non_nullable
as Map<String, List<SupplementTimeOfDay>>,
  ));
}


}

// dart format on
