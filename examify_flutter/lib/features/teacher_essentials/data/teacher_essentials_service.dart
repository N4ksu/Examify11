import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/gradebook_entry.dart';
import '../models/analytics_data.dart';
import '../models/assessment_template.dart';
import '../models/proctoring_report.dart';
import '../../../shared/models/assessment.dart';

part 'teacher_essentials_service.g.dart';

class TeacherEssentialsService {
  final Dio _dio;

  TeacherEssentialsService(this._dio);

  Future<void> uploadStudents(File file, int classroomId) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'classroom_id': classroomId,
    });

    await _dio.post('/students/bulk-upload', data: formData);
  }

  Future<List<Assessment>> getAssessments(int classroomId) async {
    final response = await _dio.get('/classrooms/$classroomId/assessments');
    return (response.data as List).map((e) => Assessment.fromJson(e)).toList();
  }

  Future<List<GradebookEntry>> getGradebook(int classroomId) async {
    final response = await _dio.get('/classrooms/$classroomId/gradebook');
    return (response.data as List)
        .map((e) => GradebookEntry.fromJson(e))
        .toList();
  }

  Future<AnalyticsData> getExamAnalytics(int assessmentId) async {
    final response = await _dio.get('/analytics/exam/$assessmentId');
    return AnalyticsData.fromJson(response.data);
  }

  Future<List<AssessmentTemplate>> getAssessmentTemplates() async {
    final response = await _dio.get('/assessment-templates');
    return (response.data as List)
        .map((e) => AssessmentTemplate.fromJson(e))
        .toList();
  }

  Future<List<ProctoringReport>> getProctoringReport(int assessmentId) async {
    final response = await _dio.get(
      '/assessments/$assessmentId/proctoring-report',
    );
    return (response.data as List)
        .map((e) => ProctoringReport.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> submitAssessment(
    int attemptId,
    List<Map<String, dynamic>> answers,
  ) async {
    final response = await _dio.post(
      '/attempts/$attemptId/submit',
      data: {'answers': answers},
    );
    return response.data;
  }

  Future<void> deleteAssessment(int assessmentId) async {
    await _dio.delete('/assessments/$assessmentId');
  }

  Future<Assessment> getAssessmentDetail(int assessmentId) async {
    final response = await _dio.get('/assessments/$assessmentId');
    return Assessment.fromJson(response.data);
  }
}

@riverpod
TeacherEssentialsService teacherEssentialsService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  // Watch auth state to ensure service re-initializes on user change
  ref.watch(authProvider);
  return TeacherEssentialsService(dio);
}

final assessmentsProvider = FutureProvider.family<List<Assessment>, int>((
  ref,
  classroomId,
) {
  return ref
      .watch(teacherEssentialsServiceProvider)
      .getAssessments(classroomId);
});

final gradebookProvider = FutureProvider.family<List<GradebookEntry>, int>((
  ref,
  classroomId,
) {
  return ref.watch(teacherEssentialsServiceProvider).getGradebook(classroomId);
});

final assessmentTemplatesProvider = FutureProvider<List<AssessmentTemplate>>((
  ref,
) {
  return ref.watch(teacherEssentialsServiceProvider).getAssessmentTemplates();
});

final proctoringReportProvider =
    FutureProvider.family<List<ProctoringReport>, int>((ref, assessmentId) {
      return ref
          .watch(teacherEssentialsServiceProvider)
          .getProctoringReport(assessmentId);
    });

final assessmentDetailProvider = FutureProvider.family<Assessment, int>((
  ref,
  id,
) {
  return ref.watch(teacherEssentialsServiceProvider).getAssessmentDetail(id);
});
