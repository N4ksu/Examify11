import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
final retakeRequestStatusProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, assessmentId) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/assessments/$assessmentId/my-retake-request');
    return response.data;
  } catch (e) {
    if (e is DioException && e.response?.statusCode == 404) {
      return null; // No request yet
    }
    rethrow;
  }
});

final usedRetakesProvider = FutureProvider.family<int, int>((ref, assessmentId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/assessments/$assessmentId/used-retakes');
  return response.data['used'];
});
