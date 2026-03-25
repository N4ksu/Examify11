import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../models/assessment.dart';
import '../models/question.dart';

final assessmentsProvider = FutureProvider.family<List<Assessment>, int>((ref, classroomId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/classrooms/$classroomId/assessments');
  return (response.data as List).map((x) => Assessment.fromJson(x)).toList();
});

final studentAttemptProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, assessmentId) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/assessments/$assessmentId/my-attempt');
    return response.data;
  } catch (e) {
    if (e is DioException && e.response?.statusCode == 404) {
      return null; // No attempt found
    }
    rethrow;
  }
});

final assessmentDetailProvider = FutureProvider.family<Assessment, int>((ref, assessmentId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/assessments/$assessmentId');
  return Assessment.fromJson(response.data);
});

final questionsProvider = FutureProvider.family<List<Question>, int>((ref, assessmentId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/assessments/$assessmentId/questions');
  return (response.data as List).map((x) => Question.fromJson(x)).toList();
});

final studentResultProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, attemptId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/attempts/$attemptId/result');
  return response.data;
});
