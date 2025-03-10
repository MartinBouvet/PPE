// lib/models/facility_model.dart
import 'dart:math' as math;

class SportFacilityModel {
  final int id;
  final String name;
  final String address;
  final String arrondissement;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String? description;
  final String? openingHours;
  final String? priceRange;
  final String? website;
  final String? phone;
  final List<int> sportIds;

  SportFacilityModel({
    required this.id,
    required this.name,
    required this.address,
    required this.arrondissement,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.description,
    this.openingHours,
    this.priceRange,
    this.website,
    this.phone,
    required this.sportIds,
  });

  factory SportFacilityModel.fromJson(Map<String, dynamic> json,
      {List<int> sports = const []}) {
    return SportFacilityModel(
      id: json['id_facility'],
      name: json['name'],
      address: json['address'],
      arrondissement: json['arrondissement'],
      latitude: json['latitude'] is double
          ? json['latitude']
          : (json['latitude'] as num).toDouble(),
      longitude: json['longitude'] is double
          ? json['longitude']
          : (json['longitude'] as num).toDouble(),
      photoUrl: json['photo_url'],
      description: json['description'],
      openingHours: json['opening_hours'],
      priceRange: json['price_range'],
      website: json['website'],
      phone: json['phone'],
      sportIds: sports,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_facility': id,
      'name': name,
      'address': address,
      'arrondissement': arrondissement,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'description': description,
      'opening_hours': openingHours,
      'price_range': priceRange,
      'website': website,
      'phone': phone,
    };
  }

  // Calculer la distance depuis la position actuelle (à implémenter avec la géolocalisation)
  // Formule de distance haversine pour calculer la distance entre deux points sur une sphère
  double calculateDistance(double userLat, double userLng) {
    const double earthRadius = 6371; // rayon de la terre en km
    final latDiff = _toRadians(userLat - latitude);
    final lngDiff = _toRadians(userLng - longitude);

    final userLatRad = _toRadians(userLat);
    final facilityLatRad = _toRadians(latitude);

    final a = math.sin(latDiff / 2) * math.sin(latDiff / 2) +
        math.cos(userLatRad) *
            math.cos(facilityLatRad) *
            math.sin(lngDiff / 2) *
            math.sin(lngDiff / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Vérifier si le lieu propose un sport spécifique
  bool hasSport(int sportId) {
    return sportIds.contains(sportId);
  }
}
