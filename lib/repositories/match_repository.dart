import 'package:flutter/foundation.dart';
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

      // Récupérer les utilisateurs déjà demandés/refusés pour les filtrer
      final alreadyInteracted = await _supabase
          .from('match_user')
          .select('id_user_liked')
          .eq('id_user_requester', userId);

      final alreadyLikedIds = alreadyInteracted
          .map<String>((m) => m['id_user_liked'] as String)
          .toList();

      // Exclure les utilisateurs déjà demandés
      final filteredMatches = potentialMatches
          .map<String>((match) => match['id_user'] as String)
          .where((id) => !alreadyLikedIds.contains(id))
          .toList();

      return filteredMatches;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des matches potentiels: $e');
      return [];
    }
  }

  Future<bool> createMatchRequest(
    String requesterId,
    String likedUserId,
  ) async {
    try {
      // Vérifier si une demande existe déjà
      final existingRequest = await _supabase
          .from('match_user')
          .select()
          .eq('id_user_requester', requesterId)
          .eq('id_user_liked', likedUserId)
          .maybeSingle();

      if (existingRequest != null) {
        // La demande existe déjà, mettre à jour si elle a été rejetée
        if (existingRequest['request_status'] == 'rejected') {
          await _supabase
              .from('match_user')
              .update({
                'request_status': 'pending',
                'request_date': DateTime.now().toIso8601String(),
                'response_date': null,
              })
              .eq('id_user_requester', requesterId)
              .eq('id_user_liked', likedUserId);
        }
      } else {
        // Créer une nouvelle demande
        await _supabase.from('match_user').insert({
          'id_user_requester': requesterId,
          'id_user_liked': likedUserId,
          'request_status': 'pending',
          'request_date': DateTime.now().toIso8601String(),
        });
      }

      // Vérifier si l'autre utilisateur a déjà fait une demande (match mutuel)
      final reverseRequest = await _supabase
          .from('match_user')
          .select()
          .eq('id_user_requester', likedUserId)
          .eq('id_user_liked', requesterId)
          .eq('request_status', 'pending')
          .maybeSingle();

      // Si match mutuel, accepter automatiquement les deux demandes et créer une conversation
      if (reverseRequest != null) {
        await respondToMatchRequest(likedUserId, requesterId, true);
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la création de la demande de match: $e');
      return false;
    }
  }

  Future<bool> respondToMatchRequest(
    String requesterId,
    String likedUserId,
    bool accept,
  ) async {
    try {
      await _supabase
          .from('match_user')
          .update({
            'request_status': accept ? 'accepted' : 'rejected',
            'response_date': DateTime.now().toIso8601String(),
          })
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

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la réponse à la demande de match: $e');
      return false;
    }
  }

  Future<String> _createConversation(String user1Id, String user2Id) async {
    try {
      final response = await _supabase
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
      debugPrint('Erreur lors de la création de la conversation: $e');
      throw Exception('Échec de la création de la conversation: $e');
    }
  }

  Future<void> _addConversationParticipants(
    String conversationId,
    List<String> userIds,
  ) async {
    try {
      final participants = userIds
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
      debugPrint(
          'Erreur lors de l\'ajout des participants à la conversation: $e');
      throw Exception(
        'Échec de l\'ajout des participants à la conversation: $e',
      );
    }
  }

  // Récupérer les demandes de match en attente pour un utilisateur
  Future<List<MatchModel>> getPendingMatchRequests(String userId) async {
    try {
      final requests = await _supabase
          .from('match_user')
          .select()
          .eq('id_user_liked', userId)
          .eq('request_status', 'pending');

      return requests
          .map<MatchModel>((request) => MatchModel.fromJson(request))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes de match: $e');
      return [];
    }
  }

  // Récupérer les matches acceptés d'un utilisateur
  Future<List<MatchModel>> getAcceptedMatches(String userId) async {
    try {
      final asRequester = await _supabase
          .from('match_user')
          .select()
          .eq('id_user_requester', userId)
          .eq('request_status', 'accepted');

      final asLiked = await _supabase
          .from('match_user')
          .select()
          .eq('id_user_liked', userId)
          .eq('request_status', 'accepted');

      final List<Map<String, dynamic>> allMatches = [
        ...asRequester,
        ...asLiked
      ];

      return allMatches
          .map<MatchModel>((match) => MatchModel.fromJson(match))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des matches acceptés: $e');
      return [];
    }
  }
}
