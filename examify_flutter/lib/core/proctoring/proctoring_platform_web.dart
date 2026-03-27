// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'proctoring_platform.dart';

class WebProctoring extends ProctoringPlatform {
  @override
  void lockWeb(Function(String) onViolation) {
    html.document.documentElement?.requestFullscreen();
    
    // Tab switching detection
    html.document.onVisibilityChange.listen((event) {
      if (html.document.visibilityState == 'hidden') {
        onViolation('alt_tab');
      }
    });

    // Window resize (Split-screen) detection
    html.window.onResize.listen((event) {
      onViolation('window_resize');
    });

    // Fullscreen exit detection
    html.document.onFullscreenChange.listen((event) {
      if (html.document.fullscreenElement == null) {
        onViolation('fullscreen_exit');
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
