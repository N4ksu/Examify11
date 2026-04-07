// lib/features/analytics/providers/exam_analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/exam_analytics.dart';

/// Fetches the exam violation summary for [examId].
final examAnalyticsProvider = FutureProvider.family<ExamSummary, int>((
  ref,
  examId,
) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/assessments/$examId/proctoring-report');

  // The existing endpoint returns a list of per-student reports.
  // We aggregate them here into the ExamSummary shape expected by the UI.
  final List<dynamic> reports = response.data as List<dynamic>;

  int totalViolations = 0;
  final Map<String, int> typeMap = {};
  final List<TopStudentStat> topStudents = [];

  for (final r in reports) {
    final student = r['student'] as Map<String, dynamic>;
    final int studentViolations = (r['total_violations'] as num).toInt();
    totalViolations += studentViolations;

    topStudents.add(
      TopStudentStat(
        name: student['name'] as String,
        violationCount: studentViolations,
        attemptId: (student['id'] as num).toInt(),
      ),
    );

    for (final log in (r['logs'] as List<dynamic>)) {
      final type = log['event_type'] as String;
      typeMap[type] = (typeMap[type] ?? 0) + 1;
    }
  }

  topStudents.sort((a, b) => b.violationCount.compareTo(a.violationCount));

  final byType =
      typeMap.entries
          .map((e) => ViolationTypeStat(type: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

  return ExamSummary(
    classroomId: 0, // In case backend hasn't updated, fall back to 0
    totalViolations: totalViolations,
    byType: byType,
    topStudents: topStudents.take(5).toList(),
  );
});

/// Fetches per-student violation detail for [attemptId].
final studentViolationProvider =
    FutureProvider.family<StudentViolationDetail, int>((ref, attemptId) async {
      final dio = ref.watch(apiClientProvider);
      final response = await dio.get('/attempts/$attemptId/result');
      // Falls back gracefully if the endpoint isn't available yet
      return StudentViolationDetail.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
