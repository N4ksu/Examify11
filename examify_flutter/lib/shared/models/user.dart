enum UserRole { teacher, student }

class User {
  final int id;
  final String name;
  final String? email;
  final UserRole role;
  final String? studentId;
  final String? teacherId;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.studentId,
    this.teacherId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Unknown User',
      email: json['email'],
      role: (json['role'] ?? 'student') == 'teacher'
          ? UserRole.teacher
          : UserRole.student,
      studentId: json['student_id'],
      teacherId: json['teacher_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role == UserRole.teacher ? 'teacher' : 'student',
      'student_id': studentId,
      'teacher_id': teacherId,
    };
  }
}
