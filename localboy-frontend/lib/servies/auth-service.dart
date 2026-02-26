import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await _api.post('/auth/send-otp', data: {
        'phone': phone,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final response = await _api.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });

      // Save token and user
      final token = response.data['token'];
      final userData = response.data['user'];

      await _storage.saveToken(token);
      await _storage.saveUser(User.fromJson(userData));

      return response.data;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    return await _storage.getUser();
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }
}