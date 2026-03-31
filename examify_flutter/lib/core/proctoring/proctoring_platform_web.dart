import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'proctoring_platform.dart';

class WebProctoring extends ProctoringPlatform {
  @override
  void lockWeb(Function(String) onViolation) {
    web.document.documentElement?.requestFullscreen();
    
    // Tab switching detection
    web.document.addEventListener('visibilitychange', ((web.Event event) {
      if (web.document.visibilityState == 'hidden') {
        onViolation('alt_tab');
      }
    }).toJS);

    // Window resize (Split-screen) detection
    web.window.addEventListener('resize', ((web.Event event) {
      onViolation('window_resize');
    }).toJS);

    // Fullscreen exit detection
    web.document.addEventListener('fullscreenchange', ((web.Event event) {
      if (web.document.fullscreenElement == null) {
        onViolation('fullscreen_exit');
      }
    }).toJS);
  }

  @override
  void unlockWeb() {
    web.document.exitFullscreen();
  }

  @override
  String getUserAgent() {
    return web.window.navigator.userAgent;
  }
}

ProctoringPlatform getPlatform() => WebProctoring();
