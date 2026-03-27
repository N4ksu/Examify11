import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
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
  bool _isCameraDenied = false;
  String? _roomName;
  int? _attemptId;

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
              if (_isCameraDenied)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📷 Camera Access Required',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your browser has blocked camera access. You cannot start the exam without it.",
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      const Text("Steps:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text("1. Look at the top-left of your screen, near the address bar.\n2. Click the Lock Icon (🔒) or Tune Icon (tune).\n3. Find Camera and change the setting to Allow.\n4. Reload this page and try again."),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (kIsWeb) {
                              html.window.location.reload();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reload Page'),
                        ),
                      ),
                    ],
                  ),
                )
              else
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
                      onPressed: (!_agreed || _isLoading) ? null : () async {
                        try {
                          setState(() => _isLoading = true);

                          if (kIsWeb) {
                            try {
                              final devices = html.window.navigator.mediaDevices;
                              if (devices != null) {
                                await (devices as dynamic).getUserMedia({'video': true});
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() {
                                _isLoading = false;
                                _isCameraDenied = true;
                              });
                              return;
                            }
                          }

                          if (_attemptId != null && _roomName != null) {
                            if (!context.mounted) return;
                            context.pushReplacement(
                              '/assessment/${widget.assessmentId}/take?attemptId=$_attemptId&roomName=$_roomName',
                            );
                            return;
                          }

                          final dio = ref.read(apiClientProvider);

                          try {
                            await dio.post('/assessments/${widget.assessmentId}/consent');
                          } catch (e) {
                            debugPrint('Consent check (possibly already recorded): $e');
                          }

                          final response = await dio.post(
                            '/assessments/${widget.assessmentId}/start',
                          );
                          _attemptId = response.data['attempt_id'];

                          ref.invalidate(assessmentDetailProvider(int.parse(widget.assessmentId)));
                          ref.invalidate(retakeRequestStatusProvider(int.parse(widget.assessmentId)));

                          final monitorResponse = await dio.post(
                            '/start-exam/${widget.assessmentId}',
                          );
                          _roomName = monitorResponse.data['room_name'];

                          if (!context.mounted) return;
                          setState(() => _isLoading = false);
                          context.pushReplacement(
                            '/assessment/${widget.assessmentId}/take?attemptId=$_attemptId&roomName=$_roomName',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to start the exam. Connection error."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E4CF5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF6E4CF5).withValues(alpha: 0.5),
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
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.center,
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
