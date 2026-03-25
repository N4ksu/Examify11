import '../../../shared/models/user.dart';

class ProctoringReport {
  final User student;
  final int totalViolations;
  final List<ProctoringLogEntry> logs;

  ProctoringReport({
    required this.student,
    required this.totalViolations,
    required this.logs,
  });

  factory ProctoringReport.fromJson(Map<String, dynamic> json) {
    return ProctoringReport(
      student: User.fromJson(json['student']),
      totalViolations: json['total_violations'] ?? 0,
      logs:
          (json['logs'] as List?)
              ?.map((e) => ProctoringLogEntry.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ProctoringLogEntry {
  final String eventType;
  final String platform;
  final String deviceInfo;
  final String ipAddress;
  final int violationNumber;
  final DateTime timestamp;

  ProctoringLogEntry({
    required this.eventType,
    required this.platform,
    required this.deviceInfo,
    required this.ipAddress,
    required this.violationNumber,
    required this.timestamp,
  });

  factory ProctoringLogEntry.fromJson(Map<String, dynamic> json) {
    return ProctoringLogEntry(
      eventType: json['event_type'],
      platform: json['platform'],
      deviceInfo: json['device_info'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      violationNumber: json['violation_number'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
