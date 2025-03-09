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

  Map<String, dynamic> toJson() {
    return {
      'id_user': userId,
      'id_sport': sportId,
      'club_name': clubName,
      'skill_level': skillLevel,
      'looking_for_partners': lookingForPartners,
    };
  }

  // Créer une copie avec des modifications
  SportUserModel copyWith({
    String? userId,
    int? sportId,
    String? clubName,
    String? skillLevel,
    bool? lookingForPartners,
  }) {
    return SportUserModel(
      userId: userId ?? this.userId,
      sportId: sportId ?? this.sportId,
      clubName: clubName ?? this.clubName,
      skillLevel: skillLevel ?? this.skillLevel,
      lookingForPartners: lookingForPartners ?? this.lookingForPartners,
    );
  }
}
