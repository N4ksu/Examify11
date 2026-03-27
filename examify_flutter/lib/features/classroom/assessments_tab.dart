import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';

import '../../shared/models/assessment.dart';
import '../../shared/providers/assessment_provider.dart';
import 'providers/assessment_status_provider.dart';
import 'widgets/retake_request_modal.dart';
import '../retake/providers/retake_request_provider.dart';

class AssessmentsTab extends ConsumerWidget {
  final String classroomId;
  const AssessmentsTab({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role.name == 'teacher';
    final assessmentsAsync = ref.watch(
      assessmentsProvider(int.parse(classroomId)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: assessmentsAsync.when(
        data: (assessments) {
          if (assessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No assessments yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final exams = assessments.where((a) => a.type == 'exam').toList();
          final quizzes = assessments.where((a) => a.type == 'quiz').toList();
          final activities = assessments
              .where((a) => a.type == 'activity')
              .toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(assessmentsProvider(int.parse(classroomId)).future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (exams.isNotEmpty) ...[
                  _buildAssignmentSection(context, 'Assessments'),
                  ...exams.map(
                    (a) => _buildAssessmentItem(context, ref, a, isTeacher),
                  ),
                  const SizedBox(height: 32),
                ],
                if (quizzes.isNotEmpty) ...[
                  _buildAssignmentSection(context, 'Quizzes'),
                  ...quizzes.map(
                    (a) => _buildAssessmentItem(context, ref, a, isTeacher),
                  ),
                  const SizedBox(height: 32),
                ],
                if (activities.isNotEmpty) ...[
                  _buildAssignmentSection(context, 'Activities'),
                  ...activities.map(
                    (a) => _buildAssessmentItem(context, ref, a, isTeacher),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/classroom/$classroomId/create-assessment'),
              backgroundColor: const Color(0xFF6E4CF5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAssessmentItem(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
    bool isTeacher,
  ) {
    if (isTeacher) {
      return _buildAssignmentItem(
        context,
        assessment.title,
        'Posted ${assessment.createdAt != null ? DateFormat('MMM d').format(assessment.createdAt!) : 'Recently'}',
        assessment.type == 'exam'
            ? Icons.assignment
            : Icons.assignment_turned_in,
        isTeacher: true,
        status: 'Manage',
        onTap: () => context.push('/assessment/${assessment.id}/reports'),
        onEdit: () => context.push(
          '/classrooms/$classroomId/assessments/${assessment.id}/edit',
        ),
        onDelete: () => _confirmDelete(context, ref, assessment),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final statusAsync = ref.watch(assessmentStatusProvider(assessment.id));
        final usedRetakesAsync = ref.watch(usedRetakesProvider(assessment.id));

        return statusAsync.when(
          data: (data) {
            final attempt = data['attempt'];
            final request = data['request'];

            return usedRetakesAsync.when(
              data: (usedRetakes) {
                const canRequestRetake = true;

                if (attempt == null) {
                  // Not taken yet
                  return _buildStartButton(context, assessment);
                }

                // Student has a submitted attempt
                if (request != null && request['status'] == 'pending') {
                  return _buildRequestPending(
                    context,
                    ref,
                    assessment,
                    attempt,
                  );
                } else if (request != null && request['status'] == 'approved') {
                  return _buildApprovedRetake(
                    context,
                    ref,
                    assessment,
                    attempt,
                  );
                } else {
                  if (attempt['status'] == 'in_progress') {
                    return _buildResumeButton(context, assessment, attempt);
                  }
                  return _buildCompleted(
                    context,
                    ref,
                    assessment,
                    attempt,
                    request?['status'],
                    canRequestRetake,
                    usedRetakes,
                  );
                }
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (err, stack) => _buildAssignmentItem(
                context,
                assessment.title,
                'Error loading retake status',
                Icons.error_outline,
                isTeacher: false,
                status: 'Error',
              ),
            );
          },
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (err, stack) => _buildAssignmentItem(
            context,
            assessment.title,
            'Error loading status',
            Icons.error_outline,
            isTeacher: false,
            status: 'Error',
          ),
        );
      },
    );
  }

  Widget _buildResumeButton(BuildContext context, Assessment assessment, dynamic attempt) {
    String subtitle = 'Currently in progress • Started ${_formatTime(attempt['started_at'])}';
    
    return _buildAssignmentItem(
      context,
      assessment.title,
      subtitle,
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'In Progress',
      onTap: () => _resumeExam(context, assessment.id, attempt['id']),
      onRetakeRequest: () => _resumeExam(context, assessment.id, attempt['id']),
      retakeLabel: 'Resume Exam',
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'Recently';
    try {
      final dateTime = DateTime.parse(timeStr);
      return DateFormat('h:mm a').format(dateTime.toLocal());
    } catch (e) {
      return 'Recently';
    }
  }

  void _resumeExam(BuildContext context, int assessmentId, int attemptId) async {
    // For now, resume just goes to take screen. 
    // We should ideally fetch the latest room name too if it's an exam.
    // But since the TakeAssessmentScreen handles it, we'll just push.
    context.push('/assessment/$assessmentId/take?attemptId=$attemptId');
  }

  Widget _buildStartButton(BuildContext context, Assessment assessment) {
    String subtitle =
        'Posted ${assessment.createdAt != null ? DateFormat('MMM d').format(assessment.createdAt!) : 'Recently'}';
    if (assessment.courseOutcome != null) {
      subtitle += ' • Outcome: ${assessment.courseOutcome!['code']}';
    }

    return _buildAssignmentItem(
      context,
      assessment.title,
      subtitle,
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Available',
      onTap: () => _startExam(context, assessment.id),
      onRetakeRequest: () => _startExam(context, assessment.id),
      retakeLabel: 'Start Exam',
    );
  }

  void _startExam(BuildContext context, int assessmentId, {bool isRetake = false}) async {
    if (isRetake) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start Retake Exam'),
          content: const Text(
            'You already have a completed attempt for this exam. Starting a retake will create a new attempt. Your previous score will remain, but this new attempt will replace your latest submission. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E4CF5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Retake'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    if (context.mounted) {
      context.push('/assessment/$assessmentId/consent');
    }
  }

  Widget _buildRequestPending(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
    dynamic attempt,
  ) {
    return _buildAssignmentItem(
      context,
      assessment.title,
      'Retake request is under review',
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Pending Retake',
      onTap: () => context.push('/attempts/${attempt['id']}/result'),
      onRetakeRequest: null, // Disabled while pending
      retakeLabel: 'Pending Request',
    );
  }

  Widget _buildApprovedRetake(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
    dynamic attempt,
  ) {
    return _buildAssignmentItem(
      context,
      assessment.title,
      'Teacher approved your retake. Click to start.',
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Retake Approved',
      onTap: () => _startExam(context, assessment.id, isRetake: true),
      onRetakeRequest: () =>
          _startExam(context, assessment.id, isRetake: true),
      retakeLabel: 'Start Retake',
    );
  }

  Widget _buildCompleted(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
    dynamic attempt,
    String? requestStatus,
    bool canRequestRetake,
    int usedRetakes,
  ) {
    final score = attempt['score'];
    String subtitle =
        'Score: $score / ${_totalPoints(assessment)} • Completed${requestStatus == 'denied' ? ' (Retake Denied)' : ''}';

    return _buildAssignmentItem(
      context,
      assessment.title,
      subtitle,
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Completed',
      isCompleted: true,
      onTap: () => context.push('/attempts/${attempt['id']}/result'),
      onRetakeRequest:
          (canRequestRetake &&
              (requestStatus == null ||
                  requestStatus == 'used' ||
                  requestStatus == 'denied'))
          ? () => _requestRetake(context, ref, assessment.id)
          : null,
      retakeLabel: 'Request Retake',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: Text('Are you sure you want to delete "${assessment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(apiClientProvider)
            .delete('/assessments/${assessment.id}');
        ref.invalidate(assessmentsProvider(int.parse(classroomId)));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Assessment deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Widget _buildAssignmentSection(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6E4CF5), // Violet section title
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFFE8EAED), thickness: 1, height: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  void _requestRetake(BuildContext context, WidgetRef ref, int assessmentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RetakeRequestModal(assessmentId: assessmentId),
    );
  }

  int _totalPoints(Assessment assessment) {
    return assessment.questions.fold(0, (sum, q) => sum + q.points);
  }

  Widget _buildAssignmentItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    required bool isTeacher,
    String? status,
    bool isCompleted = false,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onRetakeRequest,
    String? retakeLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6E4CF5).withValues(alpha: 0.1),
                  child: Icon(icon, color: const Color(0xFF6E4CF5), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF3C4043),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 8),
                  if (!isTeacher && isCompleted)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View Result',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6E4CF5),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E4CF5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF6E4CF5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                const SizedBox(width: 8),
                if (isTeacher)
                  PopupMenuButton<String>(
                    iconColor: const Color(0xFF5F6368),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  )
                else if (onRetakeRequest != null)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Color(0xFF5F6368),
                    ),
                    onSelected: (value) {
                      if (value == 'retake') {
                        onRetakeRequest();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'retake',
                        child: Text(
                          retakeLabel ??
                              (status == 'Retake Approved' ||
                                      status == 'Available'
                                  ? 'Start Exam'
                                  : 'Retake Exam'),
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 40), // Empty space to keep alignment
              ],
            ),
          ),
        ),
      ),
    );
  }
}
