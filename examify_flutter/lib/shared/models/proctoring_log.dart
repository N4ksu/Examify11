class ProctoringLog {
  final int id;
  final int attemptId;
  final String eventType;
  final String platform;
  final String deviceInfo;
  final DateTime timestamp;

  ProctoringLog({
    required this.id,
    required this.attemptId,
    required this.eventType,
    required this.platform,
    required this.deviceInfo,
    required this.timestamp,
  });

  factory ProctoringLog.fromJson(Map<String, dynamic> json) {
    return ProctoringLog(
      id: json['id'],
      attemptId: json['attempt_id'] ?? 0,
      eventType: json['event_type'],
      platform: json['platform'],
      deviceInfo: json['device_info'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'event_type': eventType,
      'platform': platform,
      'device_info': deviceInfo,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
