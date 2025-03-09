import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../utils/supabase_helper.dart';
import 'preferences_service.dart';

/// Service de gestion de l'authentification
class AuthService {
  static final _supabase = SupabaseConfig.client;

  /// Vérifie si un utilisateur est actuellement connecté
  static bool isUserLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Récupère l'ID de l'utilisateur actuel ou null si non connecté
  static String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Récupère l'email de l'utilisateur actuel ou null si non connecté
  static String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  /// Récupère le profil complet de l'utilisateur actuel depuis la base de données
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final userData =
          await _supabase.from('app_user').select().eq('id', userId).single();

      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');

      // Si l'erreur indique que l'utilisateur n'existe pas dans la table app_user
      // mais qu'il est bien authentifié, retournons un modèle minimal
      if (e.toString().contains('Row not found') && isUserLoggedIn()) {
        final userId = getCurrentUserId();
        final email = getCurrentUserEmail();

        if (userId != null) {
          return UserModel(
            id: userId,
            pseudo: email?.split('@').first ?? 'Utilisateur',
          );
        }
      }

      return null;
    }
  }

  /// Connexion avec email et mot de passe
  static Future<UserModel?> signInWithEmailPassword(
      String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Sauvegarder l'ID utilisateur dans les préférences
        await PreferencesService.setLastUserId(response.user!.id);

        // Récupérer et retourner le profil complet
        return getCurrentUserProfile();
      }
      return null;
    } on AuthException catch (e) {
      // Gérer les erreurs d'authentification spécifiques
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Email ou mot de passe incorrect');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Inscription avec email et mot de passe
  static Future<UserModel?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String pseudo,
    String? firstName,
  }) async {
    try {
      // Créer le compte d'authentification
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Date par défaut pour les champs obligatoires
        final defaultDate = DateTime.now();

        // Créer le profil utilisateur dans la table app_user
        await _supabase.from('app_user').insert({
          'id': response.user!.id,
          'pseudo': pseudo,
          'first_name': firstName,
          'birth_date': DateTime(2000, 1, 1).toIso8601String(),
          'inscription_date': defaultDate.toIso8601String(),
        });

        // Sauvegarder l'ID utilisateur dans les préférences
        await PreferencesService.setLastUserId(response.user!.id);

        return UserModel(
          id: response.user!.id,
          pseudo: pseudo,
          firstName: firstName,
          birthDate: DateTime(2000, 1, 1),
          inscriptionDate: defaultDate,
        );
      }
      return null;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('Cet email est déjà utilisé');
      } else {
        throw Exception('Erreur d\'inscription: ${e.message}');
      }
    } catch (e) {
      debugPrint('Erreur d\'inscription: $e');
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  /// Déconnexion
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// Réinitialisation du mot de passe
  static Future<void> resetPassword(String email) async {
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
  static Future<void> updatePassword(String newPassword) async {
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

  /// Vérifier l'état de l'authentification et retourner l'utilisateur si connecté
  static Future<UserModel?> checkAuthState() async {
    try {
      final session = await _supabase.auth.currentSession;

      if (session != null) {
        // Session valide, récupérer le profil utilisateur
        return getCurrentUserProfile();
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'authentification: $e');
      return null;
    }
  }

  /// Récupérer l'état d'authentification sous forme de Stream pour la réactivité
  static Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
}
