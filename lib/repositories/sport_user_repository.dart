import 'package:flutter/foundation.dart';
import '../models/sport_model.dart';
import '../models/sport_user_model.dart';
import '../config/supabase_config.dart';

class SportUserRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<SportUserModel>> getUserSports(String userId) async {
    try {
      // Pour une vraie application avec Supabase
      /*
      final response = await _supabase
          .from('sport_user')
          .select('id_user, id_sport, club_name, skill_level, looking_for_partners')
          .eq('id_user', userId);
      
      return response.map<SportUserModel>((data) => SportUserModel.fromJson(data)).toList();
      */

      // Pour la démo, retourner des données prédéfinies
      await Future.delayed(
          const Duration(milliseconds: 300)); // Simuler un délai réseau

      return [
        SportUserModel(
          userId: userId,
          sportId: 11, // ID pour le padel
          clubName: 'Padel Club Paris',
          skillLevel: 'Intermédiaire',
          lookingForPartners: true,
        ),
        SportUserModel(
          userId: userId,
          sportId: 9, // ID pour la course à pied
          skillLevel: 'Avancé',
          lookingForPartners: true,
        ),
      ];
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des sports de l\'utilisateur: $e');
      return [];
    }
  }

  Future<List<SportModel>> getAllSports() async {
    try {
      // En production, utiliser cette requête
      /*
      final sports = await _supabase.from('sport').select().order('name');
      return sports.map<SportModel>((sport) => SportModel.fromJson(sport)).toList();
      */

      // Pour la démo, retourner une liste prédéfinie
      await Future.delayed(
          const Duration(milliseconds: 300)); // Simuler un délai réseau

      return [
        SportModel(
            id: 1,
            name: 'Basketball',
            logo: 'https://cdn-icons-png.flaticon.com/512/889/889455.png'),
        SportModel(
            id: 2,
            name: 'Tennis',
            logo: 'https://cdn-icons-png.flaticon.com/512/2906/2906722.png'),
        SportModel(
            id: 3,
            name: 'Football',
            logo: 'https://cdn-icons-png.flaticon.com/512/3097/3097044.png'),
        SportModel(
            id: 4,
            name: 'Natation',
            logo: 'https://cdn-icons-png.flaticon.com/512/5073/5073524.png'),
        SportModel(
            id: 5,
            name: 'Volleyball',
            logo: 'https://cdn-icons-png.flaticon.com/512/1099/1099680.png'),
        SportModel(
            id: 6,
            name: 'Fitness',
            logo: 'https://cdn-icons-png.flaticon.com/512/2548/2548345.png'),
        SportModel(
            id: 7,
            name: 'Escalade',
            logo: 'https://cdn-icons-png.flaticon.com/512/2734/2734747.png'),
        SportModel(
            id: 8,
            name: 'Danse',
            logo: 'https://cdn-icons-png.flaticon.com/512/1998/1998610.png'),
        SportModel(
            id: 9,
            name: 'Course à pied',
            logo: 'https://cdn-icons-png.flaticon.com/512/5073/5073994.png'),
        SportModel(
            id: 10,
            name: 'Yoga',
            logo: 'https://cdn-icons-png.flaticon.com/512/2647/2647625.png'),
        SportModel(
            id: 11,
            name: 'Padel',
            logo: 'https://cdn-icons-png.flaticon.com/512/4696/4696455.png'),
        SportModel(
            id: 12,
            name: 'Boxe',
            logo: 'https://cdn-icons-png.flaticon.com/512/2503/2503380.png'),
      ];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sports: $e');
      return [];
    }
  }
}
