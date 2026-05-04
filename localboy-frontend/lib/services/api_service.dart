import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService().getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired — user should re-login
          StorageService().deleteToken();
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) {
    return _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // ─── PAYMENT METHODS ───────────────────────────────────

  Future<Map<String, dynamic>> createPaymentOrder({
    required String bookingId,
    required double amount,
  }) async {
    final response = await post('/payments/create-order', data: {
      'booking_id': bookingId,
      'amount': amount,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await post('/payments/verify', data: {
      'order_id': orderId,
      'payment_id': paymentId,
      'signature': signature,
    });
    return response.data;
  }
}