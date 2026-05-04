import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  final StorageService _storage = StorageService();

  // ─── SEND OTP ───────────────────────────────────────────

  Future<Map<String, dynamic>> sendOtp({
    required String target,
    required String targetType, // 'phone' or 'email'
  }) async {
    final response = await _dio.post('/auth/send-otp', data: {
      'target': target,
      'target_type': targetType,
    });
    return response.data;
  }

  // ─── VERIFY OTP ─────────────────────────────────────────

  Future<Map<String, dynamic>> verifyOtp({
    required String target,
    required String targetType,
    required String otp,
  }) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'target': target,
      'target_type': targetType,
      'otp': otp,
      'role': 'tourist',
    });

    // Save token
    if (response.data['token'] != null) {
      await _storage.saveToken(response.data['token']);
    }

    return response.data;
  }

  // ─── LOGIN WITH FIREBASE (after Firebase phone auth) ──

  Future<Map<String, dynamic>> loginWithFirebase({
    required String phone,
    required String firebaseUid,
    String? firebaseToken,
  }) async {
    final response = await _dio.post('/auth/firebase-login', data: {
      'phone': phone,
      'firebase_uid': firebaseUid,
      'role': 'tourist',
      if (firebaseToken != null) 'firebase_token': firebaseToken,
    });

    // Save token
    if (response.data['token'] != null) {
      await _storage.saveToken(response.data['token']);
    }

    return response.data;
  }

  // ─── VERIFY EMAIL (authenticated) ──────────────────────

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final token = await _storage.getToken();
    final response = await _dio.post(
      '/auth/verify-email',
      data: {'email': email, 'otp': otp},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ─── COMPLETE PROFILE (authenticated) ──────────────────

  Future<Map<String, dynamic>> completeProfile({
    required String name,
    String? dob,
  }) async {
    final token = await _storage.getToken();
    final response = await _dio.post(
      '/auth/complete-profile',
      data: {
        'name': name,
        if (dob != null) 'dob': dob,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ─── GOOGLE SIGN-IN ────────────────────────────────────

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final response = await _dio.post('/auth/google', data: {
      'id_token': idToken,
    });

    if (response.data['token'] != null) {
      await _storage.saveToken(response.data['token']);
    }

    return response.data;
  }

  // ─── GET PROFILE ───────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _storage.getToken();
    final response = await _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  // ─── LOGOUT ────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.deleteToken();
  }

  // ─── CHECK IF LOGGED IN ────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }
}