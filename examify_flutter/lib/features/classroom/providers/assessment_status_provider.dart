import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/assessment_status.dart';

final assessmentStatusProvider = FutureProvider.family<AssessmentStatus, int>((ref, assessmentId) async {
  final api = ref.read(apiClientProvider);

  // Fetch attempt and request in parallel
  // We use catchError to handle 404s gracefully (returning null)
  final attemptFuture = api.get('/assessments/$assessmentId/my-attempt')
      .then((resp) => resp.data)
      .catchError((e) => null);
      
  final requestFuture = api.get('/assessments/$assessmentId/my-retake-request')
      .then((resp) => resp.data)
      .catchError((e) => null);

  final results = await Future.wait([attemptFuture, requestFuture]);

  return AssessmentStatus.fromJson({
    'attempt': results[0],
    'request': results[1],
  });
});
