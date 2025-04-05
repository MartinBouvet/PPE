// lib/models/sport_model.dart
class SportModel {
  final int id;
  final String name;
  final String? description;

  SportModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: json['id_sport'],
      name: json['name'],
      description: json['description'],
    );
  }
}
