import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Load token from SharedPreferences into ApiService cache
Future<void> initAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    ApiService.setToken(token);
  }
}

class AuthState {
  final bool isLoggedIn;
  final bool isAdmin;
  final bool isTrainer;
  final Map<String, dynamic>? user;
  final String? token;
  final String? error;
  final bool isLoading;
  /// true setelah _checkToken() selesai (awal app)
  final bool isInitialized;

  const AuthState({
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.isTrainer = false,
    this.user,
    this.token,
    this.error,
    this.isLoading = false,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isAdmin,
    bool? isTrainer,
    Map<String, dynamic>? user,
    String? token,
    String? error,
    bool? isLoading,
    bool? isInitialized,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isAdmin: isAdmin ?? this.isAdmin,
    isTrainer: isTrainer ?? this.isTrainer,
    user: user ?? this.user,
    token: token ?? this.token,
    error: error,
    isLoading: isLoading ?? this.isLoading,
    isInitialized: isInitialized ?? this.isInitialized,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _checkToken();
  }

  /// Constructor for testing with a pre-set initial state (no API calls on init)
  AuthNotifier.test(super.initialState) : _api = ApiService();

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      // Set token di cache ApiService supaya interceptor langsung bisa pakai
      ApiService.setToken(token);
      state = state.copyWith(token: token, isLoggedIn: true);
      try {
        final res = await _api.getUserProfile();
        // Jika API return error (misal token expired), throw biar masuk catch
        if (res['success'] == false) {
          throw Exception(res['message'] ?? 'Gagal load profil');
        }
        final user = res['data'] ?? res['user'];

        // Block trainer/admin dari mobile (mobile khusus customer)
        if (user != null && user['role'] != 'customer') {
          ApiService.setToken(null);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          state = state.copyWith(
            isLoggedIn: false, token: null, user: null,
            isAdmin: false, isTrainer: false,
            isInitialized: true,
          );
          return;
        }

        state = state.copyWith(
          user: user,
          isLoggedIn: true,
          isAdmin: false,
          isTrainer: false,
          isInitialized: true,
        );
      } catch (e) {
        // Token expired atau API error — clear dan tandai selesai
        ApiService.setToken(null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        state = state.copyWith(
          isLoggedIn: false, token: null, user: null,
          isAdmin: false, isTrainer: false,
          isInitialized: true,
        );
      }
    } else {
      // Tidak ada token, tandai selesai inisialisasi
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      print('[AUTH_PROVIDER] Login start: $email');
      final res = await _api.login(email, password);
      print('[AUTH_PROVIDER] Login result: $res');
      final token = res['data']?['token'] ?? res['token'];
      final user = res['data']?['user'] ?? res['user'];

      if (token == null || res['success'] == false) {
        final errMsg = res['message'] ?? 'Email atau password salah';
        final errCode = res['code'] ?? res['error']?['code'];
        print('[AUTH_PROVIDER] Login failed. errMsg=$errMsg errCode=$errCode');
        state = state.copyWith(
          isLoading: false,
          error: errMsg,
        );
        // If email not verified, navigate to OTP
        if (errCode == 'EMAIL_NOT_VERIFIED' && mounted) {
          state = state.copyWith(error: errMsg);
        }
        return;
      }

      // Set token di cache ApiService IMMEDIATELY (synchronous)
      ApiService.setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      // Block trainer/admin dari login di mobile (mobile khusus customer)
      if (user != null && user['role'] != 'customer') {
        ApiService.setToken(null);
        await prefs.remove('token');
        state = state.copyWith(
          isLoading: false,
          error: 'Akun ${user?['role'] == 'admin' ? 'admin' : 'trainer'} tidak dapat digunakan di aplikasi mobile. Silakan login melalui website.',
        );
        return;
      }

      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        user: user,
        isAdmin: false,
        isTrainer: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login gagal. Periksa email dan password Anda.',
      );
    }
  }

  Future<String?> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      print('[AUTH_PROVIDER] Register start: ${data['email']}');
      final res = await _api.register(data);
      print('[AUTH_PROVIDER] Register result: $res');
      if (res['success'] == false) {
        state = state.copyWith(
          isLoading: false,
          error: res['message'] ?? 'Registrasi gagal. Coba lagi.',
        );
        return null;
      }
      state = state.copyWith(isLoading: false, error: null);
      final email = res['data']?['email'] ?? data['email'] as String?;
      print('[AUTH_PROVIDER] Register returning email: $email');
      return email;
    } catch (e) {
      print('[AUTH_PROVIDER] Register exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Registrasi gagal. Coba lagi.',
      );
      return null;
    }
  }

  Future<void> _logout() async {
    ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = const AuthState(isInitialized: true);
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
