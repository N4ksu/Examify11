class StudentAttempt {
  final int id;
  final int assessmentId;
  final int studentId;
  final String status;
  final num? score;
  final DateTime? startedAt;
  final DateTime? completedAt;

  StudentAttempt({
    required this.id,
    required this.assessmentId,
    required this.studentId,
    required this.status,
    this.score,
    this.startedAt,
    this.completedAt,
  });

  factory StudentAttempt.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int def = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? def;
      return def;
    }

    num? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val;
      if (val is String) return num.tryParse(val);
      return null;
    }

    return StudentAttempt(
      id: parseInt(json['id']),
      assessmentId: parseInt(json['assessment_id'], 0),
      studentId: parseInt(json['student_id'], 0),
      status: json['status']?.toString() ?? 'unknown',
      score: parseNum(json['score']),
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'student_id': studentId,
      'status': status,
      'score': score,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
