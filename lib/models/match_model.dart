class MatchModel {
  final String? id;
  final String requesterId;
  final String likedUserId;
  final String requestStatus; // 'pending', 'accepted', 'rejected'
  final DateTime requestDate;
  final DateTime? responseDate;

  MatchModel({
    this.id,
    required this.requesterId,
    required this.likedUserId,
    required this.requestStatus,
    required this.requestDate,
    this.responseDate,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id_match']?.toString(),
      requesterId: json['id_user_requester'],
      likedUserId: json['id_user_liked'],
      requestStatus: json['request_status'],
      requestDate: DateTime.parse(json['request_date']),
      responseDate: json['response_date'] != null
          ? DateTime.parse(json['response_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_match': id,
      'id_user_requester': requesterId,
      'id_user_liked': likedUserId,
      'request_status': requestStatus,
      'request_date': requestDate.toIso8601String(),
      'response_date': responseDate?.toIso8601String(),
    };
  }
}
