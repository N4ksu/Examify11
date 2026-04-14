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
    int parseInt(dynamic val, [int def = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? def;
      return def;
    }

    return Question(
      id: parseInt(json['id']),
      assessmentId: parseInt(json['assessment_id'], 0),
      body: json['body']?.toString() ?? json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'multiple_choice',
      points: parseInt(json['points'], 1),
      order: parseInt(json['order'], 0),
      scoringMethod: json['scoring_method']?.toString() ?? 'exact',
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
    
    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) return val == '1' || val.toLowerCase() == 'true';
      return false;
    }

    return Option(
      id: parseInt(json['id']),
      body: json['body']?.toString() ?? '',
      isCorrect: parseBool(json['is_correct']),
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
