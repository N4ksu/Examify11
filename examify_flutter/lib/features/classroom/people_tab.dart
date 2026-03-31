import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/classroom_provider.dart';
import '../../shared/providers/auth_provider.dart';

class PeopleTab extends ConsumerWidget {
  final String classroomId;
  const PeopleTab({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(classroomStudentsProvider(classroomId));
    final classroomAsync = ref.watch(classroomDetailProvider(classroomId));
    final user = ref.watch(authProvider.select((state) => state.user));
    final isTeacher = user?.role.name == 'teacher';

    return Scaffold(
      backgroundColor: Colors.white,
      body: classroomAsync.when(
        data: (classroom) => studentsAsync.when(
          data: (students) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(classroomStudentsProvider(classroomId));
              ref.invalidate(classroomDetailProvider(classroomId));
              await ref.read(classroomStudentsProvider(classroomId).future);
              await ref.read(classroomDetailProvider(classroomId).future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              itemCount: 4 + students.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSectionHeader(
                    context,
                    'Teachers',
                    Icons.person_add_alt_1,
                    showIcon: isTeacher,
                  );
                }
                if (index == 1) {
                  return _buildPersonRow(
                    context,
                    classroom.teacher?.name ?? 'Teacher',
                    isTeacher: true,
                  );
                }
                if (index == 2) return const SizedBox(height: 32);
                if (index == 3) {
                  return _buildSectionHeader(
                    context,
                    'Students',
                    Icons.person_add_alt_1,
                    count: students.length,
                    showIcon: isTeacher,
                  );
                }
                return _buildPersonRow(context, students[index - 4].name);
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error students: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error classroom: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    int? count,
    bool showIcon = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6E4CF5), // Google Blue
                fontSize: 28,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (count != null)
              Text(
                '$count students',
                style: const TextStyle(
                  color: Color(0xFF5F6368),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (showIcon) ...[
              const SizedBox(width: 16),
              Icon(icon, color: const Color(0xFF6E4CF5)),
            ],
          ],
        ),
        const Divider(color: Color(0xFF6E4CF5), thickness: 1),
      ],
    );
  }

  Widget _buildPersonRow(
    BuildContext context,
    String name, {
    bool isTeacher = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1A2535), // Dark blue/grey circle
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            name,
            style: const TextStyle(color: Color(0xFF3C4043), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
