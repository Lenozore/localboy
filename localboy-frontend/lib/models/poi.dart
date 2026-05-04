class Poi {
  final String id;
  final String name;
  final String description;
  final String imageUrl;       // legacy single image fallback
  final List<String>? photoUrls; // new: array of real photo URLs
  final String category;
  final double lat;
  final double lng;
  final int avgVisitMinutes;
  final int popularityScore;
  final String city;
  final bool isActive;
  final double? distanceKm;   // populated by /pois/nearby endpoint

  Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.photoUrls,
    required this.category,
    required this.lat,
    required this.lng,
    required this.avgVisitMinutes,
    required this.popularityScore,
    required this.city,
    required this.isActive,
    this.distanceKm,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    List<String>? urls;
    if (json['photo_urls'] != null) {
      urls = List<String>.from(json['photo_urls']);
    }

    return Poi(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      imageUrl: urls?.isNotEmpty == true
          ? urls!.first
          : (json['image_url'] ?? ''),
      photoUrls: urls,
      category: json['category'] ?? 'general',
      lat: (json['lat'] is String ? double.parse(json['lat']) : json['lat']).toDouble(),
      lng: (json['lng'] is String ? double.parse(json['lng']) : json['lng']).toDouble(),
      avgVisitMinutes: json['avg_visit_minutes'] ?? 60,
      popularityScore: json['popularity_score'] ?? json['priority'] ?? 5,
      city: json['city'] ?? 'Goa',
      isActive: json['is_active'] ?? true,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photo_urls': photoUrls,
      'category': category,
      'lat': lat,
      'lng': lng,
      'avg_visit_minutes': avgVisitMinutes,
      'popularity_score': popularityScore,
      'city': city,
      'is_active': isActive,
    };
  }
}