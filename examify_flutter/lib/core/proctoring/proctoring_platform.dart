abstract class ProctoringPlatform {
  void lockWeb(Function(String) onViolation);
  void unlockWeb();
  String getUserAgent();
}

ProctoringPlatform getPlatform() =>
    throw UnsupportedError('Cannot create proctoring platform');
