// lib/features/analytics/models/exam_analytics.dart
// Data models for the exam analytics feature.

class ViolationTypeStat {
  final String type;
  final int count;

  const ViolationTypeStat({required this.type, required this.count});

  factory ViolationTypeStat.fromJson(Map<String, dynamic> json) =>
      ViolationTypeStat(
        type: json['type'] as String,
        count: json['count'] as int,
      );

  String get displayName {
    switch (type) {
      case 'tab_switch':
        return 'Tab Switch';
      case 'window_blur':
        return 'Window Blur';
      case 'app_background':
        return 'App Backgrounded';
      case 'copy_paste':
        return 'Copy / Paste';
      case 'context_menu':
        return 'Context Menu';
      case 'fullscreen_exit':
        return 'Fullscreen Exit';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }
}

class TopStudentStat {
  final String name;
  final int violationCount;
  final int attemptId;

  const TopStudentStat({
    required this.name,
    required this.violationCount,
    required this.attemptId,
  });

  factory TopStudentStat.fromJson(Map<String, dynamic> json) => TopStudentStat(
    name: json['name'] as String,
    violationCount: json['violation_count'] as int,
    attemptId: json['attempt_id'] as int,
  );
}

class ExamSummary {
  final int classroomId;
  final int totalViolations;
  final List<ViolationTypeStat> byType;
  final List<TopStudentStat> topStudents;

  const ExamSummary({
    required this.classroomId,
    required this.totalViolations,
    required this.byType,
    required this.topStudents,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> json) => ExamSummary(
    classroomId: json['classroom_id'] as int? ?? 0,
    totalViolations: json['total_violations'] as int,
    byType: (json['by_type'] as List)
        .map((e) => ViolationTypeStat.fromJson(e as Map<String, dynamic>))
        .toList(),
    topStudents: (json['top_students'] as List)
        .map((e) => TopStudentStat.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class ViolationEvent {
  final String type;
  final DateTime createdAt;

  const ViolationEvent({required this.type, required this.createdAt});

  factory ViolationEvent.fromJson(Map<String, dynamic> json) => ViolationEvent(
    type: json['type'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  String get displayName {
    switch (type) {
      case 'tab_switch':
        return 'Tab Switch';
      case 'window_blur':
        return 'Window Blur';
      case 'app_background':
        return 'App Backgrounded';
      case 'copy_paste':
        return 'Copy / Paste';
      case 'context_menu':
        return 'Context Menu';
      case 'fullscreen_exit':
        return 'Fullscreen Exit';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }
}

class StudentViolationDetail {
  final String studentName;
  final String risk;
  final List<ViolationEvent> violations;

  const StudentViolationDetail({
    required this.studentName,
    required this.risk,
    required this.violations,
  });

  factory StudentViolationDetail.fromJson(Map<String, dynamic> json) =>
      StudentViolationDetail(
        studentName: json['student_name'] as String,
        risk: json['risk'] as String,
        violations: (json['violations'] as List)
            .map((e) => ViolationEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
