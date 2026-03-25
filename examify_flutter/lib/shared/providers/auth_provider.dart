import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  AuthState build() {
    // Schedule load user after build
    Future.microtask(() => _loadUser());
    return AuthState();
  }

  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true);
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString('access_token');

    if (token != null) {
      try {
        final userJsonStr = prefs.getString('user_data');
        if (userJsonStr != null) {
          // ...
        }
      } catch (e) {
        // failed to load user
      }
    }
    state = state.copyWith(isLoading: false);
  }

  // ─── MOCK CREDENTIALS (remove when backend is ready) ─────────────────────
  static const _mockAccounts = [
    {
      'email': 'teacher@examify.dev',
      'password': 'password',
      'id': 1,
      'name': 'Demo Teacher',
      'role': 'teacher',
    },
    {
      'email': 'student@examify.dev',
      'password': 'password',
      'id': 2,
      'name': 'Demo Student',
      'role': 'student',
    },
  ];
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // --- Mock bypass ---
    final mock = _mockAccounts.firstWhere(
      (a) => a['email'] == email && a['password'] == password,
      orElse: () => {},
    );
    if (mock.isNotEmpty) {
      await Future.delayed(
        const Duration(milliseconds: 400),
      ); // simulate latency
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('access_token', 'mock_token_${mock['id']}');
      final user = User.fromJson(mock);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    }
    // --- End mock bypass ---

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('access_token', data['access_token']);
      if (data['refresh_token'] != null) {
        await prefs.setString('refresh_token', data['refresh_token']);
      }
      if (data['expires_at'] != null) {
        await prefs.setString('expires_at', data['expires_at']);
      }

      final user = User.fromJson(data['user']);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to login. Please check credentials.',
      );
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
      final response = await dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final data = response.data;
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('access_token', data['access_token']);
      if (data['expires_at'] != null) {
        await prefs.setString('expires_at', data['expires_at']);
      }

      final user = User.fromJson(data['user']);

      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to register.');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_at');
    state = state.copyWith(clearUser: true, isLoading: false, clearError: true);
  }
}
