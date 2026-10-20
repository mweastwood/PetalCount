// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationPreferences {

@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool get fertilePatternAlerts;@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool get partnerSupportReminders;@JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue) bool get dailyLoggingReminder;@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool get breastSelfExamReminder;
/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferencesCopyWith<NotificationPreferences> get copyWith => _$NotificationPreferencesCopyWithImpl<NotificationPreferences>(this as NotificationPreferences, _$identity);

  /// Serializes this NotificationPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationPreferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreferences&&(identical(other.fertilePatternAlerts, _this.fertilePatternAlerts) || other.fertilePatternAlerts == _this.fertilePatternAlerts)&&(identical(other.partnerSupportReminders, _this.partnerSupportReminders) || other.partnerSupportReminders == _this.partnerSupportReminders)&&(identical(other.dailyLoggingReminder, _this.dailyLoggingReminder) || other.dailyLoggingReminder == _this.dailyLoggingReminder)&&(identical(other.breastSelfExamReminder, _this.breastSelfExamReminder) || other.breastSelfExamReminder == _this.breastSelfExamReminder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationPreferences;
  return Object.hash(runtimeType,_this.fertilePatternAlerts,_this.partnerSupportReminders,_this.dailyLoggingReminder,_this.breastSelfExamReminder);
}

@override
String toString() {
  final _this = this as NotificationPreferences;
  return 'NotificationPreferences(fertilePatternAlerts: ${_this.fertilePatternAlerts}, partnerSupportReminders: ${_this.partnerSupportReminders}, dailyLoggingReminder: ${_this.dailyLoggingReminder}, breastSelfExamReminder: ${_this.breastSelfExamReminder})';
}


}

/// @nodoc
abstract mixin class $NotificationPreferencesCopyWith<$Res>  {
  factory $NotificationPreferencesCopyWith(NotificationPreferences value, $Res Function(NotificationPreferences) _then) = _$NotificationPreferencesCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool fertilePatternAlerts,@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool partnerSupportReminders,@JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue) bool dailyLoggingReminder,@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool breastSelfExamReminder
});




}
/// @nodoc
class _$NotificationPreferencesCopyWithImpl<$Res>
    implements $NotificationPreferencesCopyWith<$Res> {
  _$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final NotificationPreferences _self;
  final $Res Function(NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fertilePatternAlerts = null,Object? partnerSupportReminders = null,Object? dailyLoggingReminder = null,Object? breastSelfExamReminder = null,}) {
  return _then(NotificationPreferences(
fertilePatternAlerts: null == fertilePatternAlerts ? _self.fertilePatternAlerts : fertilePatternAlerts // ignore: cast_nullable_to_non_nullable
as bool,partnerSupportReminders: null == partnerSupportReminders ? _self.partnerSupportReminders : partnerSupportReminders // ignore: cast_nullable_to_non_nullable
as bool,dailyLoggingReminder: null == dailyLoggingReminder ? _self.dailyLoggingReminder : dailyLoggingReminder // ignore: cast_nullable_to_non_nullable
as bool,breastSelfExamReminder: null == breastSelfExamReminder ? _self.breastSelfExamReminder : breastSelfExamReminder // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreferences].
extension NotificationPreferencesPatterns on NotificationPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreferences value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool fertilePatternAlerts, @JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool partnerSupportReminders, @JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue)  bool dailyLoggingReminder, @JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool breastSelfExamReminder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.fertilePatternAlerts,_that.partnerSupportReminders,_that.dailyLoggingReminder,_that.breastSelfExamReminder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool fertilePatternAlerts, @JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool partnerSupportReminders, @JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue)  bool dailyLoggingReminder, @JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool breastSelfExamReminder)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences():
return $default(_that.fertilePatternAlerts,_that.partnerSupportReminders,_that.dailyLoggingReminder,_that.breastSelfExamReminder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool fertilePatternAlerts, @JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool partnerSupportReminders, @JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue)  bool dailyLoggingReminder, @JsonKey(fromJson: _parseBooleanWithDefaultTrue)  bool breastSelfExamReminder)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.fertilePatternAlerts,_that.partnerSupportReminders,_that.dailyLoggingReminder,_that.breastSelfExamReminder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPreferences extends NotificationPreferences {
  const _NotificationPreferences({@JsonKey(fromJson: _parseBooleanWithDefaultTrue) this.fertilePatternAlerts = true, @JsonKey(fromJson: _parseBooleanWithDefaultTrue) this.partnerSupportReminders = true, @JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue) this.dailyLoggingReminder = true, @JsonKey(fromJson: _parseBooleanWithDefaultTrue) this.breastSelfExamReminder = true}): super._();
  factory _NotificationPreferences.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesFromJson(json);

@override@JsonKey(fromJson: _parseBooleanWithDefaultTrue) final  bool fertilePatternAlerts;
@override@JsonKey(fromJson: _parseBooleanWithDefaultTrue) final  bool partnerSupportReminders;
@override@JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue) final  bool dailyLoggingReminder;
@override@JsonKey(fromJson: _parseBooleanWithDefaultTrue) final  bool breastSelfExamReminder;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferencesCopyWith<_NotificationPreferences> get copyWith => __$NotificationPreferencesCopyWithImpl<_NotificationPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreferences&&(identical(other.fertilePatternAlerts, fertilePatternAlerts) || other.fertilePatternAlerts == fertilePatternAlerts)&&(identical(other.partnerSupportReminders, partnerSupportReminders) || other.partnerSupportReminders == partnerSupportReminders)&&(identical(other.dailyLoggingReminder, dailyLoggingReminder) || other.dailyLoggingReminder == dailyLoggingReminder)&&(identical(other.breastSelfExamReminder, breastSelfExamReminder) || other.breastSelfExamReminder == breastSelfExamReminder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fertilePatternAlerts,partnerSupportReminders,dailyLoggingReminder,breastSelfExamReminder);
}

@override
String toString() {
    return 'NotificationPreferences(fertilePatternAlerts: $fertilePatternAlerts, partnerSupportReminders: $partnerSupportReminders, dailyLoggingReminder: $dailyLoggingReminder, breastSelfExamReminder: $breastSelfExamReminder)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferencesCopyWith<$Res> implements $NotificationPreferencesCopyWith<$Res> {
  factory _$NotificationPreferencesCopyWith(_NotificationPreferences value, $Res Function(_NotificationPreferences) _then) = __$NotificationPreferencesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool fertilePatternAlerts,@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool partnerSupportReminders,@JsonKey(readValue: _readDailyLoggingReminderValue, fromJson: _parseBooleanWithDefaultTrue) bool dailyLoggingReminder,@JsonKey(fromJson: _parseBooleanWithDefaultTrue) bool breastSelfExamReminder
});




}
/// @nodoc
class __$NotificationPreferencesCopyWithImpl<$Res>
    implements _$NotificationPreferencesCopyWith<$Res> {
  __$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final _NotificationPreferences _self;
  final $Res Function(_NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fertilePatternAlerts = null,Object? partnerSupportReminders = null,Object? dailyLoggingReminder = null,Object? breastSelfExamReminder = null,}) {
  return _then(_NotificationPreferences(
fertilePatternAlerts: null == fertilePatternAlerts ? _self.fertilePatternAlerts : fertilePatternAlerts // ignore: cast_nullable_to_non_nullable
as bool,partnerSupportReminders: null == partnerSupportReminders ? _self.partnerSupportReminders : partnerSupportReminders // ignore: cast_nullable_to_non_nullable
as bool,dailyLoggingReminder: null == dailyLoggingReminder ? _self.dailyLoggingReminder : dailyLoggingReminder // ignore: cast_nullable_to_non_nullable
as bool,breastSelfExamReminder: null == breastSelfExamReminder ? _self.breastSelfExamReminder : breastSelfExamReminder // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
