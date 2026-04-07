import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;
  final SharedPreferences prefs;

  TokenInterceptor({required this.dio, required this.prefs});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If not a login, register, or refresh request, check token
    if (!options.path.contains('/login') &&
        !options.path.contains('/register') &&
        !options.path.contains('/token/refresh')) {
      final String? accessToken = prefs.getString('access_token');
      final String? expiresAtStr = prefs.getString('expires_at');

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
      final currentToken = prefs.getString('access_token');
      if (currentToken != null) {
        options.headers['Authorization'] = 'Bearer $currentToken';
      }
    }

    super.onRequest(options, handler);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = prefs.getString('refresh_token');
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
        await prefs.setString('access_token', data['access_token']);
        if (data['refresh_token'] != null) {
          await prefs.setString('refresh_token', data['refresh_token']);
        }
        await prefs.setString('expires_at', data['expires_at']);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> _clearTokens() async {
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_at');
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
