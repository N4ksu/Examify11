// lib/features/analytics/widgets/global_analytics_section.dart
//
// A self-contained scrollable analytics section that shows:
//  • 4 stat tiles (classrooms, students, exams, violations)
//  • Violation Breakdown using fl_chart BarChart (fallback: LinearProgressIndicator)
//  • Top Offenders list with risk badges
//  • Exam selector dropdown (PopupMenuButton) to drill into a specific exam
//
// Designed to match the teacher dashboard's color palette.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/exam_analytics.dart';
import '../providers/global_analytics_provider.dart';
import 'student_violation_bottom_sheet.dart';

class GlobalAnalyticsSection extends ConsumerStatefulWidget {
  const GlobalAnalyticsSection({super.key});

  @override
  ConsumerState<GlobalAnalyticsSection> createState() =>
      _GlobalAnalyticsSectionState();
}

class _GlobalAnalyticsSectionState extends ConsumerState<GlobalAnalyticsSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Currently selected exam from dropdown (null = global view)
  AssessmentOption? _selectedExam;

  void _openStudentSheet(TopStudentStat student, String endpoint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StudentViolationBottomSheet(
        studentName: student.name,
        attemptId: student.attemptId,
        reportEndpoint: endpoint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by KeepAlive mixin
    final analytics = ref.watch(globalAnalyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _buildSectionHeader(context, analytics),
        const SizedBox(height: 16),
        analytics.when(
          loading: () => _buildLoadingShimmer(context),
          error: (e, _) => _buildError(context, e),
          data: (data) => _buildDashboard(context, data),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Section Header with Exam Dropdown
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context,
    AsyncValue<GlobalAnalytics> analytics,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6E4CF5), Color(0xFF47A2FF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics Overview',
                style: TextStyle(
                  color: Color(0xFF24364E),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _selectedExam == null
                    ? 'Across all classrooms'
                    : '${_selectedExam!.title}  ·  ${_selectedExam!.classroomName}',
                style: const TextStyle(
                  color: Color(0xFF8B98AE),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Exam dropdown
        analytics.maybeWhen(
          data: (data) => _buildExamDropdown(context, data),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        // Refresh
        InkWell(
          onTap: () => ref.invalidate(globalAnalyticsProvider),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.refresh_rounded,
              color: Color(0xFF6E4CF5),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamDropdown(BuildContext context, GlobalAnalytics data) {
    if (data.examOptions.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<AssessmentOption?>(
      initialValue: _selectedExam,
      tooltip: 'Select exam',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 36),
      onSelected: (opt) {
        setState(() => _selectedExam = opt);
        if (opt != null) {
          context.push('/assessment/${opt.id}/analytics');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<AssessmentOption?>(
          value: null,
          child: Row(
            children: [
              const Icon(
                Icons.dashboard_rounded,
                size: 18,
                color: Color(0xFF6E4CF5),
              ),
              const SizedBox(width: 10),
              const Text(
                'All Exams',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final opt in data.examOptions)
          PopupMenuItem<AssessmentOption?>(
            value: opt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opt.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  opt.classroomName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B98AE),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: Color(0xFF6E4CF5),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedExam?.title ?? 'Select Exam',
              style: const TextStyle(
                color: Color(0xFF6E4CF5),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Color(0xFF6E4CF5),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Full Dashboard
  // ─────────────────────────────────────────────
  Widget _buildDashboard(BuildContext context, GlobalAnalytics data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stat cards row
        _buildStatCards(data),
        const SizedBox(height: 20),
        // ── Most Violating Classroom Badge
        if (data.mostViolatingClassroom != null &&
            data.mostViolatingClassroom!.violationCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildMostViolatingClassroom(data.mostViolatingClassroom!),
          ),

        // ── Bar chart + top offenders in a row on wider screens
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildViolationChart(context, data)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildTopOffenders(context, data)),
                ],
              );
            }
            return Column(
              children: [
                _buildViolationChart(context, data),
                const SizedBox(height: 16),
                _buildTopOffenders(context, data),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMostViolatingClassroom(ClassroomViolationStat stat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Action Recommended',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Classroom ${stat.name} has the most proctoring alerts (${stat.violationCount}).',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Stat Tiles Row
  // ─────────────────────────────────────────────
  Widget _buildStatCards(GlobalAnalytics data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen is wider, show all 4 in a row. Otherwise 2x2 grid.
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 600 ? 2.2 : 2.5,
          children: [
            _StatTile(
              label: 'Classrooms',
              value: '${data.totalClassrooms}',
              icon: Icons.class_rounded,
              gradient: const [Color(0xFF6E4CF5), Color(0xFF9F78FF)],
            ),
            _StatTile(
              label: 'Students',
              value: '${data.totalStudents}',
              icon: Icons.people_alt_rounded,
              gradient: const [Color(0xFF2EA4EA), Color(0xFF5BC8FF)],
            ),
            _StatTile(
              label: 'Exams',
              value: '${data.totalAssessments}',
              icon: Icons.assignment_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
            ),
            _StatTile(
              label: 'Violations',
              value: '${data.totalViolations}',
              icon: Icons.warning_amber_rounded,
              gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  fl_chart Bar Chart (with linear fallback)
  // ─────────────────────────────────────────────
  Widget _buildViolationChart(BuildContext context, GlobalAnalytics data) {
    final stats = data.byTypeSorted.take(6).toList();

    return _DashCard(
      title: 'Violation Breakdown',
      icon: Icons.bar_chart_rounded,
      iconColor: const Color(0xFF6E4CF5),
      child: stats.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No violations yet')),
            )
          : _BarChartWidget(stats: stats, total: data.totalViolations),
    );
  }

  // ─────────────────────────────────────────────
  //  Top Offenders List
  // ─────────────────────────────────────────────
  Widget _buildTopOffenders(BuildContext context, GlobalAnalytics data) {
    final top = data.topOffenders;
    return _DashCard(
      title: 'Top Students · Violations',
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFF59E0B),
      child: top.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 44,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No violations recorded!',
                      style: TextStyle(color: Color(0xFF73839D)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: top.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF0F4F8)),
              itemBuilder: (context, i) {
                final s = top[i];
                return _OffenderTile(
                  rank: i + 1,
                  student: s,
                  onView: () => _openStudentSheet(
                    s,
                    // Use a general endpoint; the bottom sheet will find the student
                    '/assessments/${data.examOptions.isNotEmpty ? data.examOptions.first.id : '0'}/proctoring-report',
                  ),
                );
              },
            ),
    );
  }

  // ─────────────────────────────────────────────
  //  Loading shimmer
  // ─────────────────────────────────────────────
  Widget _buildLoadingShimmer(BuildContext context) {
    return Column(
      children: [_shimmer(h: 80), const SizedBox(height: 14), _shimmer(h: 220)],
    );
  }

  Widget _shimmer({required double h}) => Container(
    height: h,
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(180),
      borderRadius: BorderRadius.circular(18),
    ),
  );

  Widget _buildError(BuildContext context, Object e) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: Color(0xFFEF4444)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Could not load analytics: $e',
            style: const TextStyle(color: Color(0xFF73839D)),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  Reusable card wrapper
// ─────────────────────────────────────────────
class _DashCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _DashCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF24364E),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stat tile
// ─────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: gradient.first,
                    height: 1,
                  ),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8B98AE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  fl_chart – Horizontal Bar Chart
// ─────────────────────────────────────────────
class _BarChartWidget extends StatelessWidget {
  final List<ViolationTypeStat> stats;
  final int total;
  const _BarChartWidget({required this.stats, required this.total});

  static const _palette = [
    Color(0xFF6E4CF5),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final maxCount = stats
        .fold<int>(0, (m, s) => s.count > m ? s.count : m)
        .toDouble();

    // Try fl_chart BarChart
    try {
      return SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount + 1,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      const Color(0xFF24364E).withAlpha(230),
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${stats[gi].displayName}\n${rod.toY.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      return SideTitleWidget(
                        space: 4,
                        meta: meta,
                        child: Text(
                          _shortLabel(stats[idx].type),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8B98AE),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (val, meta) => Text(
                      val.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8B98AE),
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: const Color(0xFFEFF4FA), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(stats.length, (i) {
                final color = _palette[i % _palette.length];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: stats[i].count.toDouble(),
                      color: color,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxCount + 1,
                        color: color.withAlpha(20),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      );
    } catch (_) {
      // Fallback: progress bars
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          children: stats.map((s) {
            final pct = total > 0 ? s.count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      s.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDE8FF),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF6E4CF5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.count}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  String _shortLabel(String type) {
    switch (type) {
      case 'Tab Switch':
        return 'Tab';
      case 'Window Blur':
        return 'Blur';
      case 'Copy Paste':
        return 'Copy';
      case 'Context Menu':
        return 'Menu';
      case 'Full Screen Exit':
        return 'FS';
      default:
        return type.length > 6 ? type.substring(0, 6) : type;
    }
  }
}

// ─────────────────────────────────────────────
//  Top Offender tile
// ─────────────────────────────────────────────
class _OffenderTile extends StatelessWidget {
  final int rank;
  final EnrichedStudentStat student;
  final VoidCallback onView;
  const _OffenderTile({
    required this.rank,
    required this.student,
    required this.onView,
  });

  Color get _riskColor {
    if (student.violationCount >= 5) return const Color(0xFFEF4444);
    if (student.violationCount >= 3) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get _riskLabel {
    if (student.violationCount >= 5) return 'High';
    if (student.violationCount >= 3) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFF59E0B)
                  : rank == 2
                  ? const Color(0xFF9CA3AF)
                  : rank == 3
                  ? const Color(0xFFCD7F32)
                  : const Color(0xFFEDE8FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: rank <= 3 ? Colors.white : const Color(0xFF6E4CF5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEDE8FF),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF6E4CF5),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + risk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF24364E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.classroomName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Color(0xFF8B98AE),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _riskColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$_riskLabel Risk',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _riskColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Violation chip + view
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _riskColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${student.violationCount}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _riskColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6E4CF5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
