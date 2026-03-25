import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/providers/proctoring_provider.dart';

class ProctoringReportScreen extends ConsumerWidget {
  final String assessmentId;
  const ProctoringReportScreen({super.key, required this.assessmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      proctoringReportProvider(int.parse(assessmentId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Proctoring Report - Assessment $assessmentId'),
      ),
      body: reportAsync.when(
        data: (reports) {
          // Flatten all logs into a single list for the table
          final allLogs = reports.expand((r) {
            return r.logs.map((log) => _LogWithStudent(r.student.name, log));
          }).toList();

          // Sort by violation number or timestamp if needed
          allLogs.sort((a, b) => b.log.timestamp.compareTo(a.log.timestamp));

          final totalViolations = reports.fold<int>(
            0,
            (sum, r) => sum + r.totalViolations,
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Alerts',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('Total violations detected: $totalViolations'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (allLogs.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No proctoring violations detected.'),
                    ),
                  )
                else
                  Expanded(
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: ListView(
                        children: [
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Student')),
                              DataColumn(label: Text('Event Type')),
                              DataColumn(label: Text('Platform')),
                              DataColumn(label: Text('Time')),
                            ],
                            rows: allLogs.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(item.studentName)),
                                  DataCell(Text(item.log.eventType)),
                                  DataCell(Text(item.log.platform)),
                                  DataCell(
                                    Text(
                                      DateFormat(
                                        'hh:mm a',
                                      ).format(item.log.timestamp),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading report: $err')),
      ),
    );
  }
}

class _LogWithStudent {
  final String studentName;
  final ProctoringLogEntry log;
  _LogWithStudent(this.studentName, this.log);
}
