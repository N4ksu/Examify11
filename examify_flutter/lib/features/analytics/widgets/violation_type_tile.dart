// lib/features/analytics/widgets/violation_type_tile.dart
import 'package:flutter/material.dart';
import '../models/exam_analytics.dart';

class ViolationTypeTile extends StatelessWidget {
  final ViolationTypeStat stat;
  final int totalViolations;

  const ViolationTypeTile({
    super.key,
    required this.stat,
    required this.totalViolations,
  });

  IconData _icon() {
    switch (stat.type) {
      case 'tab_switch':
      case 'app_switch':
        return Icons.tab_outlined;
      case 'window_blur':
        return Icons.blur_on;
      case 'app_background':
        return Icons.phone_android;
      case 'copy_paste':
        return Icons.content_paste;
      case 'context_menu':
        return Icons.more_horiz;
      case 'fullscreen_exit':
        return Icons.fullscreen_exit;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _color(BuildContext context) {
    final colors = [
      Colors.indigo,
      Colors.red,
      Colors.amber,
      Colors.teal,
      Colors.purple,
      Colors.orange,
    ];
    // stable color per violation type
    final idx = stat.type.hashCode.abs() % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final pct = totalViolations > 0 ? stat.count / totalViolations : 0.0;
    final color = _color(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_icon(), size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stat.count}  (${(pct * 100).toStringAsFixed(0)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: color.withOpacity(.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
