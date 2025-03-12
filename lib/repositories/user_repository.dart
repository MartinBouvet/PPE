// lib/repositories/user_repository.dart
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
      final userData =
          await _supabase.from('app_user').select().eq('id', userId).single();

      debugPrint('Données utilisateur récupérées: $userData');
      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');

      // Nouvelle tentative avec une approche alternative
      try {
        final response = await _supabase
            .rpc('get_user_profile', params: {'user_id': userId});

        if (response != null) {
          return UserModel.fromJson(response);
        }
      } catch (rpcError) {
        debugPrint('Erreur RPC: $rpcError');
      }

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

  // Méthode améliorée pour mettre à jour le profil utilisateur
  Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      debugPrint('Tentative de mise à jour du profil utilisateur: $data');

      // S'assurer que les dates sont au bon format
      if (data.containsKey('birth_date') && data['birth_date'] != null) {
        if (data['birth_date'] is DateTime) {
          data['birth_date'] =
              (data['birth_date'] as DateTime).toIso8601String();
        }
      }

      // Tenter une mise à jour directe
      await _supabase.from('app_user').update(data).eq('id', userId);
      debugPrint('Profil utilisateur mis à jour avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil: $e');

      // Tenter avec upsert en cas d'erreur
      try {
        // Ajouter l'ID à l'objet data
        data['id'] = userId;

        await _supabase.from('app_user').upsert(data);
        debugPrint('Profil utilisateur mis à jour via upsert');
        return true;
      } catch (upsertError) {
        debugPrint('Erreur lors de l\'upsert: $upsertError');

        // Dernier recours: utiliser une RPC
        try {
          // Convertir data en un format compatible avec RPC
          final params = {
            'user_id': userId,
            ...data,
          };

          await _supabase.rpc('update_user_profile', params: params);
          debugPrint('Profil utilisateur mis à jour via RPC');
          return true;
        } catch (rpcError) {
          debugPrint('Erreur RPC: $rpcError');
          return false;
        }
      }
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

  // Méthode améliorée pour récupérer les sports de l'utilisateur
  Future<List<SportUserModel>> getUserSports(String userId) async {
    try {
      debugPrint(
          'Tentative de récupération des sports pour l\'utilisateur: $userId');
      final userSports =
          await _supabase.from('sport_user').select().eq('id_user', userId);

      debugPrint('Sports utilisateur récupérés: ${userSports.length}');

      return userSports
          .map<SportUserModel>((sport) => SportUserModel.fromJson(sport))
          .toList();
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des sports de l\'utilisateur: $e');

      // Tenter une approche alternative
      try {
        final response =
            await _supabase.rpc('get_user_sports', params: {'user_id': userId});

        if (response != null && response is List) {
          return response
              .map<SportUserModel>((sport) => SportUserModel.fromJson(sport))
              .toList();
        }
      } catch (rpcError) {
        debugPrint('Erreur RPC: $rpcError');
      }

      // Si tout échoue, retourner une liste vide
      return [];
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

  // Méthode améliorée pour créer un profil utilisateur si nécessaire
  Future<UserModel?> createUserProfileIfNeeded(String userId,
      {String? email,
      String? pseudo,
      String? firstName,
      String? photo,
      String? description}) async {
    try {
      final exists = await userExists(userId);

      if (!exists) {
        final defaultPseudo = pseudo ?? email?.split('@')[0] ?? 'Utilisateur';
        final now = DateTime.now();

        // Créer un profil utilisateur de base
        final userData = {
          'id': userId,
          'pseudo': defaultPseudo,
          'first_name': firstName,
          'photo': photo,
          'description': description,
          'inscription_date': now.toIso8601String(),
          'birth_date':
              DateTime(2000, 1, 1).toIso8601String(), // Date par défaut
          'gender': 'U', // Unspecified
        };

        // Supprimer les champs null
        userData.removeWhere((key, value) => value == null);

        await _supabase.from('app_user').insert(userData);
        debugPrint('Profil utilisateur créé avec succès');

        return UserModel(
          id: userId,
          pseudo: defaultPseudo,
          firstName: firstName,
          photo: photo,
          description: description,
          inscriptionDate: now,
          birthDate: DateTime(2000, 1, 1),
          gender: 'U',
        );
      }

      return getUserProfile(userId);
    } catch (e) {
      debugPrint('Erreur lors de la création du profil utilisateur: $e');

      // Tenter avec upsert en cas d'erreur
      try {
        final defaultPseudo = pseudo ?? email?.split('@')[0] ?? 'Utilisateur';
        final now = DateTime.now();

        final userData = {
          'id': userId,
          'pseudo': defaultPseudo,
          'first_name': firstName,
          'photo': photo,
          'description': description,
          'inscription_date': now.toIso8601String(),
          'birth_date': DateTime(2000, 1, 1).toIso8601String(),
          'gender': 'U',
        };

        // Supprimer les champs null
        userData.removeWhere((key, value) => value == null);

        await _supabase.from('app_user').upsert(userData);
        debugPrint('Profil utilisateur créé via upsert');

        return UserModel(
          id: userId,
          pseudo: defaultPseudo,
          firstName: firstName,
          photo: photo,
          description: description,
          inscriptionDate: now,
          birthDate: DateTime(2000, 1, 1),
          gender: 'U',
        );
      } catch (upsertError) {
        debugPrint('Erreur lors de l\'upsert: $upsertError');
        return null;
      }
    }
  }
}
