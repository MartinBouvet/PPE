import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Classe responsable de l'initialisation et de la vérification de la base de données.
class DbInitializer {
  static final _supabase = SupabaseConfig.client;

  /// Vérifie que toutes les tables nécessaires existent dans la base de données.
  /// Retourne true si tout est correct, false sinon.
  static Future<bool> checkDatabaseStructure() async {
    try {
      // Liste des tables requises
      const requiredTables = [
        'app_user', // Vérifiez que c'est 'app_user' et pas 'user'
        'sport',
        'sport_user',
        'match_user', // Vérifiez que c'est 'match_user' et pas juste 'match'
        'conversation',
        'conversation_participant',
        'message',
      ];

      // Vérifier l'existence de chaque table
      for (final table in requiredTables) {
        final result = await _tableExists(table);
        if (!result) {
          debugPrint('Table manquante: $table');
          return false;
        }
      }

      debugPrint('Structure de la base de données validée');
      return true;
    } catch (e) {
      debugPrint(
          'Erreur lors de la vérification de la structure de la base de données: $e');
      return false;
    }
  }

  /// Vérifie si une table existe dans la base de données
  /// Vérifie si une table existe dans la base de données
  static Future<bool> _tableExists(String tableName) async {
    try {
      // Remplacer cette partie par le nouvel appel RPC
      final result = await _supabase.rpc(
        'check_table_exists', // Nouveau nom de fonction
        params: {'table_name_param': tableName}, // Paramètre renommé
      );

      // Si la fonction RPC n'existe pas, on utilise une approche plus basique
      if (result == null) {
        // Essayer de faire une requête simple sur la table
        await _supabase.from(tableName).select('count').limit(1);
        return true;
      }

      return result as bool;
    } catch (e) {
      if (e.toString().contains('does not exist')) {
        return false;
      }

      // Pour d'autres erreurs, on suppose que la table existe mais qu'il y a un autre problème
      debugPrint('Erreur lors de la vérification de la table $tableName: $e');
      return true;
    }
  }

  /// Crée les tables de base nécessaires si elles n'existent pas
  static Future<bool> createBasicTables() async {
    try {
      // Ces requêtes sont spécifiques à Supabase/PostgreSQL
      // Normalement, vous utiliseriez la console Supabase pour créer vos tables
      // Ceci est juste une solution de secours pour les cas extrêmes

      // Table utilisateur
      if (!await _tableExists('app_user')) {
        await _supabase.rpc('create_app_user_table');
      }

      // Table sport
      if (!await _tableExists('sport')) {
        await _supabase.rpc('create_sport_table');
      }

      // Table association sport_user
      if (!await _tableExists('sport_user')) {
        await _supabase.rpc('create_sport_user_table');
      }

      // Autres tables...

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la création des tables: $e');
      return false;
    }
  }

  /// Initialise des données de base (sports communs) si nécessaire
  static Future<void> initializeBasicData() async {
    try {
      // Vérifier si la table des sports est vide
      final sportsCount =
          await _supabase.from('sport').select('id_sport').limit(1);

      if (sportsCount.isEmpty) {
        // Ajouter quelques sports de base avec des IDs spécifiques
        final basicSports = [
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
          {'id_sport': 4, 'name': 'Running', 'description': 'Course à pied'},
          {
            'id_sport': 5,
            'name': 'Randonnée',
            'description': 'Marche en nature'
          },
          {
            'id_sport': 6,
            'name': 'Yoga',
            'description': 'Activité de bien-être'
          },
          {'id_sport': 7, 'name': 'Escalade', 'description': 'Sport de grimpe'},
          {'id_sport': 8, 'name': 'Natation', 'description': 'Sport aquatique'},
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

        await _supabase.from('sport').upsert(basicSports);
        debugPrint('Sports de base ajoutés');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des données de base: $e');
    }
  }
}
