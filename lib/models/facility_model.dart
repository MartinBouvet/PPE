// lib/models/facility_model.dart
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
  double calculateDistance(double userLat, double userLng) {
    // Formule de distance approximative (remplacer par une formule de distance haversine pour plus de précision)
    // Cette méthode simple permettra d'avoir un ordre de grandeur de la distance en kms
    const double earthRadius = 6371; // rayon de la terre en km
    double latDiff = _toRadians(userLat - latitude);
    double lngDiff = _toRadians(userLng - longitude);

    double a = (latDiff / 2).sin() * (latDiff / 2).sin() +
        (userLat).cos() *
            (latitude).cos() *
            (lngDiff / 2).sin() *
            (lngDiff / 2).sin();
    double c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }

  // Vérifier si le lieu propose un sport spécifique
  bool hasSport(int sportId) {
    return sportIds.contains(sportId);
  }
}
