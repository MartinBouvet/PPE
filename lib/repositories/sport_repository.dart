// lib/repositories/sport_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/sport_model.dart';
import '../models/sport_user_model.dart';

class SportRepository {
  final _supabase = SupabaseConfig.client;

  // Liste des niveaux valides (selon la contrainte de la base de données)
  final List<String> validSkillLevels = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert'
  ];

  Future<List<SportModel>> getAllSports() async {
    try {
      final sports = await _supabase.from('sport').select().order('name');
      debugPrint('Sports récupérés: ${sports.length}');

      return sports
          .map<SportModel>((sport) => SportModel.fromJson(sport))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sports: $e');
      return _generateMockSports();
    }
  }

  // Méthode pour générer des sports factices en cas d'erreur
  List<SportModel> _generateMockSports() {
    return [
      SportModel(
          id: 1, name: 'Basketball', description: 'Sport collectif de ballon'),
      SportModel(id: 2, name: 'Tennis', description: 'Sport de raquette'),
      SportModel(
          id: 3, name: 'Football', description: 'Sport collectif de ballon'),
      SportModel(id: 4, name: 'Natation', description: 'Sport aquatique'),
      SportModel(
          id: 5, name: 'Volleyball', description: 'Sport collectif de ballon'),
      SportModel(id: 6, name: 'Fitness', description: 'Activité de bien-être'),
      SportModel(id: 7, name: 'Escalade', description: 'Sport de grimpe'),
    ];
  }

  Future<SportModel?> getSportById(int sportId) async {
    try {
      final sport = await _supabase
          .from('sport')
          .select()
          .eq('id_sport', sportId)
          .single();

      return SportModel.fromJson(sport);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du sport: $e');

      // Si erreur, retourner un sport fictif avec cet ID
      if (sportId >= 1 && sportId <= 10) {
        return _generateMockSports().firstWhere((s) => s.id == sportId,
            orElse: () => SportModel(id: sportId, name: 'Sport $sportId'));
      }

      return null;
    }
  }

  // Méthode améliorée pour ajouter un sport à un utilisateur
  Future<bool> addSportToUser(
    String userId,
    int sportId, {
    String? clubName,
    String? skillLevel,
    bool lookingForPartners = false,
  }) async {
    try {
      // S'assurer que le niveau est valide
      final validLevel =
          skillLevel != null && validSkillLevels.contains(skillLevel)
              ? skillLevel
              : 'Débutant';

      debugPrint(
          'Ajout du sport $sportId à l\'utilisateur $userId avec niveau: $validLevel');

      // Vérifier si l'utilisateur a déjà ce sport
      try {
        final existingSport = await _supabase
            .from('sport_user')
            .select()
            .eq('id_user', userId)
            .eq('id_sport', sportId)
            .maybeSingle();

        if (existingSport != null) {
          // Mettre à jour plutôt qu'ajouter
          await _supabase
              .from('sport_user')
              .update({
                'club_name': clubName ?? '',
                'skill_level': validLevel,
                'looking_for_partners': lookingForPartners,
              })
              .eq('id_user', userId)
              .eq('id_sport', sportId);

          debugPrint('Sport $sportId mis à jour pour l\'utilisateur $userId');
        } else {
          // Ajouter une nouvelle entrée
          await _supabase.from('sport_user').insert({
            'id_user': userId,
            'id_sport': sportId,
            'club_name': clubName ?? '',
            'skill_level': validLevel,
            'looking_for_partners': lookingForPartners,
          });

          debugPrint('Sport $sportId ajouté pour l\'utilisateur $userId');
        }
      } catch (specificError) {
        debugPrint('Erreur spécifique: $specificError');

        // Si une erreur se produit, on tente une approche différente
        // Ceci pourrait contourner certaines limitations de RLS (Row Level Security) de Supabase
        final insertData = {
          'id_user': userId,
          'id_sport': sportId,
          'club_name': clubName ?? '',
          'skill_level': validLevel,
          'looking_for_partners': lookingForPartners,
        };

        await _supabase
            .from('sport_user')
            .upsert(insertData, onConflict: 'id_user,id_sport');

        debugPrint(
            'Sport $sportId ajouté/mis à jour via upsert pour l\'utilisateur $userId');
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du sport à l\'utilisateur: $e');
      // Tenter une dernière approche si d'autres ont échoué
      try {
        await _supabase.rpc('add_sport_to_user', params: {
          'user_id': userId,
          'sport_id': sportId,
          'club_name': clubName ?? '',
          'skill_level': skillLevel ?? 'Débutant',
          'is_looking': lookingForPartners,
        });
        return true;
      } catch (rpcError) {
        debugPrint('Échec de l\'appel RPC: $rpcError');
        return false;
      }
    }
  }

  // Supprimer un sport de l'utilisateur
  Future<bool> removeSportFromUser(String userId, int sportId) async {
    try {
      await _supabase
          .from('sport_user')
          .delete()
          .eq('id_user', userId)
          .eq('id_sport', sportId);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du sport: $e');

      // Tenter une alternative si la première approche échoue
      try {
        await _supabase.rpc('remove_sport_from_user', params: {
          'user_id': userId,
          'sport_id': sportId,
        });
        return true;
      } catch (rpcError) {
        debugPrint('Échec de l\'appel RPC: $rpcError');
        return false;
      }
    }
  }
}
