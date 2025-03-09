import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<ConversationModel>> getUserConversations(String userId) async {
    try {
      // Récupérer les IDs des conversations auxquelles l'utilisateur participe
      final participations = await _supabase
          .from('conversation_participant')
          .select('id_conversation')
          .eq('id_user', userId);

      final conversationIds =
          participations
              .map<String>((p) => p['id_conversation'].toString())
              .toList();

      if (conversationIds.isEmpty) {
        return [];
      }

      List<ConversationModel> conversations = [];

      for (final conversationId in conversationIds) {
        // Récupérer les autres participants de chaque conversation
        final otherParticipants = await _supabase
            .from('conversation_participant')
            .select('id_user')
            .eq('id_conversation', conversationId)
            .neq('id_user', userId);

        if (otherParticipants.isEmpty) continue;

        final otherUserId = otherParticipants.first['id_user'];

        // Récupérer les informations de l'autre utilisateur
        final userData =
            await _supabase
                .from('app_user')
                .select('pseudo, photo')
                .eq('id', otherUserId)
                .single();

        // Récupérer le dernier message
        final lastMessages = await _supabase
            .from('message')
            .select()
            .eq('id_conversation', conversationId)
            .order('sent_at', ascending: false)
            .limit(1);

        String? lastMessage;
        DateTime? lastMessageDate;
        if (lastMessages.isNotEmpty) {
          lastMessage = lastMessages.first['content'];
          lastMessageDate = DateTime.parse(lastMessages.first['sent_at']);
        }

        // Compter les messages non lus
        final unreadMessages = await _supabase
            .from('message')
            .select('id_message')
            .eq('id_conversation', conversationId)
            .eq('edited', false)
            .neq('id_user_sender', userId);

        final unreadCount = unreadMessages.length;

        conversations.add(
          ConversationModel(
            id: conversationId,
            otherUserId: otherUserId,
            otherUserPseudo: userData['pseudo'],
            otherUserPhoto: userData['photo'],
            lastMessage: lastMessage,
            lastMessageDate: lastMessageDate,
            unreadCount: unreadCount,
          ),
        );
      }

      // Trier les conversations par date du dernier message
      conversations.sort((a, b) {
        if (a.lastMessageDate == null) return 1;
        if (b.lastMessageDate == null) return -1;
        return b.lastMessageDate!.compareTo(a.lastMessageDate!);
      });

      return conversations;
    } catch (e) {
      throw Exception('Échec de la récupération des conversations: $e');
    }
  }

  Future<List<MessageModel>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      final messages = await _supabase
          .from('message')
          .select()
          .eq('id_conversation', conversationId)
          .order('sent_at', ascending: false);

      return messages
          .map<MessageModel>((msg) => MessageModel.fromJson(msg))
          .toList();
    } catch (e) {
      throw Exception('Échec de la récupération des messages: $e');
    }
  }

  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String content,
  ) async {
    try {
      await _supabase.from('message').insert({
        'id_conversation': conversationId,
        'id_user_sender': senderId,
        'content': content,
        'sent_at': DateTime.now().toIso8601String(),
        'edited': false,
      });
    } catch (e) {
      throw Exception('Échec de l\'envoi du message: $e');
    }
  }

  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    try {
      await _supabase
          .from('message')
          .update({'edited': true})
          .eq('id_conversation', conversationId)
          .neq('id_user_sender', userId)
          .eq('edited', false);
    } catch (e) {
      throw Exception('Échec du marquage comme lu: $e');
    }
  }
}
