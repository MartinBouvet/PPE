// lib/utils/test_data_initializer.dart
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../repositories/facility_repository.dart';
import '../repositories/sport_repository.dart';
import '../utils/db_initializer.dart';

class TestDataInitializer {
  static final _supabase = SupabaseConfig.client;

  // Méthode principale pour initialiser toutes les données de test
  static Future<bool> initializeAllTestData() async {
    try {
      // Vérifier si la base de données existe et est accessible
      bool dbExists = await _checkDatabaseConnection();

      if (!dbExists) {
        debugPrint(
            'Impossible d\'accéder à la base de données, utilisation de données factices');
        return false;
      }

      await DbInitializer
          .initializeBasicData(); // Initialiser les sports de base
      await initializeSports(); // S'assurer que les sports sont bien initialisés
      await initializeTestFacilities(); // Initialiser les installations sportives

      // Ces opérations peuvent échouer à cause des RLS, mais on continue quand même
      try {
        await initializeTestUsers(); // Initialiser les utilisateurs test
      } catch (e) {
        debugPrint(
            'Erreur lors de l\'initialisation des utilisateurs test: $e');
      }

      try {
        await initializeTestUserSports(); // Initialiser les sports des utilisateurs
      } catch (e) {
        debugPrint(
            'Erreur lors de l\'initialisation des sports des utilisateurs: $e');
      }

      try {
        await initializeTestMatches(); // Initialiser des matchs entre utilisateurs
      } catch (e) {
        debugPrint('Erreur lors de l\'initialisation des matchs test: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des données de test: $e');
      return false;
    }
  }

  // Vérifier si la connexion à la base de données fonctionne
  static Future<bool> _checkDatabaseConnection() async {
    try {
      // Test simple pour vérifier si on peut accéder à Supabase
      await _supabase.from('sport').select('count').limit(1);
      return true;
    } catch (e) {
      debugPrint('Erreur de connexion à la base de données: $e');
      return false;
    }
  }

  // Initialiser les sports de base (s'ils n'existent pas déjà)
  static Future<bool> initializeSports() async {
    try {
      // Vérifier si des sports existent déjà
      final existingSports =
          await _supabase.from('sport').select('id_sport').limit(1);

      if (existingSports.isNotEmpty) {
        debugPrint('Des sports existent déjà dans la base de données');
        return true;
      }

      // Liste des sports à créer
      final sports = [
        {
          'id_sport': 1,
          'name': 'Basketball',
          'description': 'Sport collectif de ballon'
        },
        {'id_sport': 2, 'name': 'Tennis', 'description': 'Sport de raquette'},
        {
          'id_sport': 3,
          'name': 'Football',
          'description': 'Sport collectif de ballon'
        },
        {'id_sport': 4, 'name': 'Natation', 'description': 'Sport aquatique'},
        {
          'id_sport': 5,
          'name': 'Volleyball',
          'description': 'Sport collectif de ballon'
        },
        {
          'id_sport': 6,
          'name': 'Fitness',
          'description': 'Activité de bien-être'
        },
        {'id_sport': 7, 'name': 'Escalade', 'description': 'Sport de grimpe'},
        {
          'id_sport': 8,
          'name': 'Danse',
          'description': 'Activité sportive artistique'
        },
        {
          'id_sport': 9,
          'name': 'Course à pied',
          'description': 'Sport de course'
        },
        {
          'id_sport': 10,
          'name': 'Yoga en plein air',
          'description': 'Yoga pratiqué en extérieur'
        },
      ];

      // Insérer les sports
      for (var sport in sports) {
        await _supabase.from('sport').upsert(sport);
      }

      debugPrint('Sports initialisés avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des sports: $e');
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
        }
      ];

      // Ajouter les utilisateurs dans la base de données
      for (var user in testUsers) {
        try {
          await _supabase.from('app_user').upsert(user, onConflict: 'id');
        } catch (e) {
          debugPrint('Erreur insertion utilisateur: $e');
          // Continuer avec l'utilisateur suivant
        }
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
        }
      ];

      for (var sportUser in userSports) {
        try {
          await _supabase
              .from('sport_user')
              .upsert(sportUser, onConflict: 'id_user,id_sport');
        } catch (e) {
          debugPrint('Erreur insertion sport utilisateur: $e');
          // Continuer avec le sport suivant
        }
      }

      debugPrint('Sports des utilisateurs test initialisés avec succès');
      return true;
    } catch (e) {
      debugPrint(
          'Erreur lors de l\'initialisation des sports des utilisateurs: $e');
      return false;
    }
  }

  // Initialiser des matchs entre utilisateurs test
  static Future<bool> initializeTestMatches() async {
    try {
      // Vérifier si des matchs existent déjà
      final existingMatches =
          await _supabase.from('match_user').select('id_match').limit(1);

      if (existingMatches.isNotEmpty) {
        debugPrint('Des matchs test existent déjà');
        return true;
      }

      // Créer quelques matchs entre utilisateurs test
      final testMatches = [
        {
          'id_user_requester':
              '00000000-0000-0000-0000-000000000001', // TennisFan42
          'id_user_liked': '00000000-0000-0000-0000-000000000002', // RunnerPro
          'request_status': 'accepted', // Match accepté
          'request_date': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'response_date': DateTime.now()
              .subtract(const Duration(days: 4))
              .toIso8601String(),
        },
        {
          'id_user_requester':
              '00000000-0000-0000-0000-000000000003', // YogaLover
          'id_user_liked':
              '00000000-0000-0000-0000-000000000001', // TennisFan42
          'request_status': 'pending', // En attente
          'request_date': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'response_date': null,
        }
      ];

      // Ajouter les matchs dans la base de données
      for (var match in testMatches) {
        try {
          await _supabase.from('match_user').insert(match);
        } catch (e) {
          debugPrint('Erreur insertion match: $e');
          // Continuer avec le match suivant
        }
      }

      // Créer des conversations pour les matchs acceptés
      try {
        await _createConversationsForMatches();
      } catch (e) {
        debugPrint('Erreur création conversations: $e');
      }

      debugPrint('Matchs test initialisés avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des matchs test: $e');
      return false;
    }
  }

  // Créer des conversations pour les matchs acceptés
  static Future<bool> _createConversationsForMatches() async {
    try {
      // Récupérer les matchs acceptés
      final acceptedMatches = await _supabase
          .from('match_user')
          .select()
          .eq('request_status', 'accepted');

      // Pour chaque match accepté, créer une conversation
      for (var match in acceptedMatches) {
        // Vérifier si une conversation existe déjà pour ce match
        final existingConversation = await _supabase
            .from('conversation_participant')
            .select('id_conversation')
            .or('id_user.eq.${match['id_user_requester']},id_user.eq.${match['id_user_liked']}')
            .order('id_conversation')
            .limit(1);

        // Si aucune conversation n'existe, en créer une
        if (existingConversation.isEmpty) {
          try {
            // Créer une nouvelle conversation
            final conversationResult = await _supabase
                .from('conversation')
                .insert({
                  'conversation_name': null,
                  'id_creator': match['id_user_requester'],
                  'creation_date': DateTime.now().toIso8601String(),
                })
                .select('id_conversation')
                .single();

            final conversationId = conversationResult['id_conversation'];

            // Ajouter les participants à la conversation
            await _supabase.from('conversation_participant').insert([
              {
                'id_conversation': conversationId,
                'id_user': match['id_user_requester'],
                'joined_at': DateTime.now().toIso8601String(),
              },
              {
                'id_conversation': conversationId,
                'id_user': match['id_user_liked'],
                'joined_at': DateTime.now().toIso8601String(),
              }
            ]);

            // Ajouter quelques messages
            await _supabase.from('message').insert([
              {
                'id_conversation': conversationId,
                'id_user_sender': match['id_user_requester'],
                'content':
                    'Salut ! Content qu\'on puisse faire du sport ensemble !',
                'sent_at': DateTime.now()
                    .subtract(const Duration(days: 3, hours: 2))
                    .toIso8601String(),
                'edited': true,
              },
              {
                'id_conversation': conversationId,
                'id_user_sender': match['id_user_liked'],
                'content':
                    'Salut ! Moi aussi, ça va être super ! Tu es disponible quand ?',
                'sent_at': DateTime.now()
                    .subtract(const Duration(days: 3, hours: 1))
                    .toIso8601String(),
                'edited': true,
              }
            ]);
          } catch (e) {
            debugPrint('Erreur lors de la création d\'une conversation: $e');
            continue; // Passer au match suivant
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la création des conversations: $e');
      return false;
    }
  }
}
