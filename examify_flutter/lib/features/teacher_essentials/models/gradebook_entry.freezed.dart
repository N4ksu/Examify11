// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gradebook_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GradebookEntry {

 int get id;@JsonKey(name: 'student_id') String? get studentId; String get name; String? get email; String? get section; Map<String, double?> get scores;// assessment title -> score
@JsonKey(name: 'calculated_grade') double get calculatedGrade;@JsonKey(name: 'outcomes') Map<String, double?>? get outcomes;
/// Create a copy of GradebookEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GradebookEntryCopyWith<GradebookEntry> get copyWith => _$GradebookEntryCopyWithImpl<GradebookEntry>(this as GradebookEntry, _$identity);

  /// Serializes this GradebookEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GradebookEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.section, section) || other.section == section)&&const DeepCollectionEquality().equals(other.scores, scores)&&(identical(other.calculatedGrade, calculatedGrade) || other.calculatedGrade == calculatedGrade)&&const DeepCollectionEquality().equals(other.outcomes, outcomes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,name,email,section,const DeepCollectionEquality().hash(scores),calculatedGrade,const DeepCollectionEquality().hash(outcomes));

@override
String toString() {
  return 'GradebookEntry(id: $id, studentId: $studentId, name: $name, email: $email, section: $section, scores: $scores, calculatedGrade: $calculatedGrade, outcomes: $outcomes)';
}


}

/// @nodoc
abstract mixin class $GradebookEntryCopyWith<$Res>  {
  factory $GradebookEntryCopyWith(GradebookEntry value, $Res Function(GradebookEntry) _then) = _$GradebookEntryCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'student_id') String? studentId, String name, String? email, String? section, Map<String, double?> scores,@JsonKey(name: 'calculated_grade') double calculatedGrade,@JsonKey(name: 'outcomes') Map<String, double?>? outcomes
});




}
/// @nodoc
class _$GradebookEntryCopyWithImpl<$Res>
    implements $GradebookEntryCopyWith<$Res> {
  _$GradebookEntryCopyWithImpl(this._self, this._then);

  final GradebookEntry _self;
  final $Res Function(GradebookEntry) _then;

/// Create a copy of GradebookEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = freezed,Object? name = null,Object? email = freezed,Object? section = freezed,Object? scores = null,Object? calculatedGrade = null,Object? outcomes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,studentId: freezed == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,scores: null == scores ? _self.scores : scores // ignore: cast_nullable_to_non_nullable
as Map<String, double?>,calculatedGrade: null == calculatedGrade ? _self.calculatedGrade : calculatedGrade // ignore: cast_nullable_to_non_nullable
as double,outcomes: freezed == outcomes ? _self.outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<String, double?>?,
  ));
}

}


/// Adds pattern-matching-related methods to [GradebookEntry].
extension GradebookEntryPatterns on GradebookEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GradebookEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GradebookEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GradebookEntry value)  $default,){
final _that = this;
switch (_that) {
case _GradebookEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GradebookEntry value)?  $default,){
final _that = this;
switch (_that) {
case _GradebookEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'student_id')  String? studentId,  String name,  String? email,  String? section,  Map<String, double?> scores, @JsonKey(name: 'calculated_grade')  double calculatedGrade, @JsonKey(name: 'outcomes')  Map<String, double?>? outcomes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GradebookEntry() when $default != null:
return $default(_that.id,_that.studentId,_that.name,_that.email,_that.section,_that.scores,_that.calculatedGrade,_that.outcomes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'student_id')  String? studentId,  String name,  String? email,  String? section,  Map<String, double?> scores, @JsonKey(name: 'calculated_grade')  double calculatedGrade, @JsonKey(name: 'outcomes')  Map<String, double?>? outcomes)  $default,) {final _that = this;
switch (_that) {
case _GradebookEntry():
return $default(_that.id,_that.studentId,_that.name,_that.email,_that.section,_that.scores,_that.calculatedGrade,_that.outcomes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'student_id')  String? studentId,  String name,  String? email,  String? section,  Map<String, double?> scores, @JsonKey(name: 'calculated_grade')  double calculatedGrade, @JsonKey(name: 'outcomes')  Map<String, double?>? outcomes)?  $default,) {final _that = this;
switch (_that) {
case _GradebookEntry() when $default != null:
return $default(_that.id,_that.studentId,_that.name,_that.email,_that.section,_that.scores,_that.calculatedGrade,_that.outcomes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GradebookEntry implements GradebookEntry {
  const _GradebookEntry({required this.id, @JsonKey(name: 'student_id') this.studentId, required this.name, this.email, this.section, required final  Map<String, double?> scores, @JsonKey(name: 'calculated_grade') required this.calculatedGrade, @JsonKey(name: 'outcomes') final  Map<String, double?>? outcomes}): _scores = scores,_outcomes = outcomes;
  factory _GradebookEntry.fromJson(Map<String, dynamic> json) => _$GradebookEntryFromJson(json);

@override final  int id;
@override@JsonKey(name: 'student_id') final  String? studentId;
@override final  String name;
@override final  String? email;
@override final  String? section;
 final  Map<String, double?> _scores;
@override Map<String, double?> get scores {
  if (_scores is EqualUnmodifiableMapView) return _scores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_scores);
}

// assessment title -> score
@override@JsonKey(name: 'calculated_grade') final  double calculatedGrade;
 final  Map<String, double?>? _outcomes;
@override@JsonKey(name: 'outcomes') Map<String, double?>? get outcomes {
  final value = _outcomes;
  if (value == null) return null;
  if (_outcomes is EqualUnmodifiableMapView) return _outcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of GradebookEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GradebookEntryCopyWith<_GradebookEntry> get copyWith => __$GradebookEntryCopyWithImpl<_GradebookEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GradebookEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GradebookEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.section, section) || other.section == section)&&const DeepCollectionEquality().equals(other._scores, _scores)&&(identical(other.calculatedGrade, calculatedGrade) || other.calculatedGrade == calculatedGrade)&&const DeepCollectionEquality().equals(other._outcomes, _outcomes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,name,email,section,const DeepCollectionEquality().hash(_scores),calculatedGrade,const DeepCollectionEquality().hash(_outcomes));

@override
String toString() {
  return 'GradebookEntry(id: $id, studentId: $studentId, name: $name, email: $email, section: $section, scores: $scores, calculatedGrade: $calculatedGrade, outcomes: $outcomes)';
}


}

/// @nodoc
abstract mixin class _$GradebookEntryCopyWith<$Res> implements $GradebookEntryCopyWith<$Res> {
  factory _$GradebookEntryCopyWith(_GradebookEntry value, $Res Function(_GradebookEntry) _then) = __$GradebookEntryCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'student_id') String? studentId, String name, String? email, String? section, Map<String, double?> scores,@JsonKey(name: 'calculated_grade') double calculatedGrade,@JsonKey(name: 'outcomes') Map<String, double?>? outcomes
});




}
/// @nodoc
class __$GradebookEntryCopyWithImpl<$Res>
    implements _$GradebookEntryCopyWith<$Res> {
  __$GradebookEntryCopyWithImpl(this._self, this._then);

  final _GradebookEntry _self;
  final $Res Function(_GradebookEntry) _then;

/// Create a copy of GradebookEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = freezed,Object? name = null,Object? email = freezed,Object? section = freezed,Object? scores = null,Object? calculatedGrade = null,Object? outcomes = freezed,}) {
  return _then(_GradebookEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,studentId: freezed == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,scores: null == scores ? _self._scores : scores // ignore: cast_nullable_to_non_nullable
as Map<String, double?>,calculatedGrade: null == calculatedGrade ? _self.calculatedGrade : calculatedGrade // ignore: cast_nullable_to_non_nullable
as double,outcomes: freezed == outcomes ? _self._outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<String, double?>?,
  ));
}


}

// dart format on
