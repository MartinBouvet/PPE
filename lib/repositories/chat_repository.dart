import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final _supabase = SupabaseConfig.client;

  // Données statiques pour Elise
  static const String ELISE_ID = '39dc52c6-6f4c-4d8c-b81b-d7105e160c9a';
  static const String ELISE_PSEUDO = 'Elise';
  static const String ELISE_PHOTO =
      'https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=800';

  // Conversation factice avec Elise
  Future<String?> createConversationWithElise(String currentUserId) async {
    return 'elise_conversation_${currentUserId}';
  }

  // Conversations avec Elise incluse
  Future<List<ConversationModel>> getUserConversations(String userId) async {
    List<ConversationModel> conversations = [];

    try {
      // Ajouter Elise manuellement
      conversations.add(ConversationModel(
        id: 'elise_conversation_$userId',
        otherUserId: ELISE_ID,
        otherUserPseudo: ELISE_PSEUDO,
        otherUserPhoto: ELISE_PHOTO,
        lastMessage: 'Salut ! Comment vas-tu ?',
        lastMessageDate: DateTime.now(),
        unreadCount: 0,
      ));

      try {
        // Autres conversations Supabase
      } catch (e) {
        debugPrint('Erreur récupération conversations: $e');
      }
    } catch (e) {
      debugPrint('Erreur récupération conversations: $e');
    }

    return conversations;
  }

  // Messages locaux pour Elise
  final Map<String, List<MessageModel>> _localMessages = {};

  // Récupération messages
  Future<List<MessageModel>> getConversationMessages(
      String conversationId) async {
    if (conversationId.startsWith('elise_conversation_')) {
      if (!_localMessages.containsKey(conversationId)) {
        final now = DateTime.now();
        _localMessages[conversationId] = [
          MessageModel(
            id: 'initial_msg',
            conversationId: conversationId,
            senderId: ELISE_ID,
            content: 'Salut ! Je suis Elise. Comment vas-tu ?',
            sentAt: now.subtract(const Duration(minutes: 5)),
            isRead: true,
          ),
        ];
      }
      return _localMessages[conversationId] ?? [];
    }

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
      debugPrint('Erreur récupération messages: $e');
      return [];
    }
  }

  // Envoi message
  Future<bool> sendMessage(
      String conversationId, String senderId, String content) async {
    if (content.trim().isEmpty) return false;

    if (conversationId.startsWith('elise_conversation_')) {
      if (!_localMessages.containsKey(conversationId)) {
        _localMessages[conversationId] = [];
      }

      _localMessages[conversationId]!.insert(
        0,
        MessageModel(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderId: senderId,
          content: content,
          sentAt: DateTime.now(),
          isRead: true,
        ),
      );

      return true;
    }

    try {
      await _supabase.from('message').insert({
        'id_conversation': conversationId,
        'id_user_sender': senderId,
        'content': content,
        'sent_at': DateTime.now().toIso8601String(),
        'edited': false,
      });
      return true;
    } catch (e) {
      debugPrint('Erreur envoi message: $e');
      return false;
    }
  }

  // Marquage comme lu
  Future<bool> markConversationAsRead(
      String conversationId, String userId) async {
    if (conversationId.startsWith('elise_conversation_')) {
      return true;
    }

    try {
      await _supabase
          .from('message')
          .update({'edited': true})
          .eq('id_conversation', conversationId)
          .neq('id_user_sender', userId)
          .eq('edited', false);
      return true;
    } catch (e) {
      debugPrint('Erreur marquage lu: $e');
      return false;
    }
  }

  // Fonction vide pour compatibilité
  Future<bool> addEliseAsFriend(String currentUserId) async {
    return true;
  }
}
