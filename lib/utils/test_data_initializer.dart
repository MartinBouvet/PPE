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
      await DbInitializer
          .initializeBasicData(); // Initialiser les sports de base
      await initializeTestFacilities(); // Initialiser les installations sportives
      await initializeTestUsers(); // Initialiser les utilisateurs test
      await initializeTestUserSports(); // Initialiser les sports des utilisateurs
      await initializeTestMatches(); // Initialiser des matchs entre utilisateurs

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
        {
          'id': '00000000-0000-0000-0000-000000000005',
          'pseudo': 'ClimbingQueen',
          'first_name': 'Laura',
          'birth_date': DateTime(1993, 4, 18).toIso8601String(),
          'gender': 'F',
          'photo': 'https://randomuser.me/api/portraits/women/43.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Passionnée d\'escalade. Je cherche des partenaires pour grimper en salle ou en extérieur.',
        },
        {
          'id': '00000000-0000-0000-0000-000000000006',
          'pseudo': 'FootballFan',
          'first_name': 'Julien',
          'birth_date': DateTime(1991, 8, 30).toIso8601String(),
          'gender': 'M',
          'photo': 'https://randomuser.me/api/portraits/men/67.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Amateur de football du dimanche. Je recherche une équipe sympa pour des matchs à 5 ou 7.',
        },
        {
          'id': '00000000-0000-0000-0000-000000000007',
          'pseudo': 'DanceQueen',
          'first_name': 'Chloé',
          'birth_date': DateTime(1994, 2, 14).toIso8601String(),
          'gender': 'F',
          'photo': 'https://randomuser.me/api/portraits/women/17.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Danseuse niveau intermédiaire. J\'adore la salsa et le rock, et je cherche des partenaires pour progresser.',
        },
        {
          'id': '00000000-0000-0000-0000-000000000008',
          'pseudo': 'BoxingPro',
          'first_name': 'Karim',
          'birth_date': DateTime(1990, 11, 5).toIso8601String(),
          'gender': 'M',
          'photo': 'https://randomuser.me/api/portraits/men/35.jpg',
          'inscription_date': DateTime.now().toIso8601String(),
          'description':
              'Boxeur depuis 5 ans. Je cherche des partenaires d\'entraînement sérieux pour progresser ensemble.',
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
        {
          'id_user': '00000000-0000-0000-0000-000000000005',
          'id_sport': 7, // Escalade
          'skill_level': 'Avancé',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000006',
          'id_sport': 3, // Football
          'club_name': 'FC Amateurs Paris',
          'skill_level': 'Débutant',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000007',
          'id_sport': 8, // Danse (à ajouter si nécessaire)
          'club_name': 'Club de danse Latin Fire',
          'skill_level': 'Intermédiaire',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000008',
          'id_sport': 9, // Boxe (à ajouter si nécessaire)
          'club_name': 'Boxing Club Paris',
          'skill_level': 'Avancé',
          'looking_for_partners': true,
        },
        // Ajoutez des sports secondaires pour certains utilisateurs
        {
          'id_user': '00000000-0000-0000-0000-000000000002',
          'id_sport': 1, // Basketball
          'skill_level': 'Débutant',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000004',
          'id_sport': 3, // Football
          'skill_level': 'Intermédiaire',
          'looking_for_partners': true,
        },
        {
          'id_user': '00000000-0000-0000-0000-000000000005',
          'id_sport': 5, // Randonnée
          'skill_level': 'Intermédiaire',
          'looking_for_partners': false,
        }
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
        },
        {
          'id_user_requester':
              '00000000-0000-0000-0000-000000000004', // BasketballKing
          'id_user_liked':
              '00000000-0000-0000-0000-000000000006', // FootballFan
          'request_status': 'accepted', // Match accepté
          'request_date': DateTime.now()
              .subtract(const Duration(days: 7))
              .toIso8601String(),
          'response_date': DateTime.now()
              .subtract(const Duration(days: 6))
              .toIso8601String(),
        },
        {
          'id_user_requester':
              '00000000-0000-0000-0000-000000000005', // ClimbingQueen
          'id_user_liked':
              '00000000-0000-0000-0000-000000000001', // TennisFan42
          'request_status': 'pending', // En attente
          'request_date': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'response_date': null,
        },
        // Créer un match entre l'utilisateur courant et un autre
        {
          'id_user_requester':
              '00000000-0000-0000-0000-000000000007', // DanceQueen
          'id_user_liked': '00000000-0000-0000-0000-000000000008', // BoxingPro
          'request_status': 'accepted', // Match accepté
          'request_date': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String(),
          'response_date': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        }
      ];

      // Ajouter les matchs dans la base de données
      for (var match in testMatches) {
        await _supabase.from('match_user').insert(match);
      }

      // Créer des conversations pour les matchs acceptés
      await _createConversationsForMatches();

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
            },
            {
              'id_conversation': conversationId,
              'id_user_sender': match['id_user_requester'],
              'content':
                  'Je suis libre ce week-end, samedi matin ou dimanche après-midi. Ça te va ?',
              'sent_at': DateTime.now()
                  .subtract(const Duration(days: 2, hours: 12))
                  .toIso8601String(),
              'edited': true,
            }
          ]);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la création des conversations: $e');
      return false;
    }
  }
}
