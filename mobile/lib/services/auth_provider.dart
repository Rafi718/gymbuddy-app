import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isAdmin;
  final bool isTrainer;
  final Map<String, dynamic>? user;
  final String? token;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.isTrainer = false,
    this.user,
    this.token,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isAdmin,
    bool? isTrainer,
    Map<String, dynamic>? user,
    String? token,
    String? error,
    bool? isLoading,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isAdmin: isAdmin ?? this.isAdmin,
    isTrainer: isTrainer ?? this.isTrainer,
    user: user ?? this.user,
    token: token ?? this.token,
    error: error,
    isLoading: isLoading ?? this.isLoading,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _checkToken();
  }

  /// Constructor for testing with a pre-set initial state (no API calls on init)
  AuthNotifier.test(AuthState initialState) : _api = ApiService(), super(initialState);

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      state = state.copyWith(token: token, isLoggedIn: true);
      try {
        final res = await _api.getUserProfile();
        final user = res['data'] ?? res['user'];
        state = state.copyWith(
          user: user,
          isLoggedIn: true,
          isAdmin: user?['role'] == 'admin',
          isTrainer: user?['role'] == 'trainer',
        );
      } catch (e) {
        await _logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.login(email, password);
      final token = res['token'] ?? res['data']?['token'];
      final user = res['user'] ?? res['data']?['user'];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }

      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        user: user,
        isAdmin: user?['role'] == 'admin',
        isTrainer: user?['role'] == 'trainer',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login gagal. Periksa email dan password Anda.',
      );
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.register(data);
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registrasi gagal. Coba lagi.',
      );
      return false;
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = const AuthState();
  }

  Future<void> logout() => _logout();

  Future<void> refreshUser() async {
    try {
      final res = await _api.getUserProfile();
      final user = res['data'] ?? res['user'];
      if (user != null) {
        state = state.copyWith(
          user: user,
          isAdmin: user['role'] == 'admin',
          isTrainer: user['role'] == 'trainer',
        );
      }
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService());
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});
