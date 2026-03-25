import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/course_outcome.dart';

final courseOutcomesProvider = FutureProvider.family<List<CourseOutcome>, int>((ref, classroomId) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/classrooms/$classroomId/course-outcomes');
  final List<dynamic> data = response.data;
  return data.map((json) => CourseOutcome.fromJson(json)).toList();
});

class CourseOutcomeActions {
  final WidgetRef ref;
  final int classroomId;
  CourseOutcomeActions(this.ref, this.classroomId);

  Future<void> addOutcome(String code, String description) async {
    await ref.read(apiClientProvider).post('/classrooms/$classroomId/course-outcomes', data: {
      'code': code,
      'description': description,
    });
    ref.invalidate(courseOutcomesProvider(classroomId));
  }

  Future<void> updateOutcome(int id, String code, String description) async {
    await ref.read(apiClientProvider).patch('/course-outcomes/$id', data: {
      'code': code,
      'description': description,
    });
    ref.invalidate(courseOutcomesProvider(classroomId));
  }

  Future<void> deleteOutcome(int id) async {
    await ref.read(apiClientProvider).delete('/course-outcomes/$id');
    ref.invalidate(courseOutcomesProvider(classroomId));
  }
}
