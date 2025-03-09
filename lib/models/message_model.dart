class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id_message'].toString(),
      conversationId: json['id_conversation'].toString(),
      senderId: json['id_user_sender'],
      content: json['content'],
      sentAt: DateTime.parse(json['sent_at']),
      isRead:
          json['edited'] ??
          false, // Nous utilisons le champ 'edited' comme indicateur de lecture
    );
  }
}
