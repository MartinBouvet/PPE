import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  /// Récupère l'utilisateur actuellement connecté
  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return null;
      }

      final userData = await _supabase
          .from('app_user')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (userData == null) {
        // Utilisateur authentifié mais sans profil
        return UserModel(id: authUser.id);
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');
      // Si l'utilisateur existe dans auth mais pas dans app_user
      final authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        return UserModel(id: authUser.id);
      }
      return null;
    }
  }

  /// Connexion de l'utilisateur
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
        return getCurrentUser();
      }
      return null;
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      throw Exception('Échec de la connexion: $e');
    }
  }

  /// Inscription de l'utilisateur
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String pseudo,
    String? firstName,
    DateTime? birthDate,
    required String gender,
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

      // Vérifier si l'utilisateur existe déjà dans app_user
      final existingUser = await _supabase
          .from('app_user')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingUser != null) {
        // L'utilisateur existe déjà, pas besoin de l'insérer
        return UserModel.fromJson(existingUser);
      }

      try {
        // Créer le profil utilisateur dans la table app_user
        await _supabase.from('app_user').upsert({
          'id': userId,
          'pseudo': pseudo,
          'first_name': firstName,
          'birth_date': birthDate?.toIso8601String() ?? DateTime(2000, 1, 1).toIso8601String(),
          'gender': gender,
          'inscription_date': DateTime.now().toIso8601String(),
        }, onConflict: 'id');

        // Attendre un peu pour s'assurer que les données sont bien enregistrées
        await Future.delayed(const Duration(milliseconds: 500));

        // Retourner le profil utilisateur
        return UserModel(
          id: userId,
          pseudo: pseudo,
          firstName: firstName,
          birthDate: birthDate ?? DateTime(2000, 1, 1),
          gender: gender,
          inscriptionDate: DateTime.now(),
        );
      } catch (insertError) {
        debugPrint('Erreur lors de l\'insertion dans app_user: $insertError');
        // Même si l'insertion échoue, nous retournons un modèle utilisateur minimal
        return UserModel(
          id: userId,
          pseudo: pseudo,
          firstName: firstName,
          birthDate: birthDate,
          gender: gender,
        );
      }
    } catch (e) {
      debugPrint('Erreur d\'inscription: $e');
      throw Exception('Échec de l\'inscription: $e');
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      throw Exception('Échec de la déconnexion: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Erreur de réinitialisation: ${e.message}');
    } catch (e) {
      debugPrint('Erreur de réinitialisation: $e');
      throw Exception('Erreur de réinitialisation: $e');
    }
  }

  /// Modification du mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(
        password: newPassword,
      ));
    } on AuthException catch (e) {
      throw Exception('Erreur de modification: ${e.message}');
    } catch (e) {
      debugPrint('Erreur de modification: $e');
      throw Exception('Erreur de modification du mot de passe: $e');
    }
  }

  /// Vérifier l'état de l'authentification
  Future<UserModel?> checkAuthState() async {
    try {
      final session = await _supabase.auth.currentSession;

      if (session != null) {
        // Session valide, récupérer le profil utilisateur
        return getCurrentUser();
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'authentification: $e');
      return null;
    }
  }

  /// Écouter les changements d'état d'authentification
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
}