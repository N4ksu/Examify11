// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssessmentTemplate _$AssessmentTemplateFromJson(Map<String, dynamic> json) =>
    _AssessmentTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      timeLimitMinutes: (json['time_limit_minutes'] as num).toInt(),
      weight: (json['weight'] as num).toInt(),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => TemplateQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AssessmentTemplateToJson(_AssessmentTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'time_limit_minutes': instance.timeLimitMinutes,
      'weight': instance.weight,
      'questions': instance.questions,
    };

_TemplateQuestion _$TemplateQuestionFromJson(Map<String, dynamic> json) =>
    _TemplateQuestion(
      body: json['body'] as String,
      type: json['type'] as String,
      points: (json['points'] as num).toInt(),
      suggestedCourseOutcome: json['suggested_course_outcome'] as String?,
      options: (json['options'] as List<dynamic>)
          .map((e) => TemplateOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TemplateQuestionToJson(_TemplateQuestion instance) =>
    <String, dynamic>{
      'body': instance.body,
      'type': instance.type,
      'points': instance.points,
      'suggested_course_outcome': instance.suggestedCourseOutcome,
      'options': instance.options,
    };

_TemplateOption _$TemplateOptionFromJson(Map<String, dynamic> json) =>
    _TemplateOption(
      body: json['body'] as String,
      isCorrect: json['is_correct'] as bool,
    );

Map<String, dynamic> _$TemplateOptionToJson(_TemplateOption instance) =>
    <String, dynamic>{'body': instance.body, 'is_correct': instance.isCorrect};
