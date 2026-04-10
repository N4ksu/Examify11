import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;
  final storage = const FlutterSecureStorage();

  TokenInterceptor({required this.dio});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If not a login, register, or refresh request, check token
    if (!options.path.contains('/login') &&
        !options.path.contains('/register') &&
        !options.path.contains('/token/refresh')) {
      final String? accessToken = await storage.read(key: 'access_token');
      final String? expiresAtStr = await storage.read(key: 'expires_at');

      if (accessToken != null && expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        final now = DateTime.now().toUtc();

        // If expires within 5 minutes, refresh
        if (expiresAt.difference(now).inMinutes < 5) {
          final success = await _refreshToken();
          if (!success) {
            // Refresh failed, clear tokens
            await _clearTokens();
          }
        }
      }

      // Re-read token in case it was refreshed
      final currentToken = await storage.read(key: 'access_token');
      if (currentToken != null) {
        options.headers['Authorization'] = 'Bearer $currentToken';
      }
    }

    super.onRequest(options, handler);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    try {
      // Use a new Dio instance to avoid interceptor loop
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: dio.options.connectTimeout,
          receiveTimeout: dio.options.receiveTimeout,
          sendTimeout: dio.options.sendTimeout,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      final response = await refreshDio.post(
        '/token/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await storage.write(key: 'access_token', value: data['access_token']);
        if (data['refresh_token'] != null) {
          await storage.write(key: 'refresh_token', value: data['refresh_token']);
        }
        await storage.write(key: 'expires_at', value: data['expires_at']);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'expires_at');
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if 401 Unauthorized
    if (err.response?.statusCode == 401) {
      await _clearTokens();
      // Note: GoRouter redirection logic will pick up the logged out state
      // if we have an AuthProvider watching the token or similar mechanics.
    }
    super.onError(err, handler);
  }
}
