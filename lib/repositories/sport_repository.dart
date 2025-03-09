import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/sport_model.dart';

class SportRepository {
  final _supabase = SupabaseConfig.client;

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

  Future<SportModel?> getSportById(int sportId) async {
    try {
      final sport = await _supabase
          .from('sport')
          .select()
          .eq('id_sport', sportId)
          .single();

      return SportModel.fromJson(sport);
    } catch (e) {
      throw Exception('Échec de la récupération du sport: $e');
    }
  }

  Future<void> addSport(
      String name, String? description, String? logoUrl) async {
    try {
      await _supabase.from('sport').insert({
        'name': name,
        'description': description,
        'logo': logoUrl,
      });
    } catch (e) {
      throw Exception('Échec de l\'ajout du sport: $e');
    }
  }
}
