// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assessment_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssessmentTemplate {

 String get id; String get title; String get description; String get type;@JsonKey(name: 'time_limit_minutes') int get timeLimitMinutes; int get weight; List<TemplateQuestion> get questions;
/// Create a copy of AssessmentTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssessmentTemplateCopyWith<AssessmentTemplate> get copyWith => _$AssessmentTemplateCopyWithImpl<AssessmentTemplate>(this as AssessmentTemplate, _$identity);

  /// Serializes this AssessmentTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssessmentTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.timeLimitMinutes, timeLimitMinutes) || other.timeLimitMinutes == timeLimitMinutes)&&(identical(other.weight, weight) || other.weight == weight)&&const DeepCollectionEquality().equals(other.questions, questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,type,timeLimitMinutes,weight,const DeepCollectionEquality().hash(questions));

@override
String toString() {
  return 'AssessmentTemplate(id: $id, title: $title, description: $description, type: $type, timeLimitMinutes: $timeLimitMinutes, weight: $weight, questions: $questions)';
}


}

/// @nodoc
abstract mixin class $AssessmentTemplateCopyWith<$Res>  {
  factory $AssessmentTemplateCopyWith(AssessmentTemplate value, $Res Function(AssessmentTemplate) _then) = _$AssessmentTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String type,@JsonKey(name: 'time_limit_minutes') int timeLimitMinutes, int weight, List<TemplateQuestion> questions
});




}
/// @nodoc
class _$AssessmentTemplateCopyWithImpl<$Res>
    implements $AssessmentTemplateCopyWith<$Res> {
  _$AssessmentTemplateCopyWithImpl(this._self, this._then);

  final AssessmentTemplate _self;
  final $Res Function(AssessmentTemplate) _then;

/// Create a copy of AssessmentTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? type = null,Object? timeLimitMinutes = null,Object? weight = null,Object? questions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timeLimitMinutes: null == timeLimitMinutes ? _self.timeLimitMinutes : timeLimitMinutes // ignore: cast_nullable_to_non_nullable
as int,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<TemplateQuestion>,
  ));
}

}


/// Adds pattern-matching-related methods to [AssessmentTemplate].
extension AssessmentTemplatePatterns on AssessmentTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssessmentTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssessmentTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssessmentTemplate value)  $default,){
final _that = this;
switch (_that) {
case _AssessmentTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssessmentTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _AssessmentTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String type, @JsonKey(name: 'time_limit_minutes')  int timeLimitMinutes,  int weight,  List<TemplateQuestion> questions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssessmentTemplate() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.type,_that.timeLimitMinutes,_that.weight,_that.questions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String type, @JsonKey(name: 'time_limit_minutes')  int timeLimitMinutes,  int weight,  List<TemplateQuestion> questions)  $default,) {final _that = this;
switch (_that) {
case _AssessmentTemplate():
return $default(_that.id,_that.title,_that.description,_that.type,_that.timeLimitMinutes,_that.weight,_that.questions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String type, @JsonKey(name: 'time_limit_minutes')  int timeLimitMinutes,  int weight,  List<TemplateQuestion> questions)?  $default,) {final _that = this;
switch (_that) {
case _AssessmentTemplate() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.type,_that.timeLimitMinutes,_that.weight,_that.questions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssessmentTemplate implements AssessmentTemplate {
  const _AssessmentTemplate({required this.id, required this.title, required this.description, required this.type, @JsonKey(name: 'time_limit_minutes') required this.timeLimitMinutes, required this.weight, required final  List<TemplateQuestion> questions}): _questions = questions;
  factory _AssessmentTemplate.fromJson(Map<String, dynamic> json) => _$AssessmentTemplateFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String type;
@override@JsonKey(name: 'time_limit_minutes') final  int timeLimitMinutes;
@override final  int weight;
 final  List<TemplateQuestion> _questions;
@override List<TemplateQuestion> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}


/// Create a copy of AssessmentTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssessmentTemplateCopyWith<_AssessmentTemplate> get copyWith => __$AssessmentTemplateCopyWithImpl<_AssessmentTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssessmentTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssessmentTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.timeLimitMinutes, timeLimitMinutes) || other.timeLimitMinutes == timeLimitMinutes)&&(identical(other.weight, weight) || other.weight == weight)&&const DeepCollectionEquality().equals(other._questions, _questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,type,timeLimitMinutes,weight,const DeepCollectionEquality().hash(_questions));

@override
String toString() {
  return 'AssessmentTemplate(id: $id, title: $title, description: $description, type: $type, timeLimitMinutes: $timeLimitMinutes, weight: $weight, questions: $questions)';
}


}

/// @nodoc
abstract mixin class _$AssessmentTemplateCopyWith<$Res> implements $AssessmentTemplateCopyWith<$Res> {
  factory _$AssessmentTemplateCopyWith(_AssessmentTemplate value, $Res Function(_AssessmentTemplate) _then) = __$AssessmentTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String type,@JsonKey(name: 'time_limit_minutes') int timeLimitMinutes, int weight, List<TemplateQuestion> questions
});




}
/// @nodoc
class __$AssessmentTemplateCopyWithImpl<$Res>
    implements _$AssessmentTemplateCopyWith<$Res> {
  __$AssessmentTemplateCopyWithImpl(this._self, this._then);

  final _AssessmentTemplate _self;
  final $Res Function(_AssessmentTemplate) _then;

/// Create a copy of AssessmentTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? type = null,Object? timeLimitMinutes = null,Object? weight = null,Object? questions = null,}) {
  return _then(_AssessmentTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timeLimitMinutes: null == timeLimitMinutes ? _self.timeLimitMinutes : timeLimitMinutes // ignore: cast_nullable_to_non_nullable
as int,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<TemplateQuestion>,
  ));
}


}


/// @nodoc
mixin _$TemplateQuestion {

 String get body; String get type; int get points;@JsonKey(name: 'suggested_course_outcome') String? get suggestedCourseOutcome; List<TemplateOption> get options;
/// Create a copy of TemplateQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemplateQuestionCopyWith<TemplateQuestion> get copyWith => _$TemplateQuestionCopyWithImpl<TemplateQuestion>(this as TemplateQuestion, _$identity);

  /// Serializes this TemplateQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemplateQuestion&&(identical(other.body, body) || other.body == body)&&(identical(other.type, type) || other.type == type)&&(identical(other.points, points) || other.points == points)&&(identical(other.suggestedCourseOutcome, suggestedCourseOutcome) || other.suggestedCourseOutcome == suggestedCourseOutcome)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,type,points,suggestedCourseOutcome,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'TemplateQuestion(body: $body, type: $type, points: $points, suggestedCourseOutcome: $suggestedCourseOutcome, options: $options)';
}


}

/// @nodoc
abstract mixin class $TemplateQuestionCopyWith<$Res>  {
  factory $TemplateQuestionCopyWith(TemplateQuestion value, $Res Function(TemplateQuestion) _then) = _$TemplateQuestionCopyWithImpl;
@useResult
$Res call({
 String body, String type, int points,@JsonKey(name: 'suggested_course_outcome') String? suggestedCourseOutcome, List<TemplateOption> options
});




}
/// @nodoc
class _$TemplateQuestionCopyWithImpl<$Res>
    implements $TemplateQuestionCopyWith<$Res> {
  _$TemplateQuestionCopyWithImpl(this._self, this._then);

  final TemplateQuestion _self;
  final $Res Function(TemplateQuestion) _then;

/// Create a copy of TemplateQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,Object? type = null,Object? points = null,Object? suggestedCourseOutcome = freezed,Object? options = null,}) {
  return _then(_self.copyWith(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,suggestedCourseOutcome: freezed == suggestedCourseOutcome ? _self.suggestedCourseOutcome : suggestedCourseOutcome // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<TemplateOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [TemplateQuestion].
extension TemplateQuestionPatterns on TemplateQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemplateQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemplateQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemplateQuestion value)  $default,){
final _that = this;
switch (_that) {
case _TemplateQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemplateQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _TemplateQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String body,  String type,  int points, @JsonKey(name: 'suggested_course_outcome')  String? suggestedCourseOutcome,  List<TemplateOption> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TemplateQuestion() when $default != null:
return $default(_that.body,_that.type,_that.points,_that.suggestedCourseOutcome,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String body,  String type,  int points, @JsonKey(name: 'suggested_course_outcome')  String? suggestedCourseOutcome,  List<TemplateOption> options)  $default,) {final _that = this;
switch (_that) {
case _TemplateQuestion():
return $default(_that.body,_that.type,_that.points,_that.suggestedCourseOutcome,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String body,  String type,  int points, @JsonKey(name: 'suggested_course_outcome')  String? suggestedCourseOutcome,  List<TemplateOption> options)?  $default,) {final _that = this;
switch (_that) {
case _TemplateQuestion() when $default != null:
return $default(_that.body,_that.type,_that.points,_that.suggestedCourseOutcome,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TemplateQuestion implements TemplateQuestion {
  const _TemplateQuestion({required this.body, required this.type, required this.points, @JsonKey(name: 'suggested_course_outcome') this.suggestedCourseOutcome, required final  List<TemplateOption> options}): _options = options;
  factory _TemplateQuestion.fromJson(Map<String, dynamic> json) => _$TemplateQuestionFromJson(json);

@override final  String body;
@override final  String type;
@override final  int points;
@override@JsonKey(name: 'suggested_course_outcome') final  String? suggestedCourseOutcome;
 final  List<TemplateOption> _options;
@override List<TemplateOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of TemplateQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemplateQuestionCopyWith<_TemplateQuestion> get copyWith => __$TemplateQuestionCopyWithImpl<_TemplateQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemplateQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemplateQuestion&&(identical(other.body, body) || other.body == body)&&(identical(other.type, type) || other.type == type)&&(identical(other.points, points) || other.points == points)&&(identical(other.suggestedCourseOutcome, suggestedCourseOutcome) || other.suggestedCourseOutcome == suggestedCourseOutcome)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,type,points,suggestedCourseOutcome,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'TemplateQuestion(body: $body, type: $type, points: $points, suggestedCourseOutcome: $suggestedCourseOutcome, options: $options)';
}


}

/// @nodoc
abstract mixin class _$TemplateQuestionCopyWith<$Res> implements $TemplateQuestionCopyWith<$Res> {
  factory _$TemplateQuestionCopyWith(_TemplateQuestion value, $Res Function(_TemplateQuestion) _then) = __$TemplateQuestionCopyWithImpl;
@override @useResult
$Res call({
 String body, String type, int points,@JsonKey(name: 'suggested_course_outcome') String? suggestedCourseOutcome, List<TemplateOption> options
});




}
/// @nodoc
class __$TemplateQuestionCopyWithImpl<$Res>
    implements _$TemplateQuestionCopyWith<$Res> {
  __$TemplateQuestionCopyWithImpl(this._self, this._then);

  final _TemplateQuestion _self;
  final $Res Function(_TemplateQuestion) _then;

/// Create a copy of TemplateQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? type = null,Object? points = null,Object? suggestedCourseOutcome = freezed,Object? options = null,}) {
  return _then(_TemplateQuestion(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,suggestedCourseOutcome: freezed == suggestedCourseOutcome ? _self.suggestedCourseOutcome : suggestedCourseOutcome // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<TemplateOption>,
  ));
}


}


/// @nodoc
mixin _$TemplateOption {

 String get body;@JsonKey(name: 'is_correct') bool get isCorrect;
/// Create a copy of TemplateOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemplateOptionCopyWith<TemplateOption> get copyWith => _$TemplateOptionCopyWithImpl<TemplateOption>(this as TemplateOption, _$identity);

  /// Serializes this TemplateOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemplateOption&&(identical(other.body, body) || other.body == body)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,isCorrect);

@override
String toString() {
  return 'TemplateOption(body: $body, isCorrect: $isCorrect)';
}


}

/// @nodoc
abstract mixin class $TemplateOptionCopyWith<$Res>  {
  factory $TemplateOptionCopyWith(TemplateOption value, $Res Function(TemplateOption) _then) = _$TemplateOptionCopyWithImpl;
@useResult
$Res call({
 String body,@JsonKey(name: 'is_correct') bool isCorrect
});




}
/// @nodoc
class _$TemplateOptionCopyWithImpl<$Res>
    implements $TemplateOptionCopyWith<$Res> {
  _$TemplateOptionCopyWithImpl(this._self, this._then);

  final TemplateOption _self;
  final $Res Function(TemplateOption) _then;

/// Create a copy of TemplateOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,Object? isCorrect = null,}) {
  return _then(_self.copyWith(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TemplateOption].
extension TemplateOptionPatterns on TemplateOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemplateOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemplateOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemplateOption value)  $default,){
final _that = this;
switch (_that) {
case _TemplateOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemplateOption value)?  $default,){
final _that = this;
switch (_that) {
case _TemplateOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String body, @JsonKey(name: 'is_correct')  bool isCorrect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TemplateOption() when $default != null:
return $default(_that.body,_that.isCorrect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String body, @JsonKey(name: 'is_correct')  bool isCorrect)  $default,) {final _that = this;
switch (_that) {
case _TemplateOption():
return $default(_that.body,_that.isCorrect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String body, @JsonKey(name: 'is_correct')  bool isCorrect)?  $default,) {final _that = this;
switch (_that) {
case _TemplateOption() when $default != null:
return $default(_that.body,_that.isCorrect);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TemplateOption implements TemplateOption {
  const _TemplateOption({required this.body, @JsonKey(name: 'is_correct') required this.isCorrect});
  factory _TemplateOption.fromJson(Map<String, dynamic> json) => _$TemplateOptionFromJson(json);

@override final  String body;
@override@JsonKey(name: 'is_correct') final  bool isCorrect;

/// Create a copy of TemplateOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemplateOptionCopyWith<_TemplateOption> get copyWith => __$TemplateOptionCopyWithImpl<_TemplateOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemplateOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemplateOption&&(identical(other.body, body) || other.body == body)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,isCorrect);

@override
String toString() {
  return 'TemplateOption(body: $body, isCorrect: $isCorrect)';
}


}

/// @nodoc
abstract mixin class _$TemplateOptionCopyWith<$Res> implements $TemplateOptionCopyWith<$Res> {
  factory _$TemplateOptionCopyWith(_TemplateOption value, $Res Function(_TemplateOption) _then) = __$TemplateOptionCopyWithImpl;
@override @useResult
$Res call({
 String body,@JsonKey(name: 'is_correct') bool isCorrect
});




}
/// @nodoc
class __$TemplateOptionCopyWithImpl<$Res>
    implements _$TemplateOptionCopyWith<$Res> {
  __$TemplateOptionCopyWithImpl(this._self, this._then);

  final _TemplateOption _self;
  final $Res Function(_TemplateOption) _then;

/// Create a copy of TemplateOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? isCorrect = null,}) {
  return _then(_TemplateOption(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
