class QuestionResult {
  final int id;
  final String type;
  final bool isCorrect;
  final String studentResponse;
  final String body;

  QuestionResult({
    required this.id,
    required this.type,
    required this.isCorrect,
    required this.studentResponse,
    required this.body,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int def = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? def;
      return def;
    }

    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) return val == '1' || val.toLowerCase() == 'true';
      return false;
    }

    return QuestionResult(
      id: parseInt(json['id']),
      type: json['type']?.toString() ?? 'unknown',
      isCorrect: parseBool(json['is_correct']),
      studentResponse: json['student_response']?.toString() ?? 'No answer',
      body: json['body']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'is_correct': isCorrect,
      'student_response': studentResponse,
      'body': body,
    };
  }
}

class StudentResult {
  final bool showScore;
  final num? score;
  final num total;
  final num? percentage;
  final List<QuestionResult> questionsResults;

  StudentResult({
    required this.showScore,
    this.score,
    required this.total,
    this.percentage,
    required this.questionsResults,
  });

  factory StudentResult.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val;
      if (val is String) return num.tryParse(val);
      return null;
    }

    bool parseBool(dynamic val, [bool def = true]) {
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) return val == '1' || val.toLowerCase() == 'true';
      return def;
    }

    return StudentResult(
      showScore: parseBool(json['show_score'], true),
      score: parseNum(json['score']),
      total: parseNum(json['total']) ?? 0,
      percentage: parseNum(json['percentage']),
      questionsResults: (json['questions_results'] as List?)
              ?.map((q) => QuestionResult.fromJson(q))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_score': showScore,
      'score': score,
      'total': total,
      'percentage': percentage,
      'questions_results': questionsResults.map((e) => e.toJson()).toList(),
    };
  }
}
