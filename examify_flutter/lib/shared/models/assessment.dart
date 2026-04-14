import 'question.dart';
import 'student_attempt.dart';

class Assessment {
  final int id;
  final int classroomId;
  final String title;
  final String description;
  final String type; // 'exam', 'quiz', 'activity'
  final int timeLimitMinutes;
  final bool isPublished;
  final int weight;
  final bool showScore;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final int? courseOutcomeId;
  final Map<String, dynamic>? courseOutcome;
  final List<Question> questions;
  final List<StudentAttempt> attempts;

  Assessment({
    required this.id,
    required this.classroomId,
    required this.title,
    required this.description,
    required this.type,
    required this.timeLimitMinutes,
    this.isPublished = true,
    this.weight = 0,
    this.showScore = true,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.courseOutcomeId,
    this.courseOutcome,
    this.questions = const [],
    this.attempts = const [],
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int def = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? def;
      return def;
    }

    bool parseBool(dynamic val, [bool def = true]) {
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) return val == '1' || val.toLowerCase() == 'true';
      return def;
    }

    return Assessment(
      id: parseInt(json['id']),
      classroomId: parseInt(json['classroom_id'], 0),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'exam',
      timeLimitMinutes: parseInt(json['time_limit_minutes'], 60),
      isPublished: parseBool(json['is_published'], true),
      weight: parseInt(json['weight'], 0),
      showScore: parseBool(json['show_score'], true),
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'])
          : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      courseOutcomeId: parseInt(json['course_outcome_id']),
      courseOutcome: json['course_outcome'],
      questions:
          (json['questions'] as List?)
              ?.map((e) => Question.fromJson(e))
              .toList() ??
          [],
      attempts: (json['attempts'] as List?)
              ?.map((e) => StudentAttempt.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'title': title,
      'description': description,
      'type': type,
      'time_limit_minutes': timeLimitMinutes,
      'is_published': isPublished,
      'weight': weight,
      'show_score': showScore,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'course_outcome_id': courseOutcomeId,
      'course_outcome': courseOutcome,
      'questions': questions.map((e) => e.toJson()).toList(),
      'attempts': attempts.map((e) => e.toJson()).toList(),
    };
  }
}
