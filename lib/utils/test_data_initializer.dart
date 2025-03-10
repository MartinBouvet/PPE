// lib/utils/test_data_initializer.dart
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../repositories/facility_repository.dart';
import '../utils/db_initializer.dart';

class TestDataInitializer {
  static final _supabase = SupabaseConfig.client;

  // Méthode principale pour initialiser toutes les données de test
  static Future<bool> initializeAllTestData() async {
    try {
      await DbInitializer.initializeBasicData(); // Initialiser les sports
      await initializeTestFacilities(); // Initialiser les installations sportives
      await initializeTestUsers(); // Initialiser les utilisateurs test
      await initializeTestUserSports(); // Initialiser les sports des utilisateurs

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des données de test: $e');
      return false;
    }
  }

  // Initialiser les installations sportives
  static Future<bool> initializeTestFacilities() async {
    try {
      final facilityRepository = FacilityRepository();
      return await facilityRepository.initializeFacilitiesData();
    } catch (e) {
      debugPrint(
          'Erreur lors de l\'initialisation des installations sportives: $e');
      return false;
    }
  }

  // Initialiser les utilisateurs test
  static Future<bool> initializeTestUsers() async {
    try {
      // Vérifier si des utilisateurs test existent déjà
      final existingUsers =
          await _supabase.from('app_user').select('id').limit(4);

      if (existingUsers.length >= 4) {
        debugPrint('Des utilisateurs test existent déjà');
        return true;
      }

      // Liste des utilisateurs test à créer dans Supabase
      final testUsers = [
        {
          'id': '00000000-0000-0000-0000-000000000001',
          'pseudo': 'TennisFan42',
          'first_name': 'Sophie',
          'birth_date': DateTime(1990, 5, 15).toIso8601String(),
          'gender': 'F',
          'photo': 'https://randomuser.me/api/portraits/women/32.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Passionnée de tennis et de randonnée. Je cherche des partenaires pour des matchs amicaux.',
        },
        {
          'id': '00000000-0000-0000-0000-000000000002',
          'pseudo': 'RunnerPro',
          'first_name': 'Thomas',
          'birth_date': DateTime(1988, 9, 21).toIso8601String(),
          'gender': 'M',
          'photo': 'https://randomuser.me/api/portraits/men/45.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Coureur semi-pro, 10km en 42min. Disponible le weekend pour des sessions d\'entraînement.',
        },
        {
          'id': '00000000-0000-0000-0000-000000000003',
          'pseudo': 'YogaLover',
          'first_name': 'Emma',
          'birth_date': DateTime(1992, 3, 8).toIso8601String(),
          'gender': 'F',
          'photo': 'https://randomuser.me/api/portraits/women/63.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Prof de yoga cherchant à former un groupe pour des sessions en plein air.',
        },
        {
          'id': '00000000-0000-0000-0000-000000000004',
          'pseudo': 'BasketballKing',
          'first_name': 'Lucas',
          'birth_date': DateTime(1995, 7, 12).toIso8601String(),
          'gender': 'M',
          'photo': 'https://randomuser.me/api/portraits/men/22.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Basketteur depuis 10 ans, niveau intermédiaire. Je cherche une équipe pour des matchs hebdomadaires.',
        },
      ];

      // Ajouter les utilisateurs dans la base de données
      for (var user in testUsers) {
        await _supabase.from('app_user').upsert(user, onConflict: 'id');
      }

      debugPrint('Utilisateurs test initialisés avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des utilisateurs test: $e');
      return false;
    }
  }

  // Initialiser les sports des utilisateurs test
  static Future<bool> initializeTestUserSports() async {
    try {
      // Vérifier si des relations utilisateur-sport existent déjà
      final existingSports = await _supabase
          .from('sport_user')
          .select('id_user, id_sport')
          .limit(5);

      if (existingSports.length >= 5) {
        debugPrint('Des sports d\'utilisateurs test existent déjà');
        return true;
      }

      // Relation utilisateur-sport
      final userSports = [
        {
          'id_user': '00000000-0000-0000-0000-000000000001',
          'id_sport': 2, // Tennis
          'club_name': 'Tennis Club Paris 15',
          'skill_level': 'Intermédiaire',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000001',
          'id_sport': 5, // Randonnée
          'skill_level': 'Débutant',
          'looking_for_partners': false,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000002',
          'id_sport': 4, // Course à pied / Running
          'skill_level': 'Avancé',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000003',
          'id_sport': 6, // Yoga
          'club_name': 'Studio Zen',
          'skill_level': 'Expert',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000004',
          'id_sport': 1, // Basketball
          'skill_level': 'Intermédiaire',
          'looking_for_partners': true,
        },
      ];

      for (var sportUser in userSports) {
        await _supabase
            .from('sport_user')
            .upsert(sportUser, onConflict: 'id_user,id_sport');
      }

      debugPrint('Sports des utilisateurs test initialisés avec succès');
      return true;
    } catch (e) {
      debugPrint(
          'Erreur lors de l\'initialisation des sports des utilisateurs: $e');
      return false;
    }
  }
}
