// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/api_client.dart';
import 'package:camera/camera.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/violation_banner.dart';
import '../../../shared/widgets/security_watermark.dart';
import 'widgets/sync_status_indicator.dart';
import 'widgets/session_locked_overlay.dart';
import '../../../shared/models/assessment.dart';
import '../../../shared/models/question.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/sync/sync_provider.dart';
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

class _TakeAssessmentScreenState extends ConsumerState<TakeAssessmentScreen> with WidgetsBindingObserver {
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


  // Camera tracking
  CameraController? _cameraController;
  Timer? _focusTimer;
  int _violationStrikes = 0;

  List<Question>? _loadedQuestions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.roomName != null) {
      _requestPermissions();
    }
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_focusTimer != null && _focusTimer!.isActive) return;
      
      _focusTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _violationStrikes++;
          _violationCount = _violationStrikes;
        });

        if (_violationStrikes == 1) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('⚠️ Warning 1/3'),
              content: const Text('You left the exam window. Do not switch tabs or open other apps.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('I Understand'),
                ),
              ],
            ),
          );
          return;
        } else if (_violationStrikes == 2) {
          if (_cameraController != null && _cameraController!.value.isInitialized) {
            ref.read(syncProvider.notifier).captureSnapshot(
                  widget.attemptId, 
                  isViolation: true, 
                  customCaption: "🚨 **STRIKE 2: TAB SWITCH DETECTED**",
                );
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('🚨 Warning 2/3'),
              content: const Text('Violation recorded and sent to your instructor. One more violation will terminate your exam.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('I Understand'),
                ),
              ],
            ),
          );
          return;
        } else if (_violationStrikes >= 3) {
          if (_cameraController != null && _cameraController!.value.isInitialized) {
            ref.read(syncProvider.notifier).captureSnapshot(
                  widget.attemptId, 
                  isViolation: true, 
                  customCaption: "⛔ **STRIKE 3: EXAM TERMINATED**",
                );
          }
          // Force auto-submit immediately
          _submit(autoSubmit: true, questions: _loadedQuestions);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('⛔ Exam Terminated'),
              content: const Text('You have been locked out due to multiple tab-switching violations.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          return;
        }
      });
    } else if (state == AppLifecycleState.resumed) {
      if (_focusTimer != null && _focusTimer!.isActive) {
        _focusTimer!.cancel();
        debugPrint("Micro-distraction recovered");
      }
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera].request();
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

  Future<void> _initCamera() async {
    try {
      // 1. Initialize Webcam (for the PiP display)
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.low,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }

      // 2. Delegate proctoring capture to SyncProvider
      ref.read(syncProvider.notifier).startCapture(_cameraController, widget.attemptId);
    } catch (e) {
      debugPrint('Camera/Screen init error: $e');
    }
  }


  @override
  void dispose() {
    _focusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    ref.read(syncProvider.notifier).stopCapture();
    _cameraController?.dispose();
    
    if (!kIsWeb) {
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
            color: color.withValues(alpha: 0.2),
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

  void _syncAnswerForQuestion(Question q, int index) {
      final attemptId = widget.attemptId;
      final List<Map<String, dynamic>> answerData = [];
      
      if (q.type == 'essay') {
          answerData.add({
              'question_id': q.id,
              'text_response': _essayAnswers[index] ?? '',
          });
      } else if (q.type == 'multiple_select') {
          final selectedIndices = _selectedAnswers[index] ?? {};
          for (final idx in selectedIndices) {
              answerData.add({'question_id': q.id, 'option_id': q.options[idx].id});
          }
      } else {
          final selectedSet = _selectedAnswers[index];
          final selectedIdx = (selectedSet != null && selectedSet.isNotEmpty)
              ? selectedSet.first
              : null;
          if (selectedIdx != null) {
              answerData.add({
                  'question_id': q.id,
                  'option_id': q.options[selectedIdx].id,
              });
          }
      }
      
      ref.read(syncProvider.notifier).saveAnswerLocally(attemptId, q.id, answerData);
      
      // Show snackbar if transitioning to offline
      final syncState = ref.read(syncProvider);
      if (!syncState.isOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Working Offline - Answers Saved Locally'),
                duration: Duration(seconds: 2),
              )
          );
      }
  }

  void _submit({bool autoSubmit = false, List<Question>? questions}) async {
    _timer?.cancel();

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
        if (e.toString().contains('403') || e.toString().contains('Session Hijacking')) {
           ref.read(syncProvider.notifier).markSessionLocked();
           return;
        }
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
    final syncState = ref.watch(syncProvider);
    if (syncState.isSessionLocked) {
       return SessionLockedOverlay(attemptId: widget.attemptId);
    }
    
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

  Widget _buildMainLayout(BuildContext context, Assessment assessment) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildExamUI(context, assessment),
            _buildCameraPiP(),
          ],
        );
      },
    );
  }

  Widget _buildCameraPiP() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Positioned(
      right: 16,
      bottom: 16,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildExamUI(BuildContext context, Assessment assessment) {
    final questions = assessment.questions;
    final user = ref.watch(authProvider).user;
    
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

    return SecurityWatermark(
      userId: user?.id.toString() ?? 'Unknown User',
      ipAddress: '127.0.0.1', // Placeholder for IP
      child: Scaffold(
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
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SyncStatusIndicator(),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Force Offline', style: TextStyle(color: Colors.white, fontSize: 10)),
                      SizedBox(
                        height: 24,
                        child: Switch(
                          value: !ref.watch(syncProvider).isOnline,
                          activeThumbColor: Colors.orange,
                          onChanged: (val) {
                            ref.read(syncProvider.notifier).toggleForcedOffline(val);
                            if (!val) {
                               // Try to sync if coming back online
                               ref.read(syncProvider.notifier).forceSync(widget.attemptId);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
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
                                ? Colors.red.withValues(alpha: 0.8)
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
                                          _syncAnswerForQuestion(currentQuestion, _currentQuestionIndex);
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
                                              _syncAnswerForQuestion(currentQuestion, _currentQuestionIndex);
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
                                            _syncAnswerForQuestion(currentQuestion, _currentQuestionIndex);
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
     ),
    );
  }
}
