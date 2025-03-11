// lib/repositories/sport_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/sport_model.dart';

class SportRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<SportModel>> getAllSports() async {
    try {
      final sports = await _supabase.from('sport').select().order('name');

      return sports
          .map<SportModel>((sport) => SportModel.fromJson(sport))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sports: $e');

      // Si erreur avec Supabase, retourner des données factices
      if (e.toString().contains('does not exist')) {
        return _generateMockSports();
      }

      // Retourner une liste vide en cas d'erreur plutôt que de planter
      return [];
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
      SportModel(
          id: 8, name: 'Danse', description: 'Activité sportive artistique'),
      SportModel(id: 9, name: 'Course à pied', description: 'Sport de course'),
      SportModel(
          id: 10,
          name: 'Yoga en plein air',
          description: 'Yoga pratiqué en extérieur'),
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

  Future<void> addSport(
      String name, String? description, String? logoUrl) async {
    try {
      await _supabase.from('sport').insert({
        'name': name,
        'description': description,
        'logo': logoUrl,
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du sport: $e');
      throw Exception('Échec de l\'ajout du sport: $e');
    }
  }

  // Vérifier si un sport existe déjà
  Future<bool> sportExists(String sportName) async {
    try {
      final result = await _supabase
          .from('sport')
          .select('id_sport')
          .ilike('name', sportName)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'existence du sport: $e');
      return false;
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
      return false;
    }
  }

  // Méthode pour ajouter un sport à un utilisateur
  Future<bool> addSportToUser(
    String userId,
    int sportId, {
    String? clubName,
    String? skillLevel,
    bool lookingForPartners = false,
  }) async {
    try {
      // Vérifier si l'utilisateur a déjà ce sport
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
              'club_name': clubName,
              'skill_level': skillLevel,
              'looking_for_partners': lookingForPartners,
            })
            .eq('id_user', userId)
            .eq('id_sport', sportId);
      } else {
        // Ajouter une nouvelle entrée
        await _supabase.from('sport_user').insert({
          'id_user': userId,
          'id_sport': sportId,
          'club_name': clubName,
          'skill_level': skillLevel,
          'looking_for_partners': lookingForPartners,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du sport à l\'utilisateur: $e');
      return false;
    }
  }

  // Récupérer les sports populaires (les plus ajoutés par les utilisateurs)
  Future<List<SportModel>> getPopularSports({int limit = 5}) async {
    try {
      // Cette requête suppose que vous avez une vue ou une requête qui compte les sports par popularité
      final result = await _supabase
          .rpc('get_popular_sports', params: {'limit_count': limit});

      if (result != null) {
        return (result as List)
            .map<SportModel>((sport) => SportModel.fromJson(sport))
            .toList();
      }

      // Fallback: retourner simplement les premiers sports
      return await getAllSports().then((sports) => sports.take(limit).toList());
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sports populaires: $e');
      return await getAllSports().then((sports) => sports.take(limit).toList());
    }
  }
}
