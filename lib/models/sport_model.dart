// lib/models/sport_model.dart
class SportModel {
  final int id;
  final String name;
  final String? logo;
  final String? description;

  SportModel({
    required this.id,
    required this.name,
    this.logo,
    this.description,
  });

  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: json['id_sport'],
      name: json['name'],
      logo: json['logo'],
      description: json['description'],
    );
  }
}
