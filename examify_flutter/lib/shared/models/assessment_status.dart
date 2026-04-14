import 'student_attempt.dart';

class AssessmentStatus {
  final StudentAttempt? attempt;
  final Map<String, dynamic>? request;

  AssessmentStatus({
    this.attempt,
    this.request,
  });

  factory AssessmentStatus.fromJson(Map<String, dynamic> json) {
    return AssessmentStatus(
      attempt: json['attempt'] != null ? StudentAttempt.fromJson(json['attempt']) : null,
      request: json['request'],
    );
  }
}
