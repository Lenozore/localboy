import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/poi.dart';
import '../services/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Poi> _pois = [];
  List<Poi> _nearbyPois = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Poi> get pois => _pois;
  List<Poi> get nearbyPois => _nearbyPois;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPois({String? city}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/pois', params: city != null ? {'city': city} : null);
      _pois = (response.data as List).map((json) => Poi.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNearbyPois(double lat, double lng, {double radius = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/pois/nearby', params: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
      });
      _nearbyPois = (response.data as List).map((json) => Poi.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/bookings/my-bookings');
      _bookings = (response.data as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

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
      final response = await _api.post('/trips/create', data: {
        'trip_type': packageType,
        'trip_date': tripDate.toIso8601String(),
        'start_time': startTime,
        'pickup_address': hotelAddress,
        'start_lat': hotelLat,
        'start_lng': hotelLng,
        'poi_ids': [],
        'total_distance_km': 0,
        'tourist_charge': packageType == 'half_day' ? 1499 : 2499,
        'platform_fee': packageType == 'half_day' ? 299 : 499,
        'driver_payout': packageType == 'half_day' ? 900 : 1500,
        'guide_payout': packageType == 'half_day' ? 300 : 500,
      });
      final booking = Booking.fromJson(response.data);
      _bookings.insert(0, booking);
      _isLoading = false;
      notifyListeners();
      return booking;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Booking?> getBookingDetails(String bookingId) async {
    try {
      final response = await _api.get('/trips/$bookingId');
      return Booking.fromJson(response.data);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
}