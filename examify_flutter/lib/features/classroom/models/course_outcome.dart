class CourseOutcome {
  final int id;
  final int classroomId;
  final String code;
  final String description;

  CourseOutcome({
    required this.id,
    required this.classroomId,
    required this.code,
    required this.description,
  });

  factory CourseOutcome.fromJson(Map<String, dynamic> json) {
    return CourseOutcome(
      id: json['id'],
      classroomId: json['classroom_id'],
      code: json['code'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'code': code,
      'description': description,
    };
  }

  CourseOutcome copyWith({
    int? id,
    int? classroomId,
    String? code,
    String? description,
  }) {
    return CourseOutcome(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      code: code ?? this.code,
      description: description ?? this.description,
    );
  }
}
