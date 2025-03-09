class ConversationModel {
  final String id;
  final String? otherUserId;
  final String? otherUserPseudo;
  final String? otherUserPhoto;
  final String? lastMessage;
  final DateTime? lastMessageDate;
  final int unreadCount;

  ConversationModel({
    required this.id,
    this.otherUserId,
    this.otherUserPseudo,
    this.otherUserPhoto,
    this.lastMessage,
    this.lastMessageDate,
    this.unreadCount = 0,
  });
}
