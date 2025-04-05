class BadgeModel {
  final String id;
  final String name;
  final String? logo;
  final String description;
  final String requirements;
  final DateTime dateObtained;
  final bool displayedOnProfile;

  BadgeModel({
    required this.id,
    required this.name,
    this.logo,
    required this.description,
    required this.requirements,
    required this.dateObtained,
    this.displayedOnProfile = true,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id_badge'] ?? json['id'],
      name: json['name'],
      logo: json['logo'],
      description: json['description'] ?? '',
      requirements: json['requirements'] ?? '',
      dateObtained: json['date_obtained'] != null
          ? DateTime.parse(json['date_obtained'])
          : DateTime.now(),
      displayedOnProfile: json['displayed_on_profile'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'description': description,
      'requirements': requirements,
      'date_obtained': dateObtained.toIso8601String(),
      'displayed_on_profile': displayedOnProfile,
    };
  }
}
