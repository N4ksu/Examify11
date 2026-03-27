import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';

final pendingRetakeRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/retake-requests/pending');
  return List<Map<String, dynamic>>.from(response.data);
});

class RetakeRequestsScreen extends ConsumerStatefulWidget {
  const RetakeRequestsScreen({super.key});

  @override
  ConsumerState<RetakeRequestsScreen> createState() => _RetakeRequestsScreenState();
}

class _RetakeRequestsScreenState extends ConsumerState<RetakeRequestsScreen> {
  static const Color primaryViolet = Color(0xFF6E4CF5);

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(pendingRetakeRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Retake Requests', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryViolet,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: primaryViolet,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Review student requests for exam retakes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'No pending retake requests.',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  itemBuilder: (ctx, idx) {
                    final req = requests[idx];
                    final student = req['student'];
                    final assessment = req['assessment'];
                    final classroom = assessment['classroom'];
                    final requestedAt = DateTime.parse(req['requested_at']).toLocal();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: primaryViolet.withValues(alpha: 0.05),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: primaryViolet.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: primaryViolet, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                        ),
                                          Text(
                                            student['email'],
                                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(requestedAt),
                                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Exam: ${assessment['title']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Class: ${classroom['name']}',
                                    style: TextStyle(color: primaryViolet, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'REASON',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    req['reason'],
                                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _handleRequest(req['id'], 'approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _handleRequest(req['id'], 'deny'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade600,
                                            side: BorderSide(color: Colors.red.shade200),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Deny', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: primaryViolet)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load requests: $err'),
                    TextButton(
                      onPressed: () => ref.invalidate(pendingRetakeRequestsProvider),
                      child: const Text('Retry', style: TextStyle(color: primaryViolet)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRequest(int id, String action) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/retake-requests/$id/$action');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${action == 'approve' ? 'approved' : 'denied'} successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.grey.shade800,
          ),
        );
        ref.invalidate(pendingRetakeRequestsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action request: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
