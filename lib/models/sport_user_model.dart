// lib/models/sport_user_model.dart
class SportUserModel {
  final String userId;
  final int sportId;
  final String? clubName;
  final String? skillLevel;
  final bool lookingForPartners;

  SportUserModel({
    required this.userId,
    required this.sportId,
    this.clubName,
    this.skillLevel,
    this.lookingForPartners = false,
  });

  factory SportUserModel.fromJson(Map<String, dynamic> json) {
    return SportUserModel(
      userId: json['id_user'],
      sportId: json['id_sport'],
      clubName: json['club_name'],
      skillLevel: json['skill_level'],
      lookingForPartners: json['looking_for_partners'] ?? false,
    );
  }
}
