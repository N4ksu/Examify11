import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../providers/assessment_status_provider.dart';
import '../../retake/providers/retake_request_provider.dart';

class RetakeRequestModal extends ConsumerStatefulWidget {
  final int assessmentId;

  const RetakeRequestModal({super.key, required this.assessmentId});

  @override
  ConsumerState<RetakeRequestModal> createState() => _RetakeRequestModalState();
}

class _RetakeRequestModalState extends ConsumerState<RetakeRequestModal> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/assessments/${widget.assessmentId}/retake-requests',
        data: {'reason': _reasonController.text},
      );
      
      if (mounted) {
        // Invalidate status providers to refresh the UI
        ref.invalidate(assessmentStatusProvider(widget.assessmentId));
        ref.invalidate(retakeRequestStatusProvider(widget.assessmentId));
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retake request submitted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Failed to submit request';
        if (e is DioException) {
          if (e.response?.statusCode == 403) {
            message = 'Retakes are not allowed for this exam.';
          } else if (e.response?.statusCode == 409) {
            message = 'You already have a pending or approved request.';
          } else if (e.response?.data != null && e.response?.data['message'] != null) {
            message = e.response?.data['message'];
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6200EE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.request_page_outlined, color: Color(0xFF6200EE)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Request Retake',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Explain why you need a retake for this assessment. Your teacher will review this request.',
            style: TextStyle(color: Color(0xFF49454F), fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. My internet disconnected during the exam...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
