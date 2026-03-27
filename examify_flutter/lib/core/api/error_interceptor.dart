import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'An unexpected network error occurred.';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'Could not connect to the server. Is it running?';
    } else if (err.response?.statusCode == 500) {
      message = 'Server error. Please try again later.';
    }

    // You could trigger a global notification or overlay here
    // For now, we contribute to the standardized error message
    final newErr = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: message,
    );

    return super.onError(newErr, handler);
  }
}
