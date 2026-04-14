import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/student_result.dart';

class StudentResultScreen extends ConsumerWidget {
  final String assessmentId;
  final int? attemptId;
  final StudentResult? result;

  const StudentResultScreen({
    super.key,
    required this.assessmentId,
    this.attemptId,
    this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (result != null) {
      return _buildContent(context, ref, result!);
    }

    if (attemptId == null) {
      return const Scaffold(body: Center(child: Text('Result not found')));
    }

    final resultAsync = ref.watch(studentResultProvider(attemptId!));

    return resultAsync.when(
      data: (data) => _buildContent(context, ref, data),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, StudentResult data) {
    final bool showScore = data.showScore;
    final score = data.score?.toString();
    final total = data.total.toString();
    final percentage = data.percentage?.toString();
    final List<QuestionResult> questionsResults = data.questionsResults;
    final user = ref.watch(authProvider).user;
    final bool isTeacher = user?.role == UserRole.teacher;

    const Color primaryViolet = Color(0xFF6200EE);
    const Color scoreCardBg = Color(0xFFF5F3FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Exam Results'),
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Score Card
                if (showScore && score != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scoreCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryViolet,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$score / $total',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        if (percentage != null)
                          Text(
                            '($percentage%)',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scoreCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Your exam has been submitted. You will receive your results later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),

                // Detailed Results
                if (questionsResults.isNotEmpty)
                  ...questionsResults.map(
                    (q) => _buildQuestionCard(context, ref, q, isTeacher),
                  ),

                const SizedBox(height: 32),

                // Return Button - Responsive width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Return to Dashboard',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    WidgetRef ref,
    QuestionResult q,
    bool isTeacher,
  ) {
    final bool isEssay = q.type == 'essay';
    final bool isCorrect = q.isCorrect;
    final String studentAnswer = q.studentResponse;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.body,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!isEssay)
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your answer: $studentAnswer',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          if (isTeacher) ...[
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                const Text(
                  'Teacher Override:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _setOverride(context, ref, q.id, true),
                  icon: const Icon(Icons.check, size: 16, color: Colors.green),
                  label: const Text('Correct', style: TextStyle(color: Colors.green)),
                ),
                TextButton.icon(
                  onPressed: () => _setOverride(context, ref, q.id, false),
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text('Incorrect', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
          if (isEssay && !isTeacher) ...[
            const SizedBox(height: 8),
            const Text(
              'Awaiting Grading',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _setOverride(
    BuildContext context,
    WidgetRef ref,
    int questionId,
    bool isCorrect,
  ) async {
    if (attemptId == null) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.post('/attempts/$attemptId/override-answer', data: {
        'question_id': questionId,
        'teacher_override': isCorrect,
      });

      // Invalidate both the provider and potentially any related analytics
      ref.invalidate(studentResultProvider(attemptId!));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Question marked as ${isCorrect ? 'Correct' : 'Incorrect'}',
            ),
            backgroundColor: isCorrect ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update grade: $e')),
        );
      }
    }
  }
}
