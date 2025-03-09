import '../config/supabase_config.dart';
import '../models/match_model.dart';

class MatchRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<String>> getPotentialMatches(String userId, int sportId) async {
    try {
      // Récupérer les utilisateurs qui pratiquent le même sport et qui cherchent des partenaires
      final potentialMatches = await _supabase
          .from('sport_user')
          .select('id_user')
          .eq('id_sport', sportId)
          .eq('looking_for_partners', true)
          .neq('id_user', userId);

      return potentialMatches
          .map<String>((match) => match['id_user'] as String)
          .toList();
    } catch (e) {
      throw Exception('Échec de la récupération des matches potentiels: $e');
    }
  }

  Future<void> createMatchRequest(
    String requesterId,
    String likedUserId,
  ) async {
    try {
      await _supabase.from('match_user').insert({
        'id_user_requester': requesterId,
        'id_user_liked': likedUserId,
        'request_status': 'pending',
        'request_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Échec de la création de la demande de match: $e');
    }
  }

  Future<void> respondToMatchRequest(
    String requesterId,
    String likedUserId,
    bool accept,
  ) async {
    try {
      await _supabase
          .from('match_user')
          .update({'request_status': accept ? 'accepted' : 'rejected'})
          .eq('id_user_requester', requesterId)
          .eq('id_user_liked', likedUserId);

      // Si accepté, créer une conversation
      if (accept) {
        final conversationId = await _createConversation(
          requesterId,
          likedUserId,
        );

        // Ajouter les participants à la conversation
        await _addConversationParticipants(conversationId, [
          requesterId,
          likedUserId,
        ]);
      }
    } catch (e) {
      throw Exception('Échec de la réponse à la demande de match: $e');
    }
  }

  Future<String> _createConversation(String user1Id, String user2Id) async {
    try {
      final response =
          await _supabase
              .from('conversation')
              .insert({
                'conversation_name': null,
                'id_creator': user1Id,
                'creation_date': DateTime.now().toIso8601String(),
              })
              .select('id_conversation')
              .single();

      return response['id_conversation'].toString();
    } catch (e) {
      throw Exception('Échec de la création de la conversation: $e');
    }
  }

  Future<void> _addConversationParticipants(
    String conversationId,
    List<String> userIds,
  ) async {
    try {
      final participants =
          userIds
              .map(
                (userId) => {
                  'id_conversation': conversationId,
                  'id_user': userId,
                  'joined_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      await _supabase.from('conversation_participant').insert(participants);
    } catch (e) {
      throw Exception(
        'Échec de l\'ajout des participants à la conversation: $e',
      );
    }
  }
}
