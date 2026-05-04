import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AppAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  AppUser? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;

  // ─── SEND OTP ─────────────────────────────────────────

  Future<bool> sendOtp({
    required String target,
    required String targetType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendOtp(target: target, targetType: targetType);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── VERIFY PHONE OTP ─────────────────────────────────

  Future<Map<String, dynamic>?> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOtp(
        target: phone,
        targetType: 'phone',
        otp: otp,
      );
      _token = result['token'];
      _user = AppUser.fromJson(result['user']);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ─── LOGIN WITH FIREBASE (after Firebase phone auth) ──

  Future<Map<String, dynamic>?> loginWithFirebase({
    required String phone,
    required String firebaseUid,
    String? firebaseToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.loginWithFirebase(
        phone: phone,
        firebaseUid: firebaseUid,
        firebaseToken: firebaseToken,
      );
      _token = result['token'];
      _user = AppUser.fromJson(result['user']);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ─── VERIFY EMAIL ─────────────────────────────────────

  Future<Map<String, dynamic>?> verifyEmail({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyEmail(email: email, otp: otp);
      // Refresh user data
      final profile = await _authService.getProfile();
      _user = AppUser.fromJson(profile['user']);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ─── COMPLETE PROFILE ─────────────────────────────────

  Future<bool> completeProfile({
    required String name,
    String? dob,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.completeProfile(name: name, dob: dob);
      _user = AppUser.fromJson(result['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── GOOGLE SIGN-IN ───────────────────────────────────

  Future<bool> googleSignIn(String idToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.googleSignIn(idToken);
      _token = result['token'];
      _user = AppUser.fromJson(result['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── CHECK AUTH STATUS ────────────────────────────────

  Future<bool> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) return false;

      final profile = await _authService.getProfile();
      _user = AppUser.fromJson(profile['user']);
      _token = await _storage.getToken();
      notifyListeners();
      return true;
    } catch (e) {
      await _authService.logout();
      _user = null;
      _token = null;
      notifyListeners();
      return false;
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    _error = null;
    notifyListeners();
  }

  String _parseError(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return error.toString();
  }
}