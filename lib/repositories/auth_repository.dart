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
        return null;
      }

      final userData = await _supabase
          .from('app_user') // Vérifiez que c'est bien 'app_user' et pas 'user'
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
    debugPrint('Utilisateur créé avec ID: $userId');

    // Vérifier que le genre est valide
    if (!['Male', 'Female', 'Other', 'No Answer'].contains(gender)) {
      gender = 'No Answer';
    }

    // Formater la date de naissance
    final userBirthDate = birthDate ?? DateTime(2000, 1, 1);
    final formattedBirthDate = "${userBirthDate.year.toString().padLeft(4, '0')}-${userBirthDate.month.toString().padLeft(2, '0')}-${userBirthDate.day.toString().padLeft(2, '0')}";

    // IMPORTANT: Attendre que la session soit établie
    await Future.delayed(const Duration(seconds: 1));

    // Vérifier si la session est active
    final currentSession = _supabase.auth.currentSession;
    if (currentSession == null) {
      debugPrint('ERREUR: Aucune session active après inscription');
      
      // Si l'email de confirmation est requis, nous pouvons quand même retourner un utilisateur
      return UserModel(
        id: userId,
        pseudo: pseudo,
        firstName: firstName,
        birthDate: userBirthDate,
        gender: gender,
      );
    }

    debugPrint('Session active. Token: ${currentSession.accessToken.substring(0, 10)}...');

    try {
      // Préparer les données utilisateur
      final userData = {
        'id': userId,
        'pseudo': pseudo,
        'first_name': firstName,
        'birth_date': formattedBirthDate,
        'gender': gender,
      };
      
      debugPrint('Tentative d\'insertion des données: $userData');
      
      // Utiliser une requête directe
      final result = await _supabase.from('app_user').insert(userData).select();
      debugPrint('Insertion réussie. Résultat: $result');
      
      // Retourner le modèle d'utilisateur
      return UserModel(
        id: userId,
        pseudo: pseudo,
        firstName: firstName,
        birthDate: userBirthDate,
        gender: gender,
        inscriptionDate: DateTime.now(),
      );
    } catch (insertError) {
      // Afficher l'erreur d'insertion complète
      debugPrint('Erreur détaillée lors de l\'insertion: $insertError');
      
      // Vérifiez si confirmation d'e-mail requise
      if (response.session == null) {
        debugPrint('Aucune session: vérification par e-mail probablement requise');
        return UserModel(
          id: userId,
          pseudo: pseudo,
          firstName: firstName,
          birthDate: userBirthDate,
          gender: gender,
        );
      }
      
      throw Exception('Échec de l\'insertion du profil utilisateur');
    }
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

  // Réinitialisation du mot de passe
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

  // Modification du mot de passe
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

  // Vérifier l'état de l'authentification et retourner l'utilisateur si connecté
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

  // Récupérer l'état d'authentification sous forme de Stream pour la réactivité
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
}