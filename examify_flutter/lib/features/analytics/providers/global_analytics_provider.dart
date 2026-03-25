// lib/features/analytics/providers/global_analytics_provider.dart
//
// Aggregates proctoring data across ALL of the teacher's classrooms.
// Uses KeepAlive so the data stays cached when scrolled off-screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/exam_analytics.dart';

// ─────────────────────────────────────────────
//  Global Analytics Data Model
// ─────────────────────────────────────────────

/// Per-student stat enriched with the classroom they belong to.
class EnrichedStudentStat extends TopStudentStat {
  final String classroomName;
  const EnrichedStudentStat({
    required super.name,
    required super.violationCount,
    required super.attemptId,
    required this.classroomName,
  });
}

/// Per-classroom violation summary used for the "most violating" flag.
class ClassroomViolationStat {
  final String name;
  final int violationCount;
  const ClassroomViolationStat({
    required this.name,
    required this.violationCount,
  });
}

class GlobalAnalytics {
  final int totalStudents;
  final int totalClassrooms;
  final int totalAssessments;
  final int totalViolations;
  final Map<String, int> violationsByType;
  final List<EnrichedStudentStat> topOffenders;
  final List<AssessmentOption> examOptions;
  final List<ClassroomViolationStat> classroomStats; // sorted desc by count

  const GlobalAnalytics({
    required this.totalStudents,
    required this.totalClassrooms,
    required this.totalAssessments,
    required this.totalViolations,
    required this.violationsByType,
    required this.topOffenders,
    required this.examOptions,
    required this.classroomStats,
  });

  List<ViolationTypeStat> get byTypeSorted =>
      violationsByType.entries
          .map((e) => ViolationTypeStat(type: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

  ClassroomViolationStat? get mostViolatingClassroom =>
      classroomStats.isNotEmpty ? classroomStats.first : null;
}

class AssessmentOption {
  final int id;
  final String title;
  final String classroomName;
  AssessmentOption({
    required this.id,
    required this.title,
    required this.classroomName,
  });
}

// ─────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────
final globalAnalyticsProvider = FutureProvider<GlobalAnalytics>((ref) async {
  ref.watch(authProvider); // re-fetch on auth change
  ref.keepAlive(); // KeepAlive: don't dispose when not listened

  final dio = ref.watch(apiClientProvider);

  // 1. Get all classrooms
  final classroomsResponse = await dio.get('/classrooms');
  final classrooms = (classroomsResponse.data as List)
      .map(
        (j) => {
          'id': j['id'],
          'name': j['name'],
          'students_count': j['students_count'] ?? 0,
        },
      )
      .toList();

  int totalStudents = 0;
  int totalViolations = 0;
  final Map<String, int> typeMap = {};
  final Map<int, _StudentAccumulator> studentMap = {};
  final List<AssessmentOption> examOptions = [];
  final Map<String, int> classroomViolMap = {}; // classroomName -> total

  // 2. For each classroom fetch assessments and their proctoring reports
  for (final classroom in classrooms) {
    totalStudents += (classroom['students_count'] as int);
    final cid = classroom['id'];
    final cName = classroom['name'] as String;

    List<dynamic> assessments = [];
    try {
      final aResponse = await dio.get('/classrooms/$cid/assessments');
      assessments = aResponse.data as List<dynamic>;
    } catch (_) {
      continue;
    }

    for (final a in assessments) {
      final aid = a['id'] as int;
      examOptions.add(
        AssessmentOption(
          id: aid,
          title: a['title'] as String? ?? 'Assessment #$aid',
          classroomName: cName,
        ),
      );

      // Fetch proctoring logs for this assessment
      try {
        final pResponse = await dio.get('/assessments/$aid/proctoring-report');
        final reports = pResponse.data as List<dynamic>;
        for (final r in reports) {
          final student = r['student'] as Map<String, dynamic>;
          final sid = (student['id'] as num).toInt();
          final vCount = (r['total_violations'] as num).toInt();
          totalViolations += vCount;
          classroomViolMap[cName] = (classroomViolMap[cName] ?? 0) + vCount;

          final prev = studentMap[sid];
          studentMap[sid] = _StudentAccumulator(
            name: student['name'] as String,
            count: (prev?.count ?? 0) + vCount,
            attemptId: sid,
            classroomName: cName,
          );

          for (final log in (r['logs'] as List<dynamic>)) {
            final type = log['event_type'] as String;
            typeMap[type] = (typeMap[type] ?? 0) + 1;
          }
        }
      } catch (_) {
        continue;
      }
    }
  }

  final topOffenders =
      studentMap.values
          .map(
            (s) => EnrichedStudentStat(
              name: s.name,
              violationCount: s.count,
              attemptId: s.attemptId,
              classroomName: s.classroomName,
            ),
          )
          .toList()
        ..sort((a, b) => b.violationCount.compareTo(a.violationCount));

  final classroomStats =
      classroomViolMap.entries
          .map(
            (e) => ClassroomViolationStat(name: e.key, violationCount: e.value),
          )
          .toList()
        ..sort((a, b) => b.violationCount.compareTo(a.violationCount));

  return GlobalAnalytics(
    totalStudents: totalStudents,
    totalClassrooms: classrooms.length,
    totalAssessments: examOptions.length,
    totalViolations: totalViolations,
    violationsByType: typeMap,
    topOffenders: topOffenders.take(5).toList(),
    examOptions: examOptions,
    classroomStats: classroomStats,
  );
});

class _StudentAccumulator {
  final String name;
  final int count;
  final int attemptId;
  final String classroomName;
  _StudentAccumulator({
    required this.name,
    required this.count,
    required this.attemptId,
    required this.classroomName,
  });
}
