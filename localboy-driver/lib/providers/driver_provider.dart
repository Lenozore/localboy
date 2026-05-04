import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DriverProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  List<dynamic> _trips = [];
  List<dynamic> _documents = [];
  List<dynamic> _payments = [];
  bool _isLoading = false;
  bool _isAvailable = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  List<dynamic> get trips => _trips;
  List<dynamic> get documents => _documents;
  List<dynamic> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  String? get error => _error;

  // ─── AUTH ─────────────────────────────────────────────

  Future<bool> login(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Send OTP
      await _api.post('/auth/send-otp', data: {
        'target': phone,
        'target_type': 'phone',
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post('/auth/verify-otp', data: {
        'target': phone,
        'target_type': 'phone',
        'otp': otp,
        'role': 'driver',
      });

      if (response.data['token'] != null) {
        await _storage.saveToken(response.data['token']);
      }
      _user = response.data['user'];
      _isLoading = false;
      notifyListeners();
      return response.data;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> checkAuth() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return false;

      final response = await _api.get('/auth/me');
      _user = response.data['user'];
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    _user = null;
    _profile = null;
    _trips = [];
    notifyListeners();
  }

  // ─── TRIPS ────────────────────────────────────────────

  Future<void> fetchTrips() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/trips/my-trips');
      _trips = response.data as List;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> startTrip(String tripId) async {
    try {
      await _api.post('/trips/$tripId/start');
      await fetchTrips();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> completeTrip(String tripId) async {
    try {
      await _api.post('/trips/$tripId/complete');
      await fetchTrips();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ─── DOCUMENTS ────────────────────────────────────────

  Future<void> fetchDocuments() async {
    try {
      final response = await _api.get('/documents/my-documents');
      _documents = response.data as List;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> uploadDocument(String docType, String fileUrl, String fileName) async {
    try {
      await _api.post('/documents/upload', data: {
        'doc_type': docType,
        'file_url': fileUrl,
        'file_name': fileName,
      });
      await fetchDocuments();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ─── PAYMENTS ─────────────────────────────────────────

  Future<void> fetchPayments() async {
    try {
      final response = await _api.get('/payments/history');
      _payments = response.data as List;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }
}
