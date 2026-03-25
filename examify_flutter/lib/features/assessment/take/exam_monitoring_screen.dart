import 'package:flutter/material.dart';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

class ExamMonitoringScreen extends StatefulWidget {
  final String roomName;
  final String assessmentId;
  final int attemptId;

  const ExamMonitoringScreen({
    super.key, 
    required this.roomName,
    required this.assessmentId,
    required this.attemptId,
  });

  @override
  State<ExamMonitoringScreen> createState() => _ExamMonitoringScreenState();
}

class _ExamMonitoringScreenState extends State<ExamMonitoringScreen> {
  late final WebViewController _flutterController;
  final WebviewController _windowsController = WebviewController();
  bool _isWindowsInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initWebView();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  Future<void> _initWebView() async {
    final url = 'https://meet.jit.si/${widget.roomName}';

    if (Platform.isWindows) {
      try {
        await _windowsController.initialize();
        await _windowsController.loadUrl(url);
        if (mounted) {
          setState(() {
            _isWindowsInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('WebView Error: $e');
      }
    } else {
      _flutterController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {},
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {},
          ),
        )
        ..loadRequest(Uri.parse(url));
      // Rebuild to show the flutter webview
      if (mounted) setState(() {});
    }
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('Allow access to $kind?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Monitoring'),
        backgroundColor: const Color(0xFF6E4CF5),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              context.push(
                '/assessment/${widget.assessmentId}/take?attemptId=${widget.attemptId}&roomName=${widget.roomName}',
              );
            },
            child: const Text('Proceed to Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Platform.isWindows
          ? (_isWindowsInitialized
              ? Webview(
                  _windowsController,
                  permissionRequested: _onPermissionRequested,
                )
              : const Center(child: CircularProgressIndicator()))
          : WebViewWidget(controller: _flutterController),
    );
  }
}
