import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_interceptor.dart';
import 'error_interceptor.dart';
import '../../shared/providers/auth_provider.dart';

// Provides the SharedPreferences instance synchronously (requires override in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://localhost:8000/api',
      ),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final authNotifier = ref.read(authProvider.notifier);

  dio.interceptors.addAll([
    TokenInterceptor(
      dio: dio,
      onUnauthorized: () => authNotifier.forceLogout(),
    ),
    ErrorInterceptor(),
    if (kDebugMode)
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ),
  ]);

  return dio;
});
