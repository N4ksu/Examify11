import 'user.dart';

class Announcement {
  final int id;
  final int classroomId;
  final int teacherId;
  final String title;
  final String body;
  final DateTime createdAt;
  final User? teacher;

  Announcement({
    required this.id,
    required this.classroomId,
    required this.teacherId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.teacher,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      classroomId: json['classroom_id'],
      teacherId: json['teacher_id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      teacher: json['teacher'] != null ? User.fromJson(json['teacher']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'teacher_id': teacherId,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
