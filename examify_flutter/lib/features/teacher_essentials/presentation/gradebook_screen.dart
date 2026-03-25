import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/teacher_essentials_service.dart';
import '../models/gradebook_entry.dart';

class GradebookScreen extends ConsumerWidget {
  final int classroomId;

  const GradebookScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradebookAsync = ref.watch(gradebookProvider(classroomId));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FC),
      body: gradebookAsync.when(
        data: (entries) => _GradebookBody(entries: entries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(context, err),
      ),
    );
  }

  static Widget _buildErrorState(BuildContext context, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 16),
            Text(
              'Could not load gradebook',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$err',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradebookBody extends StatefulWidget {
  final List<GradebookEntry> entries;

  const _GradebookBody({required this.entries});

  @override
  State<_GradebookBody> createState() => _GradebookBodyState();
}

class _GradebookBodyState extends State<_GradebookBody> {
  bool showOutcomes = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;

    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }

    final assessmentTitles =
        entries.expand((e) => e.scores.keys).toSet().toList();
    final outcomeKeys = entries
        .expand((e) => (e.outcomes ?? {}).keys)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Student Scores',
                    style: TextStyle(
                      color: Color(0xFF2F3E58),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SegmentedButton<bool>(
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return const Color(0xFF2F3E58);
                      }),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Assessments'),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Outcomes'),
                      ),
                    ],
                    selected: {showOutcomes},
                    onSelectionChanged: (selection) {
                      setState(() {
                        showOutcomes = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF3F8FD),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Color(0xFF2F3E58),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Color(0xFF2F3E58),
                      fontSize: 14,
                    ),
                    columns: _buildColumns(
                      showOutcomes: showOutcomes,
                      assessmentTitles: assessmentTitles,
                      outcomeKeys: outcomeKeys,
                    ),
                    rows: entries
                        .map(
                          (entry) => _buildDataRow(
                            entry,
                            assessmentTitles: assessmentTitles,
                            outcomeKeys: outcomeKeys,
                            showOutcomes: showOutcomes,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 20),
            Text(
              'No students enrolled in this class',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add students from the People tab or use Import Students.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    color: Color(0xFF2F3E58),
    fontWeight: FontWeight.w700,
    fontSize: 14,
  );
  static const TextStyle _tableCellStyle = TextStyle(
    color: Color(0xFF2F3E58),
    fontSize: 14,
  );

  List<DataColumn> _buildColumns({
    required bool showOutcomes,
    required List<String> assessmentTitles,
    required List<String> outcomeKeys,
  }) {
    final baseColumns = <DataColumn>[
      const DataColumn(label: Text('Student ID', style: _tableHeaderStyle)),
      const DataColumn(label: Text('Name', style: _tableHeaderStyle)),
      const DataColumn(label: Text('Section', style: _tableHeaderStyle)),
    ];

    if (showOutcomes) {
      return [
        ...baseColumns,
        ...outcomeKeys.map((key) => DataColumn(label: Text(key, style: _tableHeaderStyle))),
        const DataColumn(label: Text('Overall Grade', style: _tableHeaderStyle)),
      ];
    }

    return [
      ...baseColumns,
      ...assessmentTitles.map((title) => DataColumn(label: Text(title, style: _tableHeaderStyle))),
      const DataColumn(label: Text('Calculated Grade', style: _tableHeaderStyle)),
    ];
  }

  DataRow _buildDataRow(
    GradebookEntry entry, {
    required List<String> assessmentTitles,
    required List<String> outcomeKeys,
    required bool showOutcomes,
  }) {
    const cellStyle = _tableCellStyle;
    final baseCells = <DataCell>[
      DataCell(Text(entry.studentId ?? 'N/A', style: cellStyle)),
      DataCell(Text(entry.name, style: cellStyle)),
      DataCell(Text(entry.section ?? 'N/A', style: cellStyle)),
    ];

    if (showOutcomes) {
      return DataRow(
        cells: [
          ...baseCells,
          ...outcomeKeys.map((key) {
            final score = (entry.outcomes ?? const {})[key];
            return DataCell(Text(score?.toString() ?? '-', style: cellStyle));
          }),
          DataCell(
            Text(
              entry.calculatedGrade.toStringAsFixed(1),
              style: cellStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return DataRow(
      cells: [
        ...baseCells,
        ...assessmentTitles.map((title) {
          final score = entry.scores[title];
          return DataCell(Text(score?.toString() ?? '0.0', style: cellStyle));
        }),
        DataCell(
          Text(
            entry.calculatedGrade.toStringAsFixed(1),
            style: cellStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
