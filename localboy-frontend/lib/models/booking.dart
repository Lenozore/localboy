class Booking {
  final String id;
  final String? bookingCode;
  final DateTime tripDate;
  final String startTime;
  final String tripType;     // half_day, full_day
  final String? pickupAddress;
  final double? touristCharge;
  final double? platformFee;
  final double? driverPayout;
  final double? guidePayout;
  final double? totalDistanceKm;
  final String status;
  final List<ItineraryItem>? itinerary;
  final DateTime createdAt;

  Booking({
    required this.id,
    this.bookingCode,
    required this.tripDate,
    required this.startTime,
    required this.tripType,
    this.pickupAddress,
    this.touristCharge,
    this.platformFee,
    this.driverPayout,
    this.guidePayout,
    this.totalDistanceKm,
    required this.status,
    this.itinerary,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      bookingCode: json['booking_code'],
      tripDate: DateTime.parse(json['trip_date']),
      startTime: json['start_time'] ?? '',
      tripType: json['trip_type'] ?? json['package_type'] ?? 'half_day',
      pickupAddress: json['pickup_address'] ?? json['hotel_address'],
      touristCharge: json['tourist_charge'] != null
          ? (json['tourist_charge'] as num).toDouble()
          : null,
      platformFee: json['platform_fee'] != null
          ? (json['platform_fee'] as num).toDouble()
          : null,
      driverPayout: json['driver_payout'] != null
          ? (json['driver_payout'] as num).toDouble()
          : null,
      guidePayout: json['guide_payout'] != null
          ? (json['guide_payout'] as num).toDouble()
          : null,
      totalDistanceKm: json['total_distance_km'] != null
          ? (json['total_distance_km'] as num).toDouble()
          : null,
      status: json['status'] ?? 'pending',
      itinerary: json['stops'] != null
          ? (json['stops'] as List)
              .map((s) => ItineraryItem.fromJson(s))
              .toList()
          : (json['itinerary'] != null
              ? (json['itinerary'] as List)
                  .map((s) => ItineraryItem.fromJson(s))
                  .toList()
              : null),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ItineraryItem {
  final String id;
  final String? poiId;
  final int stopOrder;
  final String? estimatedArrival;
  final String? status;
  final ItineraryPoi? poi;

  ItineraryItem({
    required this.id,
    this.poiId,
    required this.stopOrder,
    this.estimatedArrival,
    this.status,
    this.poi,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'],
      poiId: json['poi_id'],
      stopOrder: json['stop_order'] ?? 0,
      estimatedArrival: json['estimated_arrival'],
      status: json['status'],
      poi: json['poi'] != null ? ItineraryPoi.fromJson(json['poi']) : null,
    );
  }
}

class ItineraryPoi {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final List<String>? photoUrls;

  ItineraryPoi({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.photoUrls,
  });

  factory ItineraryPoi.fromJson(Map<String, dynamic> json) {
    return ItineraryPoi(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'])
          : null,
    );
  }
}