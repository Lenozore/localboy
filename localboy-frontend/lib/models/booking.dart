import 'package:localboy_tourist_app/models/poi.dart';

class Booking {
  final String id;
  final String userId;
  final String bookingCode;
  final DateTime tripDate;
  final String startTime;
  final String packageType;
  final String hotelAddress;
  final double hotelLat;
  final double hotelLng;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final List<ItineraryItem>? itinerary;

  Booking({
    required this.id,
    required this.userId,
    required this.bookingCode,
    required this.tripDate,
    required this.startTime,
    required this.packageType,
    required this.hotelAddress,
    required this.hotelLat,
    required this.hotelLng,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.itinerary,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      bookingCode: json['booking_code'],
      tripDate: DateTime.parse(json['trip_date']),
      startTime: json['start_time'],
      packageType: json['package_type'],
      hotelAddress: json['hotel_address'],
      hotelLat: double.parse(json['hotel_lat'].toString()),
      hotelLng: double.parse(json['hotel_lng'].toString()),
      status: json['status'],
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      itinerary: json['itinerary'] != null
          ? (json['itinerary'] as List)
              .map((i) => ItineraryItem.fromJson(i))
              .toList()
          : null,
    );
  }
}

class ItineraryItem {
  final String id;
  final String bookingId;
  final String poiId;
  final int stopOrder;
  final String? estimatedArrival;
  final String status;
  final Poi? poi;

  ItineraryItem({
    required this.id,
    required this.bookingId,
    required this.poiId,
    required this.stopOrder,
    this.estimatedArrival,
    required this.status,
    this.poi,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'],
      bookingId: json['booking_id'],
      poiId: json['poi_id'],
      stopOrder: json['stop_order'],
      estimatedArrival: json['estimated_arrival'],
      status: json['status'] ?? 'pending',
      poi: json['poi'] != null ? Poi.fromJson(json['poi']) : null,
    );
  }
}