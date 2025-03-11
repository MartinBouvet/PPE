import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/sport_model.dart';
import '../models/sport_user_model.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final _supabase = SupabaseConfig.client;

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final userData = await _supabase
          .from('app_user') // Vérifiez que c'est 'app_user'
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');
      // Si l'utilisateur n'existe pas dans la table app_user mais existe dans Auth
      if (e.toString().contains('Row not found')) {
        final authUser = _supabase.auth.currentUser;
        if (authUser != null && authUser.id == userId) {
          return UserModel(id: userId);
        }
      }
      return null;
    }
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('app_user').update(data).eq('id', userId);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil: $e');
      throw Exception('Échec de la mise à jour du profil: $e');
    }
  }

  Future<List<SportModel>> getAllSports() async {
    try {
      final sports = await _supabase.from('sport').select().order('name');

      return sports
          .map<SportModel>((sport) => SportModel.fromJson(sport))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sports: $e');
      throw Exception('Échec de la récupération des sports: $e');
    }
  }

  Future<List<SportUserModel>> getUserSports(String userId) async {
    try {
      final userSports =
          await _supabase.from('sport_user').select().eq('id_user', userId);

      return userSports
          .map<SportUserModel>((sport) => SportUserModel.fromJson(sport))
          .toList();
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des sports de l\'utilisateur: $e');
      throw Exception(
        'Échec de la récupération des sports de l\'utilisateur: $e',
      );
    }
  }

  // Méthode pour vérifier si l'utilisateur existe déjà
  Future<bool> userExists(String userId) async {
    try {
      final result = await _supabase
          .from('app_user')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint(
          'Erreur lors de la vérification de l\'existence de l\'utilisateur: $e');
      return false;
    }
  }

  // Méthode pour créer un profil utilisateur si nécessaire
  Future<UserModel?> createUserProfileIfNeeded(String userId,
      {String? email, String? pseudo}) async {
    try {
      final exists = await userExists(userId);

      if (!exists) {
        final defaultPseudo = pseudo ?? email?.split('@')[0] ?? 'Utilisateur';

        // Créer un profil utilisateur de base
        await _supabase.from('app_user').insert({
          'id': userId,
          'pseudo': defaultPseudo,
          'inscription_date': DateTime.now().toIso8601String(),
          'birth_date':
              DateTime(2000, 1, 1).toIso8601String(), // Date par défaut
        });

        return UserModel(
          id: userId,
          pseudo: defaultPseudo,
          inscriptionDate: DateTime.now(),
          birthDate: DateTime(2000, 1, 1),
        );
      }

      return getUserProfile(userId);
    } catch (e) {
      debugPrint('Erreur lors de la création du profil utilisateur: $e');
      return null;
    }
  }
}
