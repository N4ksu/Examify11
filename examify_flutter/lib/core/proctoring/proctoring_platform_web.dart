import 'dart:html' as html;
import 'proctoring_platform.dart';

class WebProctoring extends ProctoringPlatform {
  @override
  void lockWeb(Function(String) onViolation) {
    html.document.documentElement?.requestFullscreen();
    html.document.onVisibilityChange.listen((event) {
      if (html.document.visibilityState == 'hidden') {
        onViolation('alt_tab');
      }
    });
  }

  @override
  void unlockWeb() {
    html.document.exitFullscreen();
  }

  @override
  String getUserAgent() {
    return html.window.navigator.userAgent;
  }
}

ProctoringPlatform getPlatform() => WebProctoring();
