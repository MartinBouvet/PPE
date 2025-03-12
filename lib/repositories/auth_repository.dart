// lib/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final _supabase = SupabaseConfig.client;

  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        debugPrint('Aucun utilisateur authentifié trouvé');
        return null;
      }

      debugPrint('Utilisateur auth trouvé: ${authUser.id}');

      try {
        // Vérifier si l'utilisateur existe dans app_user
        final userData = await _supabase
            .from('app_user')
            .select()
            .eq('id', authUser.id)
            .maybeSingle();

        if (userData == null) {
          debugPrint(
              'Utilisateur non trouvé dans app_user, création automatique');

          // Créer un profil utilisateur de base
          final newUserData = {
            'id': authUser.id,
            'pseudo': authUser.email?.split('@')[0] ?? 'Utilisateur',
            'inscription_date': DateTime.now().toIso8601String(),
            'birth_date': DateTime(2000, 1, 1).toIso8601String(),
            // Correction: Ajouter une valeur pour gender pour satisfaire la contrainte
            'gender': 'U', // U pour Unspecified
          };

          await _supabase.from('app_user').insert(newUserData);

          return UserModel.fromJson(newUserData);
        }

        debugPrint('Données utilisateur: $userData');
        return UserModel.fromJson(userData);
      } catch (e) {
        debugPrint('Erreur lors de la récupération du profil: $e');

        // Créer un modèle utilisateur minimal avec l'ID
        return UserModel(
          id: authUser.id,
          pseudo: authUser.email?.split('@')[0] ?? 'Utilisateur',
        );
      }
    } catch (e) {
      debugPrint('Erreur globale lors de la récupération du profil: $e');
      return null;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('Connexion réussie pour: ${response.user!.id}');

        // Vérifier si un profil existe dans app_user
        try {
          final userData = await _supabase
              .from('app_user')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (userData == null) {
            // Créer un profil utilisateur
            final newUserData = {
              'id': response.user!.id,
              'pseudo': email.split('@')[0],
              'inscription_date': DateTime.now().toIso8601String(),
              'birth_date': DateTime(2000, 1, 1).toIso8601String(),
              'gender': 'U', // Valeur par défaut pour gender
            };

            await _supabase.from('app_user').insert(newUserData);

            debugPrint('Profil utilisateur créé automatiquement');
          }
        } catch (e) {
          debugPrint('Erreur lors de la vérification/création du profil: $e');
        }

        return getCurrentUser();
      }
      return null;
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      throw Exception('Échec de la connexion: $e');
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String pseudo,
    String? firstName,
  }) async {
    try {
      // 1. Créer le compte d'authentification
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Échec de création du compte');
      }

      final userId = response.user!.id;

      // 2. Créer le profil utilisateur avec les champs obligatoires
      await _supabase.from('app_user').insert({
        'id': userId,
        'pseudo': pseudo,
        'first_name': firstName,
        'birth_date': DateTime(2000, 1, 1).toIso8601String(),
        'inscription_date': DateTime.now().toIso8601String(),
        'gender': 'U', // Valeur par défaut pour gender
      });

      return UserModel(
        id: userId,
        pseudo: pseudo,
        firstName: firstName,
        birthDate: DateTime(2000, 1, 1),
        inscriptionDate: DateTime.now(),
        gender: 'U',
      );
    } catch (e) {
      debugPrint('Erreur d\'inscription: $e');
      throw Exception('Échec de l\'inscription: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      throw Exception('Échec de la déconnexion: $e');
    }
  }
}
