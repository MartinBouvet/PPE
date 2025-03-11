import 'package:flutter/foundation.dart';
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

      final conversationIds = participations
          .map<String>((p) => p['id_conversation'].toString())
          .toList();

      if (conversationIds.isEmpty) {
        return [];
      }

      List<ConversationModel> conversations = [];

      for (final conversationId in conversationIds) {
        try {
          // Récupérer les autres participants de chaque conversation
          final otherParticipants = await _supabase
              .from('conversation_participant')
              .select('id_user')
              .eq('id_conversation', conversationId)
              .neq('id_user', userId);

          if (otherParticipants.isEmpty) continue;

          final otherUserId = otherParticipants.first['id_user'];

          // Récupérer les informations de l'autre utilisateur
          final userData = await _supabase
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
              .eq('edited',
                  false) // 'edited' utilisé comme indicateur de lecture
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
        } catch (e) {
          debugPrint(
              'Erreur lors du traitement de la conversation $conversationId: $e');
          // Continuer avec la prochaine conversation même si une erreur se produit
          continue;
        }
      }

      // Trier les conversations par date du dernier message
      conversations.sort((a, b) {
        if (a.lastMessageDate == null) return 1;
        if (b.lastMessageDate == null) return -1;
        return b.lastMessageDate!.compareTo(a.lastMessageDate!);
      });

      return conversations;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des conversations: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getConversationMessages(
      String conversationId) async {
    try {
      final messages = await _supabase
          .from('message') // Vérifiez que c'est 'message' et non 'messages'
          .select()
          .eq('id_conversation', conversationId)
          .order('sent_at', ascending: false);

      return messages
          .map<MessageModel>((msg) => MessageModel.fromJson(msg))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des messages: $e');
      return [];
    }
  }

  Future<bool> sendMessage(
      String conversationId, String senderId, String content) async {
    if (content.trim().isEmpty) {
      return false;
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
      debugPrint('Erreur lors de l\'envoi du message: $e');
      return false;
    }
  }

  Future<bool> markConversationAsRead(
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
      return true;
    } catch (e) {
      debugPrint('Erreur lors du marquage comme lu: $e');
      return false;
    }
  }

  // Méthode pour initialiser une nouvelle conversation entre deux utilisateurs
  Future<String?> createConversation(
      String creatorId, String otherUserId) async {
    try {
      // Vérifier si une conversation existe déjà entre ces deux utilisateurs
      final existingConversations =
          await _checkExistingConversation(creatorId, otherUserId);

      if (existingConversations.isNotEmpty) {
        return existingConversations.first;
      }

      // Créer une nouvelle conversation
      final result = await _supabase
          .from('conversation')
          .insert({
            'id_creator': creatorId,
            'creation_date': DateTime.now().toIso8601String(),
          })
          .select('id_conversation')
          .single();

      final conversationId = result['id_conversation'].toString();

      // Ajouter les participants
      await _supabase.from('conversation_participant').insert([
        {
          'id_conversation': conversationId,
          'id_user': creatorId,
          'joined_at': DateTime.now().toIso8601String(),
        },
        {
          'id_conversation': conversationId,
          'id_user': otherUserId,
          'joined_at': DateTime.now().toIso8601String(),
        }
      ]);

      return conversationId;
    } catch (e) {
      debugPrint('Erreur lors de la création d\'une conversation: $e');
      return null;
    }
  }

  // Vérifier si une conversation existe déjà entre deux utilisateurs
  Future<List<String>> _checkExistingConversation(
      String user1Id, String user2Id) async {
    try {
      // Récupérer les conversations du premier utilisateur
      final user1Convs = await _supabase
          .from('conversation_participant')
          .select('id_conversation')
          .eq('id_user', user1Id);

      if (user1Convs.isEmpty) {
        return [];
      }

      final user1ConvIds = user1Convs
          .map<String>((c) => c['id_conversation'].toString())
          .toList();

      // Vérifier si le deuxième utilisateur participe à l'une de ces conversations
      final commonConvs = await _supabase
          .from('conversation_participant')
          .select('id_conversation')
          .eq('id_user', user2Id)
          .in_('id_conversation', user1ConvIds);

      return commonConvs
          .map<String>((c) => c['id_conversation'].toString())
          .toList();
    } catch (e) {
      debugPrint(
          'Erreur lors de la vérification des conversations existantes: $e');
      return [];
    }
  }

  // Écouter les mises à jour de la conversation (pour les notifications en temps réel)
  Stream<List<Map<String, dynamic>>> listenToConversation(
      String conversationId) {
    try {
      return _supabase
          .from('message')
          .stream(primaryKey: ['id_message'])
          .eq('id_conversation', conversationId)
          .order('sent_at')
          .map((event) => event.map((e) => e as Map<String, dynamic>).toList());
    } catch (e) {
      debugPrint('Erreur lors de l\'écoute de la conversation: $e');
      return Stream.value([]);
    }
  }
}
