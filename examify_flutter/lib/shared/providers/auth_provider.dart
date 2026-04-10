import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../models/user.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState({this.isLoading = true, this.user, this.error});

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    Future.microtask(() => _loadUser());
    return AuthState();
  }

  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true);
    
    final token = await _storage.read(key: 'access_token');

    if (token != null) {
      try {
        final userJsonStr = await _storage.read(key: 'user_data');
        if (userJsonStr != null) {
           final user = User.fromJson(jsonDecode(userJsonStr));
           state = state.copyWith(user: user);
        }
      } catch (e) {
        // failed to load user
      }
    }
    state = state.copyWith(isLoading: false);
  }

  Future<bool> login(String email, String password, bool remember) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/login',
        data: {'email': email, 'password': password, 'remember_me': remember},
      );

      final data = response.data;
      await _storage.write(key: 'access_token', value: data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      }
      if (data['expires_at'] != null) {
        await _storage.write(key: 'expires_at', value: data['expires_at']);
      }

      final user = User.fromJson(data['user']);
      await _storage.write(key: 'user_data', value: jsonEncode(data['user']));

      state = state.copyWith(isLoading: false, user: user);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Failed to login. Please try again.';
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          errorMessage = 'Invalid email or password.';
        } else if (e.response!.statusCode == 422) {
          errorMessage = 'Validation error. Please check your inputs.';
        } else if (e.response!.statusCode == 429) {
          errorMessage = 'Too many attempts. Please try again later.';
        } else if (e.response!.statusCode! >= 500) {
          errorMessage = 'Server error. Please try again later.';
        }
      } else {
         errorMessage = 'Network error. Please check your connection.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Failed to register. Please try again.';
      if (e.response != null) {
        if (e.response!.statusCode == 422) {
          final data = e.response!.data;
          if (data is Map && data['errors'] != null && (data['errors'] as Map).isNotEmpty) {
            errorMessage = (data['errors'] as Map).values.first[0].toString();
          } else if (data is Map && data['message'] != null) {
            errorMessage = data['message'].toString();
          } else {
             errorMessage = 'Validation error. Please check your inputs.';
          }
        } else if (e.response!.statusCode! >= 500) {
          errorMessage = 'Server error. Please try again later.';
        }
      } else {
         errorMessage = 'Network error. Please check your connection.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_at');
    await _storage.delete(key: 'user_data');
    state = state.copyWith(clearUser: true, isLoading: false, clearError: true);
  }
}
