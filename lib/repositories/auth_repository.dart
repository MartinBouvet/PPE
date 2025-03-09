import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = SupabaseConfig.client;

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
        // Créer le profil utilisateur dans la table app_user
        await _supabase.from('app_user').insert({
          'id': response.user!.id,
          'pseudo': pseudo,
          'first_name': firstName,
          'inscription_date': DateTime.now().toIso8601String(),
        });

        return UserModel(
          id: response.user!.id,
          pseudo: pseudo,
          firstName: firstName,
          inscriptionDate: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Échec de l\'inscription: $e');
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
        final userData =
            await _supabase
                .from('app_user')
                .select()
                .eq('id', response.user!.id)
                .single();

        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      throw Exception('Échec de la connexion: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final userData =
            await _supabase
                .from('app_user')
                .select()
                .eq('id', user.id)
                .single();

        return UserModel.fromJson(userData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
