import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ViolationBanner extends StatelessWidget {
  final int violationCount;

  const ViolationBanner({super.key, required this.violationCount});

  @override
  Widget build(BuildContext context) {
    if (violationCount == 0) return const SizedBox.shrink();

    String message = '';
    Color bgColor = AppColors.warning;

    if (violationCount <= 2) {
      message = '⚠️ Warning: Focus loss detected';
    } else if (violationCount < 5) {
      message = '⚠️ FINAL WARNING — next violation auto-submits';
      bgColor = AppColors.error.withValues(alpha: 0.9);
    } else {
      message = '❌ Exam Auto-Submitted due to violations';
      bgColor = AppColors.error;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
