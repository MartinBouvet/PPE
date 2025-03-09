import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/sport_model.dart';
import '../models/sport_user_model.dart';

class UserRepository {
  final _supabase = SupabaseConfig.client;

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final userData =
          await _supabase.from('app_user').select().eq('id', userId).single();

      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Échec de la récupération du profil: $e');
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase.from('app_user').update(data).eq('id', userId);
    } catch (e) {
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
      throw Exception('Échec de la récupération des sports: $e');
    }
  }

  Future<List<SportUserModel>> getUserSports(String userId) async {
    try {
      final userSports = await _supabase
          .from('sport_user')
          .select()
          .eq('id_user', userId);

      return userSports
          .map<SportUserModel>((sport) => SportUserModel.fromJson(sport))
          .toList();
    } catch (e) {
      throw Exception(
        'Échec de la récupération des sports de l\'utilisateur: $e',
      );
    }
  }
}
