class Question {
  final int id;
  final int assessmentId;
  final String body;
  final String type; // multiple_choice, true_false, essay, multiple_select
  final int points;
  final int order;
  final String scoringMethod; // 'exact' or 'partial'
  final List<Option> options;

  Question({
    required this.id,
    required this.assessmentId,
    required this.body,
    required this.type,
    required this.points,
    required this.order,
    this.scoringMethod = 'exact',
    this.options = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      assessmentId: json['assessment_id'] ?? 0,
      body: json['body'] ?? json['text'] ?? '',
      type: json['type'] ?? 'multiple_choice',
      points: json['points'] ?? 1,
      order: json['order'] ?? 0,
      scoringMethod: json['scoring_method'] ?? 'exact',
      options:
          (json['options'] as List?)?.map((o) => Option.fromJson(o)).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'body': body,
      'type': type,
      'points': points,
      'order': order,
      'scoring_method': scoringMethod,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  bool get isMcq => type == 'multiple_choice';
  bool get isMultipleSelect => type == 'multiple_select';
  bool get isTrueFalse => type == 'true_false';
  bool get isEssay => type == 'essay';
}

class Option {
  final int? id;
  final String body;
  final bool isCorrect;

  Option({this.id, required this.body, this.isCorrect = false});

  factory Option.fromJson(dynamic json) {
    if (json is String) {
      return Option(body: json);
    }
    return Option(
      id: json['id'],
      body: json['body'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'body': body,
      'is_correct': isCorrect,
    };
  }
}
