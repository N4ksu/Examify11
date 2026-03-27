import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

class ProctoringLogEntry {
  final String eventType;
  final String platform;
  final String? remark;
  final DateTime timestamp;

  ProctoringLogEntry({
    required this.eventType,
    required this.platform,
    this.remark,
    required this.timestamp,
  });

  factory ProctoringLogEntry.fromJson(Map<String, dynamic> json) {
    return ProctoringLogEntry(
      eventType: json['event_type'] ?? 'Unknown',
      platform: json['platform'] ?? 'Unknown',
      remark: json['remark'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class ProctoringReportStudent {
  final String name;
  ProctoringReportStudent({required this.name});

  factory ProctoringReportStudent.fromJson(Map<String, dynamic> json) {
    return ProctoringReportStudent(name: json['name'] ?? 'Unknown Student');
  }
}

class ProctoringReport {
  final ProctoringReportStudent student;
  final List<ProctoringLogEntry> logs;
  final List<ProctoringSnapshotEntry> snapshots;
  final int totalViolations;

  ProctoringReport({
    required this.student,
    required this.logs,
    required this.snapshots,
    required this.totalViolations,
  });

  factory ProctoringReport.fromJson(Map<String, dynamic> json) {
    var logsList = json['logs'] as List? ?? [];
    var snapshotsList = json['snapshots'] as List? ?? [];
    return ProctoringReport(
      student: ProctoringReportStudent.fromJson(json['student'] ?? {}),
      logs: logsList.map((x) => ProctoringLogEntry.fromJson(x)).toList(),
      snapshots: snapshotsList.map((x) => ProctoringSnapshotEntry.fromJson(x)).toList(),
      totalViolations: json['total_violations'] ?? 0,
    );
  }
}

class ProctoringSnapshotEntry {
  final String url;
  final DateTime capturedAt;

  ProctoringSnapshotEntry({
    required this.url,
    required this.capturedAt,
  });

  factory ProctoringSnapshotEntry.fromJson(Map<String, dynamic> json) {
    return ProctoringSnapshotEntry(
      url: json['url'] ?? '',
      capturedAt: DateTime.parse(
        json['captured_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

final proctoringReportProvider = FutureProvider.family<List<ProctoringReport>, int>((ref, assessmentId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/assessments/$assessmentId/proctoring-report');
  final data = response.data as List;
  return data.map((json) => ProctoringReport.fromJson(json)).toList();
});
