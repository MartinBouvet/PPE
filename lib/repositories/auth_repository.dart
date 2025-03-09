import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = SupabaseConfig.client;

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
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      // Si l'utilisateur n'existe pas encore dans la table app_user
      if (e.toString().contains('Row not found')) {
        final authUser = _supabase.auth.currentUser;
        if (authUser != null) {
          return UserModel(id: authUser.id);
        }
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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Ajouter une date de naissance par défaut
        final DateTime defaultBirthDate = DateTime(2000, 1, 1);

        // Créer le profil utilisateur dans la table app_user
        await _supabase.from('app_user').insert({
          'id': response.user!.id,
          'pseudo': pseudo,
          'first_name': firstName,
          'birth_date': defaultBirthDate
              .toIso8601String(), // Ajout de la date de naissance
          'inscription_date': DateTime.now().toIso8601String(),
        });

        return UserModel(
          id: response.user!.id,
          pseudo: pseudo,
          firstName: firstName,
          birthDate:
              defaultBirthDate, // Inclure la date de naissance dans le modèle
          inscriptionDate: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Échec de l\'inscription: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Échec de la déconnexion: $e');
    }
  }
}
