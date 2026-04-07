import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_data.freezed.dart';
part 'analytics_data.g.dart';

@freezed
abstract class AnalyticsData with _$AnalyticsData {
  const factory AnalyticsData({
    @JsonKey(name: 'average_score') required double averageScore,
    @JsonKey(name: 'highest_score') required double highestScore,
    @JsonKey(name: 'lowest_score') required double lowestScore,
    @JsonKey(name: 'score_distribution')
    required Map<String, int> scoreDistribution,
    @JsonKey(name: 'question_performance')
    required List<QuestionPerformance> questionPerformance,
  }) = _AnalyticsData;

  factory AnalyticsData.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsDataFromJson(json);
}

@freezed
abstract class QuestionPerformance with _$QuestionPerformance {
  const factory QuestionPerformance({
    required int id,
    required String text,
    @JsonKey(name: 'correct_count') required int correctCount,
    @JsonKey(name: 'incorrect_count') required int incorrectCount,
  }) = _QuestionPerformance;

  factory QuestionPerformance.fromJson(Map<String, dynamic> json) =>
      _$QuestionPerformanceFromJson(json);
}
