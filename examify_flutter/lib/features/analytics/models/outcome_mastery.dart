class StrugglingStudent {
  final int id;
  final String name;
  final double masteryPercentage;

  StrugglingStudent({
    required this.id,
    required this.name,
    required this.masteryPercentage,
  });

  factory StrugglingStudent.fromJson(Map<String, dynamic> json) {
    return StrugglingStudent(
      id: json['id'],
      name: json['name'],
      masteryPercentage: (json['mastery_percentage'] as num).toDouble(),
    );
  }
}

class OutcomeBreakdown {
  final int id;
  final String code;
  final String description;
  final int possiblePoints;
  final int earnedPoints;
  final double masteryPercentage;

  OutcomeBreakdown({
    required this.id,
    required this.code,
    required this.description,
    required this.possiblePoints,
    required this.earnedPoints,
    required this.masteryPercentage,
  });

  factory OutcomeBreakdown.fromJson(Map<String, dynamic> json) {
    return OutcomeBreakdown(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      possiblePoints: json['possible_points'],
      earnedPoints: json['earned_points'],
      masteryPercentage: (json['mastery_percentage'] as num).toDouble(),
    );
  }
}

class ExamOutcomeAnalytics {
  final double overallMastery;
  final String? lowestCo;
  final List<OutcomeBreakdown> breakdown;
  final List<StrugglingStudent> strugglingStudents;

  ExamOutcomeAnalytics({
    required this.overallMastery,
    this.lowestCo,
    required this.breakdown,
    required this.strugglingStudents,
  });

  factory ExamOutcomeAnalytics.fromJson(Map<String, dynamic> json) {
    return ExamOutcomeAnalytics(
      overallMastery: (json['overall_mastery'] as num).toDouble(),
      lowestCo: json['lowest_co'] as String?,
      breakdown: (json['breakdown'] as List<dynamic>)
          .map((item) => OutcomeBreakdown.fromJson(item))
          .toList(),
      strugglingStudents: (json['struggling_students'] as List<dynamic>)
          .map((item) => StrugglingStudent.fromJson(item))
          .toList(),
    );
  }
}
