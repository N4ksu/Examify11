// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalyticsData _$AnalyticsDataFromJson(Map<String, dynamic> json) =>
    _AnalyticsData(
      averageScore: (json['average_score'] as num).toDouble(),
      highestScore: (json['highest_score'] as num).toDouble(),
      lowestScore: (json['lowest_score'] as num).toDouble(),
      scoreDistribution: Map<String, int>.from(
        json['score_distribution'] as Map,
      ),
      questionPerformance: (json['question_performance'] as List<dynamic>)
          .map((e) => QuestionPerformance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnalyticsDataToJson(_AnalyticsData instance) =>
    <String, dynamic>{
      'average_score': instance.averageScore,
      'highest_score': instance.highestScore,
      'lowest_score': instance.lowestScore,
      'score_distribution': instance.scoreDistribution,
      'question_performance': instance.questionPerformance,
    };

_QuestionPerformance _$QuestionPerformanceFromJson(Map<String, dynamic> json) =>
    _QuestionPerformance(
      id: (json['id'] as num).toInt(),
      text: json['text'] as String,
      correctCount: (json['correct_count'] as num).toInt(),
      incorrectCount: (json['incorrect_count'] as num).toInt(),
    );

Map<String, dynamic> _$QuestionPerformanceToJson(
  _QuestionPerformance instance,
) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'correct_count': instance.correctCount,
  'incorrect_count': instance.incorrectCount,
};
