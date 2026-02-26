class Poi {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String category;
  final double lat;
  final double lng;
  final int avgVisitMinutes;
  final int priority;
  final String city;
  final bool isActive;

  Poi({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.category,
    required this.lat,
    required this.lng,
    required this.avgVisitMinutes,
    required this.priority,
    required this.city,
    required this.isActive,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      category: json['category'],
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
      avgVisitMinutes: json['avg_visit_minutes'] ?? 60,
      priority: json['priority'] ?? 5,
      city: json['city'] ?? 'Goa',
      isActive: json['is_active'] ?? true,
    );
  }
}