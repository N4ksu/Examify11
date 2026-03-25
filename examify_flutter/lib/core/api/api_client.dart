import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_interceptor.dart';

// Provides the SharedPreferences instance synchronously (requires override in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

final apiClientProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000/api', // Dev base URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(TokenInterceptor(dio: dio, prefs: prefs));
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
});
