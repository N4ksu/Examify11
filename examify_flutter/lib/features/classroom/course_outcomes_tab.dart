import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/course_outcomes_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class CourseOutcomesTab extends ConsumerWidget {
  final String classroomId;

  const CourseOutcomesTab({super.key, required this.classroomId});

  void _showAddEditDialog(BuildContext context, WidgetRef ref, {int? id, String? initialCode, String? initialDesc}) {
    final codeController = TextEditingController(text: initialCode);
    final descController = TextEditingController(text: initialDesc);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(id == null ? 'Add Course Outcome' : 'Edit Course Outcome'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: codeController,
                    label: 'Code (e.g. CO1)',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: descController,
                    label: 'Description',
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  text: 'Save',
                  isLoading: isSaving,
                  onPressed: isSaving ? null : () async {
                    if (codeController.text.trim().isEmpty || descController.text.trim().isEmpty) return;
                    setState(() => isSaving = true);
                    final actions = CourseOutcomeActions(ref, int.parse(classroomId));
                    try {
                      if (id == null) {
                        await actions.addOutcome(codeController.text, descController.text);
                      } else {
                        await actions.updateOutcome(id, codeController.text, descController.text);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outcome?'),
        content: const Text('Are you sure you want to delete this course outcome?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await CourseOutcomeActions(ref, int.parse(classroomId)).deleteOutcome(id);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcomesAsync = ref.watch(courseOutcomesProvider(int.parse(classroomId)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(courseOutcomesProvider(int.parse(classroomId)));
      },
      child: outcomesAsync.when(
        data: (outcomes) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Course Outcomes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2A3954),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(context, ref),
                      icon: const Icon(Icons.add, size: 20, color: Colors.white),
                      label: const Text('Add CO', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E44AD),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (outcomes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No course outcomes added yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ),
                ...outcomes.map((co) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8E44AD).withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E44AD).withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E44AD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          co.code,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8E44AD)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          co.description,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF2A3954)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF64748B), size: 20),
                        onPressed: () => _showAddEditDialog(context, ref, id: co.id, initialCode: co.code, initialDesc: co.description),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => _confirmDelete(context, ref, co.id),
                      ),
                    ],
                  ),
                ))
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8E44AD))),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
