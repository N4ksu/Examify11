import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/analytics_data.dart';

class AnalyticsDashboard extends StatelessWidget {
  final AnalyticsData data;

  const AnalyticsDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6E4CF5),
        foregroundColor: Colors.white,
        title: const Text(
          'Exam Analytics',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreSummary(),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Class Performance Distribution',
              child: SizedBox(height: 240, child: _buildHistogram()),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Question Difficulty',
              subtitle: 'Correct vs Incorrect answers per question',
              child: SizedBox(height: 320, child: _buildBarChart()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E3EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF223B6A).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F3E58),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF7B8AA2),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildScoreSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6E4CF5),
            Color(0xFF49A5FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Average', '${data.averageScore.toStringAsFixed(1)}%'),
          _summaryItem('Highest', '${data.highestScore.toStringAsFixed(1)}%'),
          _summaryItem('Lowest', '${data.lowestScore.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.84),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildHistogram() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: data.scoreDistribution.entries.map((e) {
          return BarChartGroupData(
            x: int.parse(e.key),
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: const Color(0xFF6E4CF5),
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: data.questionPerformance.map((q) {
          return BarChartGroupData(
            x: q.id,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: q.correctCount.toDouble(),
                color: const Color(0xFF35C76F),
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: q.incorrectCount.toDouble(),
                color: const Color(0xFFE25468),
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
