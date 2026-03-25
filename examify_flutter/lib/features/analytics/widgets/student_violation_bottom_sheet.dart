// lib/features/analytics/widgets/student_violation_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../models/exam_analytics.dart';

/// Shows a draggable bottom sheet with a student's full violation timeline.
///
/// [studentName] and [attemptId] are passed in from the parent.
/// Data is fetched lazily inside using a FutureBuilder.
class StudentViolationBottomSheet extends ConsumerWidget {
  final String studentName;
  final int attemptId;
  final String reportEndpoint; // e.g. '/assessments/$examId/proctoring-report'

  const StudentViolationBottomSheet({
    super.key,
    required this.studentName,
    required this.attemptId,
    required this.reportEndpoint,
  });

  IconData _iconFor(String type) {
    switch (type) {
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

  String _displayName(String type) {
    switch (type) {
      case 'tab_switch':
        return 'Tab Switch';
      case 'window_blur':
        return 'Window Blur';
      case 'app_background':
        return 'App Backgrounded';
      case 'copy_paste':
        return 'Copy / Paste';
      case 'context_menu':
        return 'Context Menu';
      case 'fullscreen_exit':
        return 'Fullscreen Exit';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dio = ref.watch(apiClientProvider);
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('MMM dd, yyyy hh:mm a');

    final future = dio.get(reportEndpoint).then((res) {
      final list = res.data as List<dynamic>;
      final studentLogs = <ViolationEvent>[];

      for (final r in list) {
        final s = r['student'];
        if (s == null) continue;
        if ((s['id'] as num?)?.toInt() == attemptId ||
            (s['name'] as String?) == studentName ||
            (s['email'] as String?) == studentName) {
          final logs = (r['logs'] as List<dynamic>?) ?? [];
          for (final log in logs) {
            studentLogs.add(
              ViolationEvent(
                type: log['event_type'] as String,
                createdAt: DateTime.parse(log['timestamp'] as String).toLocal(),
              ),
            );
          }
        }
      }

      studentLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return studentLogs;
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Violation Timeline',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: FutureBuilder<List<ViolationEvent>>(
              future: future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load violation details.\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final events = snap.data ?? [];
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 52,
                          color: cs.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text('No violations recorded for this student.'),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final ev = events[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.red.withOpacity(.12),
                        child: Icon(
                          _iconFor(ev.type),
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                      title: Text(
                        _displayName(ev.type),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        fmt.format(ev.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(.6),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
