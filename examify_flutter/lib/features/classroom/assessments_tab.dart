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
  final bool isMobile;
  const AssessmentsTab({
    super.key,
    required this.classroomId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final isTeacher = user?.role.name == 'teacher';
    final assessmentsAsync = ref.watch(
      assessmentsProvider(int.parse(classroomId)),
    );

    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: assessmentsAsync.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
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
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (exams.isNotEmpty) ...[
                        _buildAssignmentSection(context, 'Assessments', isMobile: isMobile),
                        ...exams.map((a) => _buildAssessmentItem(context, ref, a, isTeacher, isMobile: isMobile)),
                        const SizedBox(height: 24),
                      ],
                      if (quizzes.isNotEmpty) ...[
                        _buildAssignmentSection(context, 'Quizzes', isMobile: isMobile),
                        ...quizzes.map((a) => _buildAssessmentItem(context, ref, a, isTeacher, isMobile: isMobile)),
                        const SizedBox(height: 24),
                      ],
                      if (activities.isNotEmpty) ...[
                        _buildAssignmentSection(context, 'Activities', isMobile: isMobile),
                        ...activities.map((a) => _buildAssessmentItem(context, ref, a, isTeacher, isMobile: isMobile)),
                        const SizedBox(height: 24),
                      ],
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 64)),
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
    bool isTeacher, {
    bool isMobile = false,
  }) {
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
        isMobile: isMobile,
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
                  return _buildStartButton(context, assessment, isMobile: isMobile);
                }

                // Student has a submitted attempt
                if (request != null && request['status'] == 'pending') {
                  return _buildRequestPending(
                    context,
                    ref,
                    assessment,
                    attempt,
                    isMobile: isMobile,
                  );
                } else if (request != null && request['status'] == 'approved') {
                  return _buildApprovedRetake(
                    context,
                    ref,
                    assessment,
                    attempt,
                    isMobile: isMobile,
                  );
                } else {
                  if (attempt['status'] == 'in_progress') {
                    return _buildResumeButton(context, assessment, attempt, isMobile: isMobile);
                  }
                  return _buildCompleted(
                    context,
                    ref,
                    assessment,
                    attempt,
                    request?['status'],
                    canRequestRetake,
                    usedRetakes,
                    isMobile: isMobile,
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
                isMobile: isMobile,
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
            isMobile: isMobile,
          ),
        );
      },
    );
  }

  Widget _buildResumeButton(BuildContext context, Assessment assessment, dynamic attempt, {bool isMobile = false}) {
    String subtitle = 'In progress • Started ${_formatTime(attempt['started_at'])}';
    
    return _buildAssignmentItem(
      context,
      assessment.title,
      subtitle,
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'In Progress',
      isMobile: isMobile,
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

  Widget _buildStartButton(BuildContext context, Assessment assessment, {bool isMobile = false}) {
    String subtitle =
        'Posted ${assessment.createdAt != null ? DateFormat('MMM d').format(assessment.createdAt!) : 'Recently'}';
    if (assessment.courseOutcome != null) {
      subtitle += ' • ${assessment.courseOutcome!['code']}';
    }

    return _buildAssignmentItem(
      context,
      assessment.title,
      subtitle,
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Available',
      isMobile: isMobile,
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
    dynamic attempt, {
    bool isMobile = false,
  }) {
    return _buildAssignmentItem(
      context,
      assessment.title,
      'Retake request is under review',
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Pending',
      isMobile: isMobile,
      onTap: () => context.push('/attempts/${attempt['id']}/result'),
      onRetakeRequest: null,
      retakeLabel: 'Pending Request',
    );
  }

  Widget _buildApprovedRetake(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
    dynamic attempt, {
    bool isMobile = false,
  }) {
    return _buildAssignmentItem(
      context,
      assessment.title,
      'Teacher approved your retake.',
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Retake',
      isMobile: isMobile,
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
    int usedRetakes, {
    bool isMobile = false,
  }) {
    final score = attempt['score'];
    String subtitle =
        'Score: $score / ${_totalPoints(assessment)}${requestStatus == 'denied' ? ' • Denied' : ''}';

    return _buildAssignmentItem(
      context,
      assessment.title,
      subtitle,
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: false,
      status: 'Done',
      isCompleted: true,
      isMobile: isMobile,
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

  Widget _buildAssignmentSection(BuildContext context, String title, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF6E4CF5),
            fontSize: isMobile ? 20 : 24,
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
    bool isMobile = false,
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
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 18 : 20,
                  backgroundColor: const Color(0xFF6E4CF5).withValues(alpha: 0.1),
                  child: Icon(icon, color: const Color(0xFF6E4CF5), size: isMobile ? 18 : 22),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF3C4043),
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF5F6368),
                          fontSize: isMobile ? 12 : 13,
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
                        Text(
                          isMobile ? 'Done' : 'Completed',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isMobile ? 'View' : 'View Result',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6E4CF5),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E4CF5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: const Color(0xFF6E4CF5),
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                const SizedBox(width: 4),
                if (isTeacher)
                  PopupMenuButton<String>(
                    iconSize: 20,
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
                else if (!isMobile)
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
