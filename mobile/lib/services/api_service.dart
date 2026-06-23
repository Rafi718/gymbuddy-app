// ignore_for_file: use_null_aware_elements

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  // Untuk development, ganti ke localhost. Untuk production, pakai Render.
  static const String _prodUrl = 'https://gymbuddy-api-production-81df.up.railway.app/api';
  static const String _devUrl = 'http://localhost:5000/api';
  static const bool _isProduction = true; // Using Railway production backend

  static String get baseUrl => _isProduction ? _prodUrl : _devUrl;

  /// Set token langsung ke default headers Dio dan cache
  static void setToken(String? token) {
    _lastToken = token;
    final dio = _instance._dio;
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      dio.options.headers.remove('Authorization');
    }
  }
  /// Token terakhir yang di-set (di-cache untuk akses cepat)
  static String? _lastToken;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip untuk login (ga perlu token)
        if (options.path.contains('/auth/login') || options.path.contains('/auth/register')) {
          return handler.next(options);
        }
        // Pastikan Authorization header selalu ada untuk request lain
        if (options.headers['Authorization'] == null && _lastToken != null) {
          options.headers['Authorization'] = 'Bearer $_lastToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          _dio.options.headers.remove('Authorization');
          _lastToken = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
        }
        return handler.next(error);
      },
    ));
  }

  Map<String, dynamic> _handleError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      String msg;
      if (data is Map) {
        msg = data['message']?.toString() ?? 'Terjadi kesalahan. Coba lagi.';
      } else if (data != null) {
        msg = data.toString();
      } else {
        msg = 'Terjadi kesalahan. Coba lagi.';
      }
      return {'success': false, 'message': msg};
    }
    return {'success': false, 'message': 'Koneksi error. Periksa internet Anda.'};
  }

  // ==================== AUTH ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data;
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }
      return data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/auth/register', data: data);
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== USER / PROFILE ====================
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final res = await _dio.get('/user/profile');
      return {'success': true, 'data': res.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/user/profile', data: data);
      return {'success': true, 'message': res.data['message'] ?? 'Profil berhasil diperbarui'};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== SESSIONS ====================
  Future<Map<String, dynamic>> getSessions({int page = 1, int limit = 10, String? search, String? kota}) async {
    try {
      final params = <String, dynamic>{'_page': page, '_limit': limit};
      if (search != null) params['search'] = search;
      if (kota != null) params['kota'] = kota;
      final res = await _dio.get('/sessions', queryParameters: params);
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSessionDetail(int id) async {
    try {
      final res = await _dio.get('/sessions/$id');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== BOOKINGS ====================
  Future<Map<String, dynamic>> createBooking(int sessionId, {String? notes}) async {
    try {
      final res = await _dio.post('/bookings', data: {
        'session_id': sessionId,
        'catatan': notes ?? '',
      });
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final res = await _dio.get('/bookings/my');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelBooking(int id) async {
    try {
      final res = await _dio.patch('/bookings/$id/status', data: {
        'status': 'Cancel',
      });
      return {'success': true, 'message': res.data['message'] ?? 'Booking dibatalkan'};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PAYMENTS ====================
  Future<Map<String, dynamic>> createPayment(int bookingId) async {
    try {
      final res = await _dio.post('/payments/create', data: {
        'booking_id': bookingId,
      });
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(int bookingId) async {
    try {
      final res = await _dio.get('/payments/$bookingId/status');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPaymentConfig() async {
    try {
      final res = await _dio.get('/payments/config');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== TRAINERS ====================
  Future<Map<String, dynamic>> getTrainers({String? search, String? kota}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null) params['nama'] = search;
      if (kota != null) params['kota'] = kota;
      final res = await _dio.get('/trainers', queryParameters: params);
      return {'success': true, 'data': res.data['data'] ?? [], 'total': res.data['total'] ?? 0};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== ARTICLES ====================
  Future<Map<String, dynamic>> getArticles({int page = 1, int limit = 10}) async {
    try {
      final res = await _dio.get('/articles', queryParameters: {
        '_page': page, '_limit': limit,
      });
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PROGRESS ====================
  Future<Map<String, dynamic>> getProgress() async {
    try {
      final res = await _dio.get('/progress');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyProgress() async {
    try {
      final res = await _dio.get('/progress/my');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addProgress(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/progress', data: data);
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== REVIEWS ====================
  Future<Map<String, dynamic>> createReview(int sessionId, int rating, String comment) async {
    try {
      final res = await _dio.post('/reviews', data: {
        'session_id': sessionId,
        'rating_score': rating,
        'comment': comment,
      });
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PROMO ====================
  Future<Map<String, dynamic>> checkPromo(String kode) async {
    try {
      final res = await _dio.get('/promo/check', queryParameters: {'kode': kode});
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== FAQ ====================
  Future<Map<String, dynamic>> getFaq({String? kategori}) async {
    try {
      final params = <String, dynamic>{
        if (kategori != null) 'kategori': kategori,
      };
      final res = await _dio.get('/faq', queryParameters: params);
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== NOTIFICATIONS ====================
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final res = await _dio.get('/notifications/my');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(int id) async {
    try {
      final res = await _dio.patch('/notifications/$id/read');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== BANNERS ====================
  Future<Map<String, dynamic>> getBanners() async {
    try {
      final res = await _dio.get('/banners');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PHOTO UPLOAD ====================
  Future<Map<String, dynamic>> uploadPhoto(File file) async {
    try {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(file.path, filename: 'profile.jpg'),
      });
      final res = await _dio.post('/upload/profile', data: formData);
      return {'success': true, 'data': res.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== TRAINER VIEWS ====================
  Future<Map<String, dynamic>> getTrainerBookingHistory() async {
    try {
      final res = await _dio.get('/views/customer-booking-history');
      return {'success': true, 'data': res.data['data'] ?? []};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== ADMIN ====================
  Future<Map<String, dynamic>> adminGetDashboard() async {
    try {
      final res = await _dio.get('/analytics/dashboard');
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> adminGetUsers({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/user/', queryParameters: {
        '_page': page, '_limit': limit,
      });
      return {'success': true, 'data': res.data['data'] ?? []};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> adminDeleteUser(int id) async {
    try {
      final res = await _dio.delete('/user/$id');
      return {'success': true, 'message': res.data['message'] ?? 'User berhasil dihapus'};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> adminGetPromos() async {
    try {
      final res = await _dio.get('/promo');
      return {'success': true, 'data': res.data['data'] ?? []};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> adminGetBookings({String? status}) async {
    try {
      final res = await _dio.get('/bookings', queryParameters: <String, dynamic>{
        if (status != null) 'status': status,
      });
      return res.data;
    } catch (e) {
      return _handleError(e);
    }
  }
}
