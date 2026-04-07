import 'proctoring_platform.dart';

class NativeProctoring extends ProctoringPlatform {
  @override
  void lockWeb(Function(String) onViolation) {
    // No-op on native
  }

  @override
  void unlockWeb() {
    // No-op on native
  }

  @override
  String getUserAgent() {
    return 'Native';
  }
}

ProctoringPlatform getPlatform() => NativeProctoring();
