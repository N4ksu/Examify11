import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:window_manager/window_manager.dart';
import 'proctoring_platform.dart';
import 'dart:io' show Platform;
import 'proctoring_platform_native.dart'
    if (dart.library.html) 'proctoring_platform_web.dart'
    as platform_impl;

enum ProctoringAction { warn, finalWarn, autoSubmitted }

class ProctoringService extends WindowListener with WidgetsBindingObserver {
  final int attemptId;
  final Dio apiClient;
  int violationCount = 0;
  Function(ProctoringAction)? onViolation;

  bool _isProctoring = false;

  ProctoringService({
    required this.attemptId,
    required this.apiClient,
    this.onViolation,
  }) : _platform = platform_impl.getPlatform();

  final ProctoringPlatform _platform;
  
  // Spatial awareness for overlay masking
  Offset overlayPosition = const Offset(24, 100);
  Size overlaySize = const Size(320, 240);
  bool isOverlayFullScreen = false;
  bool isMouseInJitsi = false;

  Future<void> start() async {
    if (_isProctoring) return;
    _isProctoring = true;

    WidgetsBinding.instance.addObserver(this);

    if (kIsWeb) {
      _lockWeb();
    } else if (Platform.isAndroid) {
      await _lockAndroid();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await _lockDesktop();
    } else if (Platform.isIOS) {
      await _lockIOS();
    }
  }

  Future<void> stop() async {
    if (!_isProctoring) return;
    _isProctoring = false;

    WidgetsBinding.instance.removeObserver(this);

    if (kIsWeb) {
      _unlockWeb();
    } else if (Platform.isAndroid) {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
    } else if (Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && _isProctoring) {
      _reportViolation('window_close_attempt');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _checkViolationWithDelay(state == AppLifecycleState.paused ? 'app_background' : 'window_blur');
    }
  }

  void _checkViolationWithDelay(String eventType) {
    if (!_isProctoring) return;
    
    // 1-second delay to allow focus to settle and check mouse position
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!_isProctoring) return;
      
      // If we are fullscreen monitoring or mouse is in Jitsi, ignore
      if (isOverlayFullScreen || isMouseInJitsi) {
        debugPrint('Ignoring $eventType: Interaction detected inside Jitsi overlay');
        return;
      }

      _reportViolation(eventType, remark: _getDefaultRemark(eventType));
    });
  }

  @override
  void onWindowFocus() {
    // Window gained focus
  }

  @override
  void onWindowBlur() {
    // Window lost focus on desktop (Alt-Tab)
    if (_isProctoring && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _checkViolationWithDelay('window_blur');
    }
  }

  @override
  void onWindowResize() {
    if (_isProctoring) {
      _reportViolation('window_resize');
    }
  }

  @override
  void onWindowMaximize() {
    if (_isProctoring) {
      // Potentially allowed, but usually we want to stay in fullscreen
    }
  }

  @override
  void onWindowUnmaximize() {
    if (_isProctoring) {
      _reportViolation('window_unmaximize');
    }
  }

  Future<void> _lockAndroid() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _lockIOS() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _lockDesktop() async {
    windowManager.addListener(this);
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setPreventClose(true);
  }

  void _lockWeb() {
    _platform.lockWeb((type) => _reportViolation(type));
  }

  void _unlockWeb() {
    _platform.unlockWeb();
  }

  Future<String> _getDeviceInfo() async {
    if (kIsWeb) {
      return _platform.getUserAgent();
    }
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return '${info.manufacturer} ${info.model} (API ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return '${info.name} ${info.systemVersion}';
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      return 'Windows ${info.majorVersion}.${info.minorVersion}';
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      return 'macOS ${info.osRelease}';
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      return '${info.name} ${info.version}';
    }
    return 'Unknown Device';
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  Future<void> _reportViolation(String eventType, {String? remark}) async {
    violationCount++;
    final info = await _getDeviceInfo();

    try {
      final response = await apiClient.post(
        '/attempts/$attemptId/proctor-event',
        data: {
          'event_type': eventType,
          'platform': _getPlatformName(),
          'device_info': info,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'remark': remark ?? _getDefaultRemark(eventType),
        },
      );

      final action = response.data['action'];
      if (action == 'warn') onViolation?.call(ProctoringAction.warn);
      if (action == 'final_warn') onViolation?.call(ProctoringAction.finalWarn);
      if (action == 'auto_submitted') {
        onViolation?.call(ProctoringAction.autoSubmitted);
      }
    } catch (e) {
      debugPrint('Failed to report violation: $e');
    }
  }

  String _getDefaultRemark(String eventType) {
    switch (eventType) {
      case 'alt_tab':
        return 'User switched to another application or tab';
      case 'app_background':
        return 'Application was moved to background';
      case 'window_blur':
        return 'Screen lost focus (Alt-Tab or window switch)';
      case 'fullscreen_exit':
        return 'Left full-screen mode';
      case 'window_resize':
        return 'Exam window was resized';
      case 'window_unmaximize':
        return 'Exam window was unmaximized';
      case 'window_close_attempt':
        return 'Attempted to close the exam window';
      default:
        return 'Proctoring violation detected: $eventType';
    }
  }
}
