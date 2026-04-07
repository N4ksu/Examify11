// lib/features/analytics/exam_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/exam_analytics.dart';
import 'providers/exam_analytics_provider.dart';
import 'widgets/violation_type_tile.dart';
import 'widgets/student_violation_bottom_sheet.dart';
import 'widgets/outcome_mastery_tab.dart';
import 'widgets/submissions_tab.dart';

class ExamAnalyticsScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamAnalyticsScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamAnalyticsScreen> createState() =>
      _ExamAnalyticsScreenState();
}

class _ExamAnalyticsScreenState extends ConsumerState<ExamAnalyticsScreen> {
  late int _examId;
  final Color primaryViolet = const Color(0xFF673AB7);
  final Color accentViolet = const Color(0xFFEDE7F6);

  @override
  void initState() {
    super.initState();
    _examId = int.parse(widget.examId);
  }

  void _openStudentSheet(TopStudentStat student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: primaryViolet,
          title: const Text(
            'Exam Report',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(examAnalyticsProvider(_examId)),
            ),
          ],
          bottom: TabBar(
            labelColor: primaryViolet,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryViolet,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Submissions'),
              Tab(text: 'Violations'),
              Tab(text: 'Mastery'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SubmissionsTab(examId: _examId),
            _buildViolationsTab(analytics),
            analytics.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (_) => OutcomeMasteryTab(examId: _examId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsTab(AsyncValue<ExamSummary> analytics) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(examAnalyticsProvider(_examId)),
      child: analytics.when(
        loading: () => _LoadingSkeleton(),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(examAnalyticsProvider(_examId)),
        ),
        data: (summary) => Column(
          children: [
            Expanded(
              child: _Dashboard(
                summary: summary,
                examId: _examId,
                onViewStudent: _openStudentSheet,
              ),
            ),
            // Footer Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 250, // Keep button from being too wide
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/assessment/$_examId/reports'),
                    icon: const Icon(Icons.list_alt_rounded, size: 18),
                    label: const Text('Full Proctoring Logs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryViolet,
                      side: BorderSide(color: primaryViolet),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // Responsive Centering
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(totalViolations: summary.totalViolations),
              const SizedBox(height: 24),
              if (summary.byType.isNotEmpty) ...[
                const _SectionTitle(
                  icon: Icons.analytics_outlined,
                  label: 'Violation Breakdown',
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
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
                const SizedBox(height: 24),
              ],
              const _SectionTitle(
                icon: Icons.people_outline,
                label: 'Student Oversight',
              ),
              const SizedBox(height: 12),
              if (summary.topStudents.isEmpty)
                const _EmptyState(
                  icon: Icons.verified_user_outlined,
                  message: 'No violations detected.',
                )
              else
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.topStudents.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, i) => _StudentTile(
                      student: summary.topStudents[i],
                      onView: () => onViewStudent(summary.topStudents[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF673AB7).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.security_rounded,
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
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Incident Alerts Detected',
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
  final TopStudentStat student;
  final VoidCallback onView;

  const _StudentTile({required this.student, required this.onView});

  @override
  Widget build(BuildContext context) {
    // Using a deep violet for maximum visibility on white
    const Color textPrimary = Color(0xFF311B92);
    const Color textSecondary = Color(0xFF616161);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEDE7F6),
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF673AB7),
          ),
        ),
      ),
      title: Text(
        student.name,
        style: const TextStyle(
          color: textPrimary, // Explicit dark color
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        '${student.violationCount} Violations',
        style: const TextStyle(
          color: textSecondary, // Visible grey
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: SizedBox(
        width: 80, // Fixed width to keep buttons uniform
        child: ElevatedButton(
          onPressed: onView,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF3E5F5),
            foregroundColor: const Color(0xFF673AB7),
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'View',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
