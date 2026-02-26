import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/poi.dart';
import '../servies/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Poi> _pois = [];
  List<Booking> _myBookings = [];
  bool _isLoading = false;
  String? _error;

  List<Poi> get pois => _pois;
  List<Booking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch POIs
  Future<void> fetchPois({String city = 'Goa'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/pois', params: {'city': city});
      _pois = (response.data as List)
          .map((poi) => Poi.fromJson(poi))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create booking
  Future<Booking?> createBooking({
    required DateTime tripDate,
    required String startTime,
    required String packageType,
    required String hotelAddress,
    required double hotelLat,
    required double hotelLng,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/bookings', data: {
        'trip_date': tripDate.toIso8601String().split('T')[0],
        'start_time': startTime,
        'package_type': packageType,
        'hotel_address': hotelAddress,
        'hotel_lat': hotelLat,
        'hotel_lng': hotelLng,
      });

      _isLoading = false;
      notifyListeners();
      return Booking.fromJson(response.data);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Fetch my bookings
  Future<void> fetchMyBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/bookings/my-bookings');
      _myBookings = (response.data as List)
          .map((booking) => Booking.fromJson(booking))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get booking details
  Future<Booking?> getBookingDetails(String bookingId) async {
    try {
      final response = await _api.get('/bookings/$bookingId');
      return Booking.fromJson(response.data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}