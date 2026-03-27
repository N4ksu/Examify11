import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/wizard_bottom_nav.dart';

class ReviewAssessmentScreen extends ConsumerStatefulWidget {
  final String assessmentId;
  final String classroomId;
  const ReviewAssessmentScreen({
    super.key,
    required this.assessmentId,
    required this.classroomId,
  });

  @override
  ConsumerState<ReviewAssessmentScreen> createState() =>
      _ReviewAssessmentScreenState();
}

class _ReviewAssessmentScreenState
    extends ConsumerState<ReviewAssessmentScreen> {
  bool _isFinalizing = false;

  Future<void> _finalize() async {
    setState(() => _isFinalizing = true);
    try {
      final id = int.parse(widget.assessmentId);
      final api = ref.read(apiClientProvider);

      // Validation: ensure at least one question exists
      final questions = await ref.read(questionsProvider(id).future);
      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot assign an exam with no questions.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _isFinalizing = false);
        }
        return;
      }

      // Update is_published to true to "Assign" the exam
      await api.patch('/assessments/$id', data: {'is_published': true});

      if (mounted) {
        // Find the classroomId to navigate back correctly
        final assessment = await ref.read(assessmentDetailProvider(id).future);
        ref.invalidate(assessmentsProvider(assessment.classroomId));

        if (mounted) {
          // Navigate back to classroom detail and clear wizard stack
          context.go('/classroom/${assessment.classroomId}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exam assigned successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to assign exam: $e')));
        setState(() => _isFinalizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = int.parse(widget.assessmentId);
    final assessmentAsync = ref.watch(assessmentDetailProvider(id));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Review Assessment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6E4CF5),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: assessmentAsync.when(
              data: (assessment) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('General Information'),
                          _buildInfoCard([
                            _buildInfoRow('Title', assessment.title),
                            _buildInfoRow(
                              'Description',
                              assessment.description.isEmpty
                                  ? 'No description'
                                  : assessment.description,
                            ),
                            _buildInfoRow(
                              'Time Limit',
                              '${assessment.timeLimitMinutes} minutes',
                            ),
                            _buildInfoRow(
                              'Show Score',
                              assessment.showScore ? 'Yes' : 'No',
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildSectionHeader('Questions Summary'),
                          _buildQuestionsList(id),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          WizardBottomNav(
            currentStep: 3,
            onBack: () => context.pop(),
            onNext: _isFinalizing ? null : _finalize,
            onStepTap: (step) {
              if (step == 1) {
                context.push(
                  '/classrooms/${widget.classroomId}/assessments/${widget.assessmentId}/edit',
                );
              } else if (step == 2) {
                context.push(
                  '/classrooms/${widget.classroomId}/assessments/${widget.assessmentId}/manage-questions',
                );
              }
            },
            nextText: 'Assign',
            isNextLoading: _isFinalizing,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(int assessmentId) {
    return Consumer(
      builder: (context, ref, child) {
        final questionsAsync = ref.watch(questionsProvider(assessmentId));
        return questionsAsync.when(
          data: (questions) {
            if (questions.isEmpty) {
              return const Text(
                'No questions added yet.',
                style: TextStyle(fontStyle: FontStyle.italic),
              );
            }

            final totalPoints = questions.fold<int>(
              0,
              (sum, q) => sum + q.points,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${questions.length} questions ($totalPoints points)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E4CF5),
                  ),
                ),
                const SizedBox(height: 16),
                ...questions.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final q = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 207, 207, 207),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromARGB(255, 5, 5, 5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Q$idx',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q.type.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${q.points} pts',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Error loading questions'),
        );
      },
    );
  }
}
