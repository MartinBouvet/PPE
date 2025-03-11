// lib/models/user_model.dart
class UserModel {
  final String id;
  final String? firstName;
  final String? pseudo;
  final DateTime? birthDate;
  final String? gender;
  final String? photo;
  final DateTime? inscriptionDate;
  final String? description;

  UserModel({
    required this.id,
    this.firstName,
    this.pseudo,
    this.birthDate,
    this.gender,
    this.photo,
    this.inscriptionDate,
    this.description,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      pseudo: json['pseudo'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      gender: json['gender'],
      photo: json['photo'],
      inscriptionDate: json['inscription_date'] != null
          ? DateTime.parse(json['inscription_date'])
          : null,
      description: json['description'],
    );
  }
}
