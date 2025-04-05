import 'package:flutter/foundation.dart';
import '../models/sport_model.dart';
import '../models/sport_user_model.dart';
import '../config/supabase_config.dart';

class SportUserRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<SportUserModel>> getUserSports(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      return [
        SportUserModel(
          userId: userId,
          sportId: 11,
          clubName: 'Padel Club Paris',
          skillLevel: 'Intermédiaire',
          lookingForPartners: true,
        ),
        SportUserModel(
          userId: userId,
          sportId: 9,
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
      await Future.delayed(const Duration(milliseconds: 300));

      return [
        SportModel(id: 1, name: 'Basketball'),
        SportModel(id: 2, name: 'Tennis'),
        SportModel(id: 3, name: 'Football'),
        SportModel(id: 4, name: 'Natation'),
        SportModel(id: 5, name: 'Volleyball'),
        SportModel(id: 6, name: 'Fitness'),
        SportModel(id: 7, name: 'Escalade'),
        SportModel(id: 8, name: 'Danse'),
        SportModel(id: 9, name: 'Course à pied'),
        SportModel(id: 10, name: 'Yoga'),
        SportModel(id: 11, name: 'Padel'),
        SportModel(id: 12, name: 'Boxe'),
      ];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sports: $e');
      return [];
    }
  }
}
