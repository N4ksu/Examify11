import 'package:freezed_annotation/freezed_annotation.dart';

part 'assessment_template.freezed.dart';
part 'assessment_template.g.dart';

@freezed
abstract class AssessmentTemplate with _$AssessmentTemplate {
  const factory AssessmentTemplate({
    required String id,
    required String title,
    required String description,
    required String type,
    @JsonKey(name: 'time_limit_minutes') required int timeLimitMinutes,
    required int weight,
    required List<TemplateQuestion> questions,
  }) = _AssessmentTemplate;

  factory AssessmentTemplate.fromJson(Map<String, dynamic> json) =>
      _$AssessmentTemplateFromJson(json);
}

@freezed
abstract class TemplateQuestion with _$TemplateQuestion {
  const factory TemplateQuestion({
    required String body,
    required String type,
    required int points,
    @JsonKey(name: 'suggested_course_outcome') String? suggestedCourseOutcome,
    required List<TemplateOption> options,
  }) = _TemplateQuestion;

  factory TemplateQuestion.fromJson(Map<String, dynamic> json) =>
      _$TemplateQuestionFromJson(json);
}

@freezed
abstract class TemplateOption with _$TemplateOption {
  const factory TemplateOption({
    required String body,
    @JsonKey(name: 'is_correct') required bool isCorrect,
  }) = _TemplateOption;

  factory TemplateOption.fromJson(Map<String, dynamic> json) =>
      _$TemplateOptionFromJson(json);
}
