import 'user.dart';

class Classroom {
  final int id;
  final String name;
  final String joinCode;
  final bool isMeetingActive;
  final String? description;
  final User? teacher;
  final int? studentsCount;

  Classroom({
    required this.id,
    required this.name,
    required this.joinCode,
    this.isMeetingActive = false,
    this.description,
    this.teacher,
    this.studentsCount,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'],
      name: json['name'],
      joinCode: json['join_code'] ?? '',
      isMeetingActive:
          json['is_meeting_active'] == 1 || json['is_meeting_active'] == true,
      description: json['description'],
      teacher: json['teacher'] != null ? User.fromJson(json['teacher']) : null,
      studentsCount: json['students_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'join_code': joinCode,
      'is_meeting_active': isMeetingActive,
      'description': description,
      'teacher': teacher?.toJson(),
      'students_count': studentsCount,
    };
  }
}
