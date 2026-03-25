import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/proctoring/proctoring_service.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/violation_banner.dart';

import '../../../shared/models/assessment.dart';
import '../../../shared/models/question.dart';
import '../../../shared/providers/assessment_provider.dart';

class TakeAssessmentScreen extends ConsumerStatefulWidget {
  final String assessmentId;
  final int attemptId;
  final String? roomName;
  const TakeAssessmentScreen({
    super.key,
    required this.assessmentId,
    required this.attemptId,
    this.roomName,
  });

  @override
  ConsumerState<TakeAssessmentScreen> createState() =>
      _TakeAssessmentScreenState();
}

class _TakeAssessmentScreenState extends ConsumerState<TakeAssessmentScreen> {
  late ProctoringService _proctoringService;
  int _violationCount = 0;
  int _currentQuestionIndex = 0;
  final Map<int, Set<int>> _selectedAnswers =
      {}; // Map of question index -> set of selected option indices
  final Map<int, String> _essayAnswers =
      {}; // Map of question index -> essay text value
  final _essayController = TextEditingController();

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isInitialized = false;
  bool _isQuestionsInitialized = false;

  late final WebViewController _flutterController;
  final WebviewController _windowsController = WebviewController();
  bool _isWindowsInitialized = false;

  // Interactive Overlay State
  Offset _overlayPosition = const Offset(24, 100); // Relative to top-left
  Size _overlaySize = const Size(320, 240);
  bool _isOverlayFullScreen = false;

  List<Question>? _loadedQuestions;

  @override
  void initState() {
    super.initState();
    _initProctoring();
    if (widget.roomName != null) {
      _requestPermissions();
      _initWebView();
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  Future<void> _initWebView() async {
    final url =
        'https://meet.jit.si/${widget.roomName}#config.prejoinPageEnabled=false&config.requireDisplayName=false&config.startWithAudioMuted=false&config.startWithVideoMuted=false&config.disableDeepLinking=true&userInfo.displayName=Student';

    if (Platform.isWindows) {
      try {
        await _windowsController.initialize();
        await _windowsController.loadUrl(url);
        await _windowsController.executeScript('''
          function autoJoin() {
            const joinButton = Array.from(document.querySelectorAll('button')).find(b => 
              b.innerText.toLowerCase().includes('join') || 
              b.ariaLabel?.toLowerCase().includes('join')
            );
            if (joinButton) { joinButton.click(); }
          }
          setInterval(autoJoin, 1000);
        ''');
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
            onPageFinished: (url) {
              _flutterController.runJavaScript('''
                function autoJoin() {
                  const joinButton = Array.from(document.querySelectorAll('button')).find(b => 
                    b.innerText.toLowerCase().includes('join') || 
                    b.ariaLabel?.toLowerCase().includes('join')
                  );
                  if (joinButton) { joinButton.click(); }
                }
                setInterval(autoJoin, 1000);
              ''');
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
      if (mounted) setState(() {});
    }
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
    String url,
    WebviewPermissionKind kind,
    bool isUserInitiated,
  ) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('Allow access to $kind?'),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return decision ?? WebviewPermissionDecision.none;
  }

  void _initTimer(int minutes) {
    if (_isInitialized) return;
    _secondsRemaining = minutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _submit(autoSubmit: true, questions: _loadedQuestions);
      }
    });
    _isInitialized = true;
  }

  void _initProctoring() {
    _proctoringService = ProctoringService(
      attemptId: widget.attemptId,
      apiClient: ref.read(apiClientProvider),
      onViolation: (action) {
        if (!mounted) return;
        setState(() {
          _violationCount = _proctoringService.violationCount;
        });

        if (action == ProctoringAction.warn ||
            action == ProctoringAction.finalWarn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Warning: Focus loss detected. Please stay on the exam screen.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (action == ProctoringAction.autoSubmitted) {
          _submit(autoSubmit: true, questions: _loadedQuestions);
        }
      },
    );
    _proctoringService.start();
    // Sync initial overlay state
    _proctoringService.overlayPosition = _overlayPosition;
    _proctoringService.overlaySize = _overlaySize;
    _proctoringService.isOverlayFullScreen = _isOverlayFullScreen;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _proctoringService.stop();
    if (Platform.isWindows) {
      _windowsController.dispose();
      // Ensure local window manager flags are reset even if service fails
      _resetWindowManager();
    }
    _essayController.dispose();
    super.dispose();
  }

  Future<void> _resetWindowManager() async {
    try {
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setPreventClose(false);
    } catch (e) {
      debugPrint('Error resetting window manager: $e');
    }
  }

  void _onQuestionChanged(int newIndex) {
    setState(() {
      _currentQuestionIndex = newIndex;
      _essayController.text = _essayAnswers[newIndex] ?? '';
    });
  }

  bool _allQuestionsAnswered(List<Question> questions) {
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      if (q.type == 'essay') {
        final answer = _essayAnswers[i];
        if (answer == null || answer.trim().isEmpty) {
          return false;
        }
      } else {
        // multiple_choice, true_false, multiple_select
        final selected = _selectedAnswers[i];
        if (selected == null || selected.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isQuestionAnswered(int index, Question q) {
    if (q.type == 'essay') {
      final answer = _essayAnswers[index];
      return answer != null && answer.trim().isNotEmpty;
    } else {
      final selected = _selectedAnswers[index];
      return selected != null && selected.isNotEmpty;
    }
  }

  Widget _buildNavigationSidebar(List<Question> questions) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final isAnswered = _isQuestionAnswered(index, questions[index]);
                final isCurrent = index == _currentQuestionIndex;

                return InkWell(
                  onTap: () => _onQuestionChanged(index),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF6E4CF5)
                          : (isAnswered
                                ? Colors.green.shade100
                                : Colors.orange.shade50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF6E4CF5)
                            : (isAnswered ? Colors.green : Colors.orange),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : (isAnswered
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendItem(Colors.green, 'Answered'),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.orange, 'Unanswered'),
          const SizedBox(height: 8),
          _buildLegendItem(const Color(0xFF6E4CF5), 'Current'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _invalidateData() {
    final aid = int.tryParse(widget.assessmentId);
    if (aid != null) {
      final assessment = ref.read(assessmentDetailProvider(aid)).asData?.value;
      if (assessment != null) {
        ref.invalidate(assessmentsProvider(assessment.classroomId));
      }
      ref.invalidate(assessmentDetailProvider(aid));
      ref.invalidate(studentAttemptProvider(aid));
    }
  }

  void _submit({bool autoSubmit = false, List<Question>? questions}) async {
    _timer?.cancel();
    await _proctoringService.stop();

    if (questions != null) {
      final answers = <Map<String, dynamic>>[];
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (q.type == 'essay') {
          answers.add({
            'question_id': q.id,
            'text_response': _essayAnswers[i] ?? '',
          });
        } else if (q.type == 'multiple_select') {
          final selectedIndices = _selectedAnswers[i] ?? {};
          for (final idx in selectedIndices) {
            answers.add({'question_id': q.id, 'option_id': q.options[idx].id});
          }
        } else {
          final selectedSet = _selectedAnswers[i];
          final selectedIdx = (selectedSet != null && selectedSet.isNotEmpty)
              ? selectedSet.first
              : null;
          answers.add({
            'question_id': q.id,
            'option_id': selectedIdx != null ? q.options[selectedIdx].id : null,
          });
        }
      }

      try {
        final api = ref.read(apiClientProvider);
        await api.post(
          '/attempts/${widget.attemptId}/submit',
          data: {'answers': answers},
        );
        _invalidateData();

        if (!mounted) return;
        context.pushReplacement(
          '/assessment/${widget.assessmentId}/result',
          extra: widget.attemptId,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit assessment: $e')),
        );
      }
    } else {
      _invalidateData();
      if (!mounted) return;
      context.pushReplacement(
        '/assessment/${widget.assessmentId}/result',
        extra: widget.attemptId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessmentAsync = ref.watch(
      assessmentDetailProvider(int.parse(widget.assessmentId)),
    );

    return PopScope(
      canPop: false,
      child: assessmentAsync.when(
        data: (assessment) {
          _initTimer(assessment.timeLimitMinutes);
          _loadedQuestions = assessment.questions;
          if (!_isQuestionsInitialized && assessment.questions.isNotEmpty) {
            final questions = assessment.questions;
            for (int i = 0; i < questions.length; i++) {
              if (questions[i].type == 'essay') {
                _essayAnswers[i] = _essayAnswers[i] ?? '';
              }
            }
            final firstQ = questions[0];
            if (firstQ.type == 'essay') {
              _essayController.text = _essayAnswers[0] ?? '';
            }
            _isQuestionsInitialized = true;
          }
          return _buildMainLayout(context, assessment);
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error loading assessment: $err')),
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildWebview() {
    if (Platform.isWindows) {
      if (!_isWindowsInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return Webview(
        _windowsController,
        permissionRequested: _onPermissionRequested,
      );
    } else {
      return WebViewWidget(controller: _flutterController);
    }
  }

  Widget _buildMainLayout(BuildContext context, Assessment assessment) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildExamUI(context, assessment),
            if (widget.roomName != null && widget.roomName!.isNotEmpty)
              _isOverlayFullScreen
                  ? _buildFullScreenOverlay()
                  : _buildFloatingOverlay(constraints),
          ],
        );
      },
    );
  }

  Widget _buildFullScreenOverlay() {
    return MouseRegion(
      onEnter: (_) => _proctoringService.isMouseInJitsi = true,
      onExit: (_) => _proctoringService.isMouseInJitsi = false,
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            _buildOverlayHeader(isFullScreen: true),
            Expanded(child: _buildWebview()),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOverlay(BoxConstraints constraints) {
    return Positioned(
      top: _overlayPosition.dy,
      left: _overlayPosition.dx,
      child: MouseRegion(
        onEnter: (_) => _proctoringService.isMouseInJitsi = true,
        onExit: (_) => _proctoringService.isMouseInJitsi = false,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: _overlaySize.width,
            height: _overlaySize.height,
            color: Colors.black87,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildOverlayHeader(isFullScreen: false),
                    Expanded(child: _buildWebview()),
                  ],
                ),
                // Resize handle
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _overlaySize = Size(
                          (_overlaySize.width + details.delta.dx)
                              .clamp(200.0, 800.0),
                          (_overlaySize.height + details.delta.dy)
                              .clamp(150.0, 600.0),
                        );
                        _proctoringService.overlaySize = _overlaySize;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.south_east,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayHeader({required bool isFullScreen}) {
    return GestureDetector(
      onPanUpdate: isFullScreen
          ? null
          : (details) {
              setState(() {
                _overlayPosition += details.delta;
                _proctoringService.overlayPosition = _overlayPosition;
              });
            },
      child: Container(
        color: const Color(0xFF6E4CF5),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.videocam, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Exam Monitoring',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () =>
                  setState(() {
                    _isOverlayFullScreen = !_isOverlayFullScreen;
                    _proctoringService.isOverlayFullScreen = _isOverlayFullScreen;
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamUI(BuildContext context, Assessment assessment) {
    final questions = assessment.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: const Center(
          child: Text('No questions found in this assessment.'),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF6A40F2), Color(0xFF8D43F0), Color(0xFFA74DE9)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Image.asset('assets/cite_logo.png', height: 40),
                  const SizedBox(width: 8),
                  Image.asset('assets/jmc_logo.png', height: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${assessment.title} - Proctored',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Total Points: $totalPoints',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(_secondsRemaining),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _secondsRemaining < 60
                                ? Colors.red.shade300
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                if (_violationCount > 0)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ViolationBanner(violationCount: _violationCount),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text('${currentQuestion.points} pts'),
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    162,
                                    11,
                                    182,
                                  ),
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentQuestion.body,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: currentQuestion.type == 'essay'
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: TextField(
                                        maxLines: null,
                                        decoration: const InputDecoration(
                                          hintText: 'Type your answer here...',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _essayAnswers[_currentQuestionIndex] =
                                                val;
                                          });
                                        },
                                        controller: _essayController,
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: currentQuestion.options.length,
                                      itemBuilder: (context, index) {
                                        final option =
                                            currentQuestion.options[index];
                                        if (currentQuestion.type ==
                                            'multiple_select') {
                                          return CheckboxListTile(
                                            title: Text(
                                              option.body,
                                              style: const TextStyle(
                                                color: Color(0xFF1E293B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 2,
                                            ),
                                            checkboxShape:
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                            value:
                                                (_selectedAnswers[_currentQuestionIndex] ??
                                                        {})
                                                    .contains(index),
                                            activeColor: const Color(
                                              0xFF6E4CF5,
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                final currentSet =
                                                    _selectedAnswers[_currentQuestionIndex] ??
                                                    {};
                                                if (val == true) {
                                                  currentSet.add(index);
                                                } else {
                                                  currentSet.remove(index);
                                                }
                                                _selectedAnswers[_currentQuestionIndex] =
                                                    currentSet;
                                              });
                                            },
                                          );
                                        }
                                        return RadioListTile<int>(
                                          title: Text(
                                            option.body,
                                            style: const TextStyle(
                                              color: Color(0xFF1E293B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          fillColor:
                                              WidgetStateProperty.resolveWith((
                                                states,
                                              ) {
                                                if (states.contains(
                                                  WidgetState.selected,
                                                )) {
                                                  return const Color(
                                                    0xFF6E4CF5,
                                                  );
                                                }
                                                return Colors.grey.shade400;
                                              }),
                                          value: index,
                                          activeColor: const Color(0xFF6E4CF5),
                                          groupValue:
                                              (_selectedAnswers[_currentQuestionIndex] ??
                                                      {})
                                                  .isNotEmpty
                                              ? _selectedAnswers[_currentQuestionIndex]!
                                                    .first
                                              : null,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == null) {
                                                _selectedAnswers[_currentQuestionIndex] =
                                                    {};
                                              } else {
                                                _selectedAnswers[_currentQuestionIndex] =
                                                    {val};
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppButton(
                                  text: 'Previous',
                                  onPressed: _currentQuestionIndex > 0
                                      ? () => _onQuestionChanged(
                                          _currentQuestionIndex - 1,
                                        )
                                      : null,
                                  isSecondary: true,
                                ),
                                if (_currentQuestionIndex <
                                    questions.length - 1)
                                  AppButton(
                                    text: 'Next Question',
                                    onPressed: () => _onQuestionChanged(
                                      _currentQuestionIndex + 1,
                                    ),
                                  )
                                else
                                  AppButton(
                                    text: 'Submit Assessment',
                                    onPressed: () {
                                      if (!_allQuestionsAnswered(questions)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please answer all questions before submitting.',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }
                                      _submit(questions: questions);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildNavigationSidebar(questions),
        ],
      ),
    );
  }
}
