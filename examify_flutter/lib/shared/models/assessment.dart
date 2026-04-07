import 'question.dart';

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
  final List<dynamic> attempts;

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
    return Assessment(
      id: json['id'],
      classroomId: json['classroom_id'] ?? 0,
      title: json['title'],
      description: json['description'] ?? '',
      type: json['type'] ?? 'exam',
      timeLimitMinutes: json['time_limit_minutes'] ?? 60,
      isPublished: json['is_published'] ?? true,
      weight: json['weight'] ?? 0,
      showScore: json['show_score'] ?? true,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'])
          : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      courseOutcomeId: json['course_outcome_id'],
      courseOutcome: json['course_outcome'],
      questions:
          (json['questions'] as List?)
              ?.map((e) => Question.fromJson(e))
              .toList() ??
          [],
      attempts: json['attempts'] ?? [],
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
      'attempts': attempts,
    };
  }
}
