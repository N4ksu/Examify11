import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/outcome_mastery.dart';

final outcomeAnalyticsProvider = FutureProvider.family<ExamOutcomeAnalytics, int>((ref, assessmentId) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/assessments/$assessmentId/outcome-analytics');
  return ExamOutcomeAnalytics.fromJson(response.data);
});
