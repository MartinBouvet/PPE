import 'package:flutter/foundation.dart';
import '../models/badge_model.dart';
import '../config/supabase_config.dart';

class BadgeRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      // En production, nous utiliserions cette requête Supabase
      /*
      final response = await _supabase
        .from('badge_user')
        .select('id_badge, date_obtained, displayed_on_profile, badge(name, logo, description, requirements)')
        .eq('id_user', userId);
      
      return response.map<BadgeModel>((badgeData) {
        final badge = badgeData['badge'] as Map<String, dynamic>;
        return BadgeModel(
          id: badgeData['id_badge'],
          name: badge['name'],
          logo: badge['logo'],
          description: badge['description'] ?? '',
          requirements: badge['requirements'] ?? '',
          dateObtained: DateTime.parse(badgeData['date_obtained']),
          displayedOnProfile: badgeData['displayed_on_profile'] ?? true,
        );
      }).toList();
      */

      // Pour la démo, retournons des données factices
      await Future.delayed(
          const Duration(milliseconds: 300)); // Simuler un délai réseau

      return [
        BadgeModel(
          id: 'badge1',
          name: 'Padel Master',
          logo: 'https://cdn-icons-png.flaticon.com/512/4696/4696455.png',
          description: 'A participé à plus de 10 matchs de padel',
          requirements: 'Jouer 10 matchs de padel',
          dateObtained: DateTime.now().subtract(const Duration(days: 30)),
        ),
        BadgeModel(
          id: 'badge2',
          name: 'Runner Elite',
          logo: 'https://cdn-icons-png.flaticon.com/512/5073/5073994.png',
          description: 'A couru un total de 100km',
          requirements: 'Courir un total de 100km',
          dateObtained: DateTime.now().subtract(const Duration(days: 15)),
        ),
        BadgeModel(
          id: 'badge3',
          name: 'Socializer',
          logo: 'https://cdn-icons-png.flaticon.com/512/7163/7163912.png',
          description: 'A trouvé 5 nouveaux partenaires sportifs',
          requirements: 'Matcher avec 5 partenaires différents',
          dateObtained: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
    } catch (e) {
      debugPrint('Erreur lors du chargement des badges: $e');
      return [];
    }
  }
}
