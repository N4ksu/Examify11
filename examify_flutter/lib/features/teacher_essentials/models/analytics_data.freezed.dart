// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalyticsData {

@JsonKey(name: 'average_score') double get averageScore;@JsonKey(name: 'highest_score') double get highestScore;@JsonKey(name: 'lowest_score') double get lowestScore;@JsonKey(name: 'score_distribution') Map<String, int> get scoreDistribution;@JsonKey(name: 'question_performance') List<QuestionPerformance> get questionPerformance;
/// Create a copy of AnalyticsData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsDataCopyWith<AnalyticsData> get copyWith => _$AnalyticsDataCopyWithImpl<AnalyticsData>(this as AnalyticsData, _$identity);

  /// Serializes this AnalyticsData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsData&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore)&&(identical(other.highestScore, highestScore) || other.highestScore == highestScore)&&(identical(other.lowestScore, lowestScore) || other.lowestScore == lowestScore)&&const DeepCollectionEquality().equals(other.scoreDistribution, scoreDistribution)&&const DeepCollectionEquality().equals(other.questionPerformance, questionPerformance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,averageScore,highestScore,lowestScore,const DeepCollectionEquality().hash(scoreDistribution),const DeepCollectionEquality().hash(questionPerformance));

@override
String toString() {
  return 'AnalyticsData(averageScore: $averageScore, highestScore: $highestScore, lowestScore: $lowestScore, scoreDistribution: $scoreDistribution, questionPerformance: $questionPerformance)';
}


}

/// @nodoc
abstract mixin class $AnalyticsDataCopyWith<$Res>  {
  factory $AnalyticsDataCopyWith(AnalyticsData value, $Res Function(AnalyticsData) _then) = _$AnalyticsDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'average_score') double averageScore,@JsonKey(name: 'highest_score') double highestScore,@JsonKey(name: 'lowest_score') double lowestScore,@JsonKey(name: 'score_distribution') Map<String, int> scoreDistribution,@JsonKey(name: 'question_performance') List<QuestionPerformance> questionPerformance
});




}
/// @nodoc
class _$AnalyticsDataCopyWithImpl<$Res>
    implements $AnalyticsDataCopyWith<$Res> {
  _$AnalyticsDataCopyWithImpl(this._self, this._then);

  final AnalyticsData _self;
  final $Res Function(AnalyticsData) _then;

/// Create a copy of AnalyticsData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? averageScore = null,Object? highestScore = null,Object? lowestScore = null,Object? scoreDistribution = null,Object? questionPerformance = null,}) {
  return _then(_self.copyWith(
averageScore: null == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double,highestScore: null == highestScore ? _self.highestScore : highestScore // ignore: cast_nullable_to_non_nullable
as double,lowestScore: null == lowestScore ? _self.lowestScore : lowestScore // ignore: cast_nullable_to_non_nullable
as double,scoreDistribution: null == scoreDistribution ? _self.scoreDistribution : scoreDistribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,questionPerformance: null == questionPerformance ? _self.questionPerformance : questionPerformance // ignore: cast_nullable_to_non_nullable
as List<QuestionPerformance>,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsData].
extension AnalyticsDataPatterns on AnalyticsData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsData value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsData value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'average_score')  double averageScore, @JsonKey(name: 'highest_score')  double highestScore, @JsonKey(name: 'lowest_score')  double lowestScore, @JsonKey(name: 'score_distribution')  Map<String, int> scoreDistribution, @JsonKey(name: 'question_performance')  List<QuestionPerformance> questionPerformance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsData() when $default != null:
return $default(_that.averageScore,_that.highestScore,_that.lowestScore,_that.scoreDistribution,_that.questionPerformance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'average_score')  double averageScore, @JsonKey(name: 'highest_score')  double highestScore, @JsonKey(name: 'lowest_score')  double lowestScore, @JsonKey(name: 'score_distribution')  Map<String, int> scoreDistribution, @JsonKey(name: 'question_performance')  List<QuestionPerformance> questionPerformance)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsData():
return $default(_that.averageScore,_that.highestScore,_that.lowestScore,_that.scoreDistribution,_that.questionPerformance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'average_score')  double averageScore, @JsonKey(name: 'highest_score')  double highestScore, @JsonKey(name: 'lowest_score')  double lowestScore, @JsonKey(name: 'score_distribution')  Map<String, int> scoreDistribution, @JsonKey(name: 'question_performance')  List<QuestionPerformance> questionPerformance)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsData() when $default != null:
return $default(_that.averageScore,_that.highestScore,_that.lowestScore,_that.scoreDistribution,_that.questionPerformance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyticsData implements AnalyticsData {
  const _AnalyticsData({@JsonKey(name: 'average_score') required this.averageScore, @JsonKey(name: 'highest_score') required this.highestScore, @JsonKey(name: 'lowest_score') required this.lowestScore, @JsonKey(name: 'score_distribution') required final  Map<String, int> scoreDistribution, @JsonKey(name: 'question_performance') required final  List<QuestionPerformance> questionPerformance}): _scoreDistribution = scoreDistribution,_questionPerformance = questionPerformance;
  factory _AnalyticsData.fromJson(Map<String, dynamic> json) => _$AnalyticsDataFromJson(json);

@override@JsonKey(name: 'average_score') final  double averageScore;
@override@JsonKey(name: 'highest_score') final  double highestScore;
@override@JsonKey(name: 'lowest_score') final  double lowestScore;
 final  Map<String, int> _scoreDistribution;
@override@JsonKey(name: 'score_distribution') Map<String, int> get scoreDistribution {
  if (_scoreDistribution is EqualUnmodifiableMapView) return _scoreDistribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_scoreDistribution);
}

 final  List<QuestionPerformance> _questionPerformance;
@override@JsonKey(name: 'question_performance') List<QuestionPerformance> get questionPerformance {
  if (_questionPerformance is EqualUnmodifiableListView) return _questionPerformance;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questionPerformance);
}


/// Create a copy of AnalyticsData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsDataCopyWith<_AnalyticsData> get copyWith => __$AnalyticsDataCopyWithImpl<_AnalyticsData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyticsDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsData&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore)&&(identical(other.highestScore, highestScore) || other.highestScore == highestScore)&&(identical(other.lowestScore, lowestScore) || other.lowestScore == lowestScore)&&const DeepCollectionEquality().equals(other._scoreDistribution, _scoreDistribution)&&const DeepCollectionEquality().equals(other._questionPerformance, _questionPerformance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,averageScore,highestScore,lowestScore,const DeepCollectionEquality().hash(_scoreDistribution),const DeepCollectionEquality().hash(_questionPerformance));

@override
String toString() {
  return 'AnalyticsData(averageScore: $averageScore, highestScore: $highestScore, lowestScore: $lowestScore, scoreDistribution: $scoreDistribution, questionPerformance: $questionPerformance)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsDataCopyWith<$Res> implements $AnalyticsDataCopyWith<$Res> {
  factory _$AnalyticsDataCopyWith(_AnalyticsData value, $Res Function(_AnalyticsData) _then) = __$AnalyticsDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'average_score') double averageScore,@JsonKey(name: 'highest_score') double highestScore,@JsonKey(name: 'lowest_score') double lowestScore,@JsonKey(name: 'score_distribution') Map<String, int> scoreDistribution,@JsonKey(name: 'question_performance') List<QuestionPerformance> questionPerformance
});




}
/// @nodoc
class __$AnalyticsDataCopyWithImpl<$Res>
    implements _$AnalyticsDataCopyWith<$Res> {
  __$AnalyticsDataCopyWithImpl(this._self, this._then);

  final _AnalyticsData _self;
  final $Res Function(_AnalyticsData) _then;

/// Create a copy of AnalyticsData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? averageScore = null,Object? highestScore = null,Object? lowestScore = null,Object? scoreDistribution = null,Object? questionPerformance = null,}) {
  return _then(_AnalyticsData(
averageScore: null == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double,highestScore: null == highestScore ? _self.highestScore : highestScore // ignore: cast_nullable_to_non_nullable
as double,lowestScore: null == lowestScore ? _self.lowestScore : lowestScore // ignore: cast_nullable_to_non_nullable
as double,scoreDistribution: null == scoreDistribution ? _self._scoreDistribution : scoreDistribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,questionPerformance: null == questionPerformance ? _self._questionPerformance : questionPerformance // ignore: cast_nullable_to_non_nullable
as List<QuestionPerformance>,
  ));
}


}


/// @nodoc
mixin _$QuestionPerformance {

 int get id; String get text;@JsonKey(name: 'correct_count') int get correctCount;@JsonKey(name: 'incorrect_count') int get incorrectCount;
/// Create a copy of QuestionPerformance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionPerformanceCopyWith<QuestionPerformance> get copyWith => _$QuestionPerformanceCopyWithImpl<QuestionPerformance>(this as QuestionPerformance, _$identity);

  /// Serializes this QuestionPerformance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionPerformance&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount)&&(identical(other.incorrectCount, incorrectCount) || other.incorrectCount == incorrectCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,correctCount,incorrectCount);

@override
String toString() {
  return 'QuestionPerformance(id: $id, text: $text, correctCount: $correctCount, incorrectCount: $incorrectCount)';
}


}

/// @nodoc
abstract mixin class $QuestionPerformanceCopyWith<$Res>  {
  factory $QuestionPerformanceCopyWith(QuestionPerformance value, $Res Function(QuestionPerformance) _then) = _$QuestionPerformanceCopyWithImpl;
@useResult
$Res call({
 int id, String text,@JsonKey(name: 'correct_count') int correctCount,@JsonKey(name: 'incorrect_count') int incorrectCount
});




}
/// @nodoc
class _$QuestionPerformanceCopyWithImpl<$Res>
    implements $QuestionPerformanceCopyWith<$Res> {
  _$QuestionPerformanceCopyWithImpl(this._self, this._then);

  final QuestionPerformance _self;
  final $Res Function(QuestionPerformance) _then;

/// Create a copy of QuestionPerformance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? correctCount = null,Object? incorrectCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,correctCount: null == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int,incorrectCount: null == incorrectCount ? _self.incorrectCount : incorrectCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionPerformance].
extension QuestionPerformancePatterns on QuestionPerformance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionPerformance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionPerformance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionPerformance value)  $default,){
final _that = this;
switch (_that) {
case _QuestionPerformance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionPerformance value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionPerformance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String text, @JsonKey(name: 'correct_count')  int correctCount, @JsonKey(name: 'incorrect_count')  int incorrectCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionPerformance() when $default != null:
return $default(_that.id,_that.text,_that.correctCount,_that.incorrectCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String text, @JsonKey(name: 'correct_count')  int correctCount, @JsonKey(name: 'incorrect_count')  int incorrectCount)  $default,) {final _that = this;
switch (_that) {
case _QuestionPerformance():
return $default(_that.id,_that.text,_that.correctCount,_that.incorrectCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String text, @JsonKey(name: 'correct_count')  int correctCount, @JsonKey(name: 'incorrect_count')  int incorrectCount)?  $default,) {final _that = this;
switch (_that) {
case _QuestionPerformance() when $default != null:
return $default(_that.id,_that.text,_that.correctCount,_that.incorrectCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionPerformance implements QuestionPerformance {
  const _QuestionPerformance({required this.id, required this.text, @JsonKey(name: 'correct_count') required this.correctCount, @JsonKey(name: 'incorrect_count') required this.incorrectCount});
  factory _QuestionPerformance.fromJson(Map<String, dynamic> json) => _$QuestionPerformanceFromJson(json);

@override final  int id;
@override final  String text;
@override@JsonKey(name: 'correct_count') final  int correctCount;
@override@JsonKey(name: 'incorrect_count') final  int incorrectCount;

/// Create a copy of QuestionPerformance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionPerformanceCopyWith<_QuestionPerformance> get copyWith => __$QuestionPerformanceCopyWithImpl<_QuestionPerformance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionPerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionPerformance&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount)&&(identical(other.incorrectCount, incorrectCount) || other.incorrectCount == incorrectCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,correctCount,incorrectCount);

@override
String toString() {
  return 'QuestionPerformance(id: $id, text: $text, correctCount: $correctCount, incorrectCount: $incorrectCount)';
}


}

/// @nodoc
abstract mixin class _$QuestionPerformanceCopyWith<$Res> implements $QuestionPerformanceCopyWith<$Res> {
  factory _$QuestionPerformanceCopyWith(_QuestionPerformance value, $Res Function(_QuestionPerformance) _then) = __$QuestionPerformanceCopyWithImpl;
@override @useResult
$Res call({
 int id, String text,@JsonKey(name: 'correct_count') int correctCount,@JsonKey(name: 'incorrect_count') int incorrectCount
});




}
/// @nodoc
class __$QuestionPerformanceCopyWithImpl<$Res>
    implements _$QuestionPerformanceCopyWith<$Res> {
  __$QuestionPerformanceCopyWithImpl(this._self, this._then);

  final _QuestionPerformance _self;
  final $Res Function(_QuestionPerformance) _then;

/// Create a copy of QuestionPerformance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? correctCount = null,Object? incorrectCount = null,}) {
  return _then(_QuestionPerformance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,correctCount: null == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int,incorrectCount: null == incorrectCount ? _self.incorrectCount : incorrectCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
