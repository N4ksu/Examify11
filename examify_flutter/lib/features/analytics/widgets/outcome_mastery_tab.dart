import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/outcome_analytics_provider.dart';
import '../models/outcome_mastery.dart';

class OutcomeMasteryTab extends ConsumerWidget {
  final int examId;

  const OutcomeMasteryTab({super.key, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(outcomeAnalyticsProvider(examId));
    final isWide = MediaQuery.of(context).size.width > 700;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(outcomeAnalyticsProvider(examId));
      },
      child: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8E44AD))),
        error: (e, stack) => Center(child: Text('Error: $e')),
        data: (analytics) {
          if (analytics.breakdown.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No Course Outcomes tracked for this exam.\nTag questions with Outcomes during Exam Creation to see Analytics here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OverallMasteryCard(overallMastery: analytics.overallMastery),
                const SizedBox(height: 16),
                
                if (analytics.lowestCo != null) ...[
                  _ActionRecommended(lowestCo: analytics.lowestCo!),
                  const SizedBox(height: 16),
                ],

                _SectionTitle(icon: Icons.bar_chart_rounded, label: 'Mastery Breakdown'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: analytics.breakdown.map((co) => _MasteryBreakdownTile(stat: co)).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (analytics.lowestCo != null && analytics.strugglingStudents.isNotEmpty) ...[
                  _SectionTitle(icon: Icons.group_off_outlined, label: 'Students needing help with ${analytics.lowestCo}'),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: analytics.strugglingStudents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        return _StudentTile(student: analytics.strugglingStudents[i], rank: i + 1);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Summary Card
// ──────────────────────────────────────────────
class _OverallMasteryCard extends StatelessWidget {
  final double overallMastery;
  
  const _OverallMasteryCard({required this.overallMastery});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: const Color(0xFF8E44AD).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF8E44AD), const Color(0xFF6C3483)],
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
              child: const Icon(Icons.school_rounded, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overallMastery.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                ),
                const Text(
                  'Overall CO Mastery',
                  style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
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
//  Action Recommended
// ──────────────────────────────────────────────
class _ActionRecommended extends StatelessWidget {
  final String lowestCo;

  const _ActionRecommended({required this.lowestCo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Action Recommended', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                const SizedBox(height: 4),
                Text(
                  'The class struggled the most with $lowestCo. Consider allocating additional review time or supplementary materials for this objective.',
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Mastery Breakdown Tile
// ──────────────────────────────────────────────
class _MasteryBreakdownTile extends StatelessWidget {
  final OutcomeBreakdown stat;

  const _MasteryBreakdownTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final masteryValue = stat.possiblePoints > 0 ? (stat.earnedPoints / stat.possiblePoints) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.code,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                '${stat.masteryPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2A3954)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: masteryValue,
              backgroundColor: const Color(0xFF8E44AD).withOpacity(0.15),
              color: const Color(0xFF8E44AD),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Student Row Tile
// ──────────────────────────────────────────────
class _StudentTile extends StatelessWidget {
  final StrugglingStudent student;
  final int rank;

  const _StudentTile({required this.student, required this.rank});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade50,
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
        ),
      ),
      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Mastery: ${student.masteryPercentage.toStringAsFixed(1)}%', style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: Chip(
        label: const Text('Needs Help', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
        backgroundColor: Colors.red.shade400,
        padding: EdgeInsets.zero,
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
