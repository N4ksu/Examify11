import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;
  final VoidCallback? onUnauthorized;
  final storage = const FlutterSecureStorage();

  TokenInterceptor({required this.dio, this.onUnauthorized});

  // Share a single refresh future among all requests to prevent race conditions
  Future<bool>? _refreshFuture;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String path = options.path;
    
    // Auth routes that never need any token or refresh logic
    final bool isPublicAuthRoute = path.contains('/login') ||
        path.contains('/register') ||
        path.contains('/token/refresh');
    
    // Special case: Logout needs the token injected, but should NEVER trigger a refresh
    final bool isLogoutRoute = path.contains('/logout');

    if (!isPublicAuthRoute) {
      final String? accessToken = await storage.read(key: 'access_token');
      final String? expiresAtStr = await storage.read(key: 'expires_at');

      // Only check for refresh if it's NOT a logout request
      if (!isLogoutRoute && accessToken != null && expiresAtStr != null) {
        try {
          final expiresAt = DateTime.parse(expiresAtStr).toUtc();
          final now = DateTime.now().toUtc();

          // If expires within 5 minutes, refresh
          if (expiresAt.difference(now).inMinutes < 5) {
            _refreshFuture ??= _refreshToken();
            final success = await _refreshFuture;
            _refreshFuture = null;

            if (success != true) {
              await _clearTokens();
              onUnauthorized?.call();
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Session expired',
                  type: DioExceptionType.cancel,
                ),
              );
            }
          }
        } catch (e) {
          await _clearTokens();
          onUnauthorized?.call();
        }
      }

      // Inject the current token (cached or freshly refreshed)
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
    await storage.delete(key: 'user_data');
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If 401 Unauthorized, trigger forced local logout
    if (err.response?.statusCode == 401) {
      final String path = err.requestOptions.path;
      // Don't trigger logout if the 401 comes from login itself
      if (!path.contains('/login')) {
        await _clearTokens();
        onUnauthorized?.call();
      }
    }
    super.onError(err, handler);
  }
}
