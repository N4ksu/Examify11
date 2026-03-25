// lib/features/analytics/exam_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/exam_analytics.dart';
import 'providers/exam_analytics_provider.dart';
import 'widgets/violation_type_tile.dart';
import 'widgets/student_violation_bottom_sheet.dart';
import 'widgets/outcome_mastery_tab.dart';

class ExamAnalyticsScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamAnalyticsScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamAnalyticsScreen> createState() =>
      _ExamAnalyticsScreenState();
}

class _ExamAnalyticsScreenState extends ConsumerState<ExamAnalyticsScreen> {
  late int _examId;

  @override
  void initState() {
    super.initState();
    _examId = int.parse(widget.examId);
  }

  void _openStudentSheet(TopStudentStat student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StudentViolationBottomSheet(
        studentName: student.name,
        attemptId: student.attemptId,
        reportEndpoint: '/assessments/$_examId/proctoring-report',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(examAnalyticsProvider(_examId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(examAnalyticsProvider(_examId)),
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Proctoring'),
            Tab(text: 'Mastery'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          // Tab 1: Proctoring Dashboard
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(examAnalyticsProvider(_examId)),
            child: analytics.when(
              loading: () => _LoadingSkeleton(),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(examAnalyticsProvider(_examId)),
              ),
              data: (summary) => _Dashboard(
                summary: summary,
                examId: _examId,
                onViewStudent: _openStudentSheet,
              ),
            ),
          ),
          
          // Tab 2: Mastery Analytics
          analytics.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading mastery data: $err')),
            data: (_) {
              return OutcomeMasteryTab(examId: _examId);
            },
          ),
        ],
      ),
    ));
  }
}

// ──────────────────────────────────────────────
//  Loading skeleton
// ──────────────────────────────────────────────
class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _shimmer(context, height: 100),
          const SizedBox(height: 16),
          _shimmer(context, height: 200),
          const SizedBox(height: 16),
          _shimmer(context, height: 280),
        ],
      ),
    );
  }

  Widget _shimmer(BuildContext context, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Error state
// ──────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Main dashboard content
// ──────────────────────────────────────────────
class _Dashboard extends StatelessWidget {
  final ExamSummary summary;
  final int examId;
  final void Function(TopStudentStat) onViewStudent;

  const _Dashboard({
    required this.summary,
    required this.examId,
    required this.onViewStudent,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Total Violations card
          _SummaryCard(totalViolations: summary.totalViolations),
          const SizedBox(height: 16),

          // ── Violation Breakdown
          if (summary.byType.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.bar_chart_rounded,
              label: 'Violation Breakdown',
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: summary.byType
                      .map(
                        (s) => ViolationTypeTile(
                          stat: s,
                          totalViolations: summary.totalViolations,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Top Students
          _SectionTitle(
            icon: Icons.emoji_events_outlined,
            label: 'Top Students · Most Violations',
          ),
          const SizedBox(height: 8),
          if (summary.topStudents.isEmpty)
            _EmptyState(
              icon: Icons.check_circle_outline,
              message: 'No violations recorded for this exam.',
            )
          else
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summary.topStudents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = summary.topStudents[i];
                  return _StudentTile(
                    rank: i + 1,
                    student: s,
                    onView: () => onViewStudent(s),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Summary card (total violations)
// ──────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int totalViolations;

  const _SummaryCard({required this.totalViolations});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.red.withOpacity(.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalViolations',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const Text(
                  'Total Violations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Section title row
// ──────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
//  Student row tile
// ──────────────────────────────────────────────
class _StudentTile extends StatelessWidget {
  final int rank;
  final TopStudentStat student;
  final VoidCallback onView;

  const _StudentTile({
    required this.rank,
    required this.student,
    required this.onView,
  });

  Color _riskColor(int count) {
    if (count >= 5) return Colors.red;
    if (count >= 3) return Colors.orange;
    return Colors.green;
  }

  String _riskLabel(int count) {
    if (count >= 5) return 'High';
    if (count >= 3) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(student.violationCount);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        student.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_riskLabel(student.violationCount)} Risk',
              style: TextStyle(
                fontSize: 11,
                color: riskColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              '${student.violationCount}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: riskColor,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onView, child: const Text('View')),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Empty state
// ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
