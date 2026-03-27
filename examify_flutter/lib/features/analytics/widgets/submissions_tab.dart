import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../teacher_essentials/data/teacher_essentials_service.dart';

class SubmissionsTab extends ConsumerWidget {
  final int examId;

  const SubmissionsTab({super.key, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(teacherResultsProvider(examId));
    final isWide = MediaQuery.of(context).size.width > 700;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherResultsProvider(examId));
      },
      child: resultsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E4CF5)),
        ),
        error: (e, stack) => _buildErrorState(context, e, ref),
        data: (results) {
          if (results.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No submissions yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Sort by submitted_at desc
          final sortedResults = List<Map<String, dynamic>>.from(results)
            ..sort((a, b) {
              final dateA = a['submitted_at'];
              final dateB = b['submitted_at'];
              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;
              return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
            });

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 24,
            ),
            itemCount: sortedResults.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final attempt = sortedResults[i];
              return _SubmissionTile(
                examId: examId,
                attempt: attempt,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object e, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load submissions:\n$e',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(teacherResultsProvider(examId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final int examId;
  final Map<String, dynamic> attempt;

  const _SubmissionTile({
    required this.examId,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    final student = attempt['student'];
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final score = attempt['score'] ?? 0;
    final total = attempt['total'] ?? 0;
    final status = attempt['status'] ?? 'pending';
    final bool isCompleted = status == 'submitted' || status == 'auto_submitted';
    final String submittedAtStr = attempt['submitted_at'] ?? '';
    
    String dateText = 'Not Submitted';
    if (submittedAtStr.isNotEmpty) {
      final date = DateTime.tryParse(submittedAtStr);
      if (date != null) {
        dateText = DateFormat('MMM dd, yyyy \u2022 hh:mm a').format(date.toLocal());
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isCompleted
              ? () => context.push('/attempts/${attempt['id'] ?? 0}/result')
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6E4CF5).withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF6E4CF5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F3E58),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF71819C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCompleted ? 'Submitted: $dateText' : 'Status: In Progress / Not Submitted',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F3E58),
                            ),
                          ),
                          Text(
                            ' / $total',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF71819C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => context.push('/attempts/${attempt['id'] ?? 0}/result'),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: const Color(0xFF6E4CF5).withValues(alpha: 0.08),
                          foregroundColor: const Color(0xFF6E4CF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'View Answers',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
