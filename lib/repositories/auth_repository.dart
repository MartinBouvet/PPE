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
    DateTime? birthDate, // Ajout du paramètre birthDate
    String gender = 'No Answer',
  }) async {
    try {
      // Vérifier que firstName n'est pas null ou vide (car NOT NULL dans la base)
      final String validFirstName = (firstName?.isNotEmpty == true) 
          ? firstName! 
          : "Utilisateur"; // Valeur par défaut si non fournie
      
      // Utiliser la date fournie ou la date actuelle si non fournie
      final DateTime validBirthDate = birthDate ?? DateTime(2000, 1, 1);
      
      // 1. Créer le compte d'authentification
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'pseudo': pseudo,
          'first_name': validFirstName,
        },
      );

      if (response.user == null) {
        throw Exception('Échec de création du compte');
      }

      final userId = response.user!.id;
      
      // 2. Insérer dans app_user avec TOUS les champs obligatoires
      try {
        // Formater la date au format YYYY-MM-DD pour PostgreSQL
        final formattedBirthDate = "${validBirthDate.year}-${validBirthDate.month.toString().padLeft(2, '0')}-${validBirthDate.day.toString().padLeft(2, '0')}";
        
        // Vérifier que le genre est valide
        if (!['Male', 'Female', 'Other', 'No Answer'].contains(gender)) {
          debugPrint('Genre invalide: $gender, utilisation de la valeur par défaut');
          gender = 'No Answer';
        } else {
          debugPrint('Genre valide: $gender');
        }

        // Préparer les données utilisateur
        final userData = {
          'id': userId,
          'pseudo': pseudo,
          'first_name': validFirstName,
          'birth_date': formattedBirthDate,
          'gender': gender,
          'inscription_date': DateTime.now().toIso8601String().split('T')[0], // Format YYYY-MM-DD
        };

        debugPrint('Données à insérer: $userData');

        // Utiliser une requête directe
        final result = await _supabase.from('app_user').insert(userData).select();
        debugPrint('Insertion réussie. Résultat: $result');
        
        // Attendre un peu pour s'assurer que les données sont bien enregistrées
        await Future.delayed(const Duration(milliseconds: 300));
        
        // 3. Récupérer le profil utilisateur depuis la base de données
        final userDataFromDb = await _supabase
            .from('app_user')
            .select()
            .eq('id', userId)
            .maybeSingle();
            
        if (userDataFromDb != null) {
          debugPrint('Utilisateur créé avec succès: $userDataFromDb');
          return UserModel.fromJson(userDataFromDb);
        } else {
          debugPrint('Utilisateur créé mais impossible de récupérer les données');
          // Retourner un modèle minimal
          return UserModel(
            id: userId,
            pseudo: pseudo,
            firstName: validFirstName,
            birthDate: validBirthDate,
            inscriptionDate: DateTime.now(),
          );
        }
      } catch (insertError) {
        debugPrint('Erreur détaillée lors de l\'insertion: $insertError');
        
        // Même si l'insertion échoue, nous retournons un modèle utilisateur minimal
        return UserModel(
          id: userId,
          pseudo: pseudo,
          firstName: validFirstName,
          birthDate: validBirthDate,
        );
      }
    } catch (e) {
      debugPrint('Erreur d\'inscription détaillée: $e');
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