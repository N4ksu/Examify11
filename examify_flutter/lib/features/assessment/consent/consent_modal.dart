import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/assessment.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../../retake/providers/retake_request_provider.dart';

class ConsentModal extends ConsumerStatefulWidget {
  final String assessmentId;
  const ConsentModal({super.key, required this.assessmentId});

  @override
  ConsumerState<ConsentModal> createState() => _ConsentModalState();
}

class _ConsentModalState extends ConsumerState<ConsentModal> {
  bool _agreed = false;
  bool _isLoading = false;
  String? _roomName;
  int? _attemptId;

  void _prepareExam() async {
    if (_attemptId != null && _roomName != null) {
      if (mounted) {
        context.pushReplacement(
          '/assessment/${widget.assessmentId}/take?attemptId=$_attemptId&roomName=$_roomName',
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(apiClientProvider);

      // 1. Record Consent
      try {
        await dio.post('/assessments/${widget.assessmentId}/consent');
      } catch (e) {
        debugPrint('Consent check (possibly already recorded): $e');
      }

      // 2. Start Attempt
      final response = await dio.post(
        '/assessments/${widget.assessmentId}/start',
      );
      _attemptId = response.data['attempt_id'];

      // Invalidate status & request providers to ensure UI is in sync
      ref.invalidate(assessmentDetailProvider(int.parse(widget.assessmentId)));
      ref.invalidate(
          retakeRequestStatusProvider(int.parse(widget.assessmentId)));

      // 3. Get Jitsi Room
      final monitorResponse = await dio.post(
        '/start-exam/${widget.assessmentId}',
      );
      _roomName = monitorResponse.data['room_name'];

      if (mounted) {
        context.pushReplacement(
          '/assessment/${widget.assessmentId}/take?attemptId=$_attemptId&roomName=$_roomName',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = 'Failed to start exam';
        if (e is DioException && e.response?.statusCode == 403) {
          message = e.response?.data['message'] ??
              'You have already taken this exam. Retakes are not allowed.';
          ref.invalidate(
              studentAttemptProvider(int.parse(widget.assessmentId)));
        } else if (e is DioException && e.response?.data != null) {
          message = e.response?.data['message'] ?? message;
        } else {
          message = '$message: $e';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessmentAsync = ref.watch(
      assessmentDetailProvider(int.parse(widget.assessmentId)),
    );
    final requestAsync = ref.watch(
      retakeRequestStatusProvider(int.parse(widget.assessmentId)),
    );

    return assessmentAsync.when(
      data: (assessment) {
        final lastAttempt = assessment.attempts.isNotEmpty
            ? assessment.attempts.last
            : null;
        final isSubmitted =
            lastAttempt != null && lastAttempt['status'] == 'submitted';

        if (isSubmitted) {
          return requestAsync.when(
            data: (request) {
              final isApproved = request?['status'] == 'approved';
              if (isApproved) {
                return _buildConsentUI(context);
              }
              return _buildAlreadyResponded(context, assessment, lastAttempt);
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                _buildAlreadyResponded(context, assessment, lastAttempt),
          );
        }

        return _buildConsentUI(context);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildAlreadyResponded(
    BuildContext context,
    Assessment assessment,
    dynamic attempt,
  ) {
    final score = attempt['score'];
    final totalPoints = assessment.questions.fold(
      0,
      (sum, q) => sum + q.points,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBF8),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF673AB7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You\'ve already responded',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You can fill out this form only once. \nTry contacting the owner of the form if you think this is a mistake.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF202124),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (assessment.showScore)
                      Text(
                        'Score: $score / $totalPoints',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3C4043),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pushReplacement(
                        '/attempts/${attempt['id']}/result',
                        extra: widget.assessmentId,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('View score'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentUI(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Exam Monitoring Notice',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.security_outlined,
                size: 64,
                color: Color(0xFF6E4CF5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please read carefully before starting',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This assessment is proctored. The following data will be monitored and recorded:',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildMonitoringItem(
                      Icons.visibility_outlined,
                      'Device focus and application tabbing',
                    ),
                    _buildMonitoringItem(
                      Icons.window_outlined,
                      'Unauthorized access to other tabs or windows',
                    ),
                    _buildMonitoringItem(
                      Icons.gavel_outlined,
                      'Multiple violations will result in auto-submission',
                    ),
                    _buildMonitoringItem(
                      Icons.network_ping_outlined,
                      'Your IP address and device information',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(unselectedWidgetColor: const Color(0xFF6E4CF5)),
                child: CheckboxListTile(
                  value: _agreed,
                  onChanged: (val) => setState(() => _agreed = val ?? false),
                  title: const Text(
                    'I understand and agree to be monitored',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  activeColor: const Color(0xFF6E4CF5),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _agreed && !_isLoading ? _prepareExam : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E4CF5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF6E4CF5).withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Start Exam',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonitoringItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6E4CF5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
