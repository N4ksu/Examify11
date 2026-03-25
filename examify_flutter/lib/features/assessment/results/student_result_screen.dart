import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/assessment_provider.dart';

class StudentResultScreen extends ConsumerWidget {
  final String assessmentId;
  final int? attemptId;
  final Map<String, dynamic>? result;

  const StudentResultScreen({
    super.key,
    required this.assessmentId,
    this.attemptId,
    this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (result != null) {
      return _buildContent(context, result!);
    }

    if (attemptId == null) {
      return const Scaffold(body: Center(child: Text('Result not found')));
    }

    final resultAsync = ref.watch(studentResultProvider(attemptId!));

    return resultAsync.when(
      data: (data) => _buildContent(context, data),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final bool showScore = data['show_score'] ?? true;
    final score = data['score']?.toString();
    final total = data['total']?.toString() ?? '0';
    final percentage = data['percentage']?.toString();
    final List<dynamic>? questionsResults = data['questions_results'];

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
                if (showScore && questionsResults != null)
                  ...questionsResults.map((q) => _buildQuestionCard(context, q)),

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

  Widget _buildQuestionCard(BuildContext context, Map<String, dynamic> q) {
    final bool isEssay = q['type'] == 'essay';
    final bool isCorrect = q['is_correct'] ?? false;
    final String studentAnswer = q['student_response'] ?? 'No answer';

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
                  q['body'] ?? '',
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
          if (isEssay) ...[
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
}
