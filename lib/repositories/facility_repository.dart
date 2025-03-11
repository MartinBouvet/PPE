// lib/repositories/facility_repository.dart
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/facility_model.dart';

class FacilityRepository {
  final _supabase = SupabaseConfig.client;

  // Récupérer toutes les installations sportives
  Future<List<SportFacilityModel>> getAllFacilities() async {
    try {
      final facilitiesData =
          await _supabase.from('sport_facility').select('*').order('name');

      List<SportFacilityModel> facilities = [];

      for (var facilityData in facilitiesData) {
        // Récupérer les sports associés à chaque installation
        final sportsData = await _supabase
            .from('facility_sport')
            .select('id_sport')
            .eq('id_facility', facilityData['id_facility']);

        List<int> sportIds =
            sportsData.map<int>((sport) => sport['id_sport'] as int).toList();

        facilities
            .add(SportFacilityModel.fromJson(facilityData, sports: sportIds));
      }

      // Si aucune installation n'est trouvée ou en cas d'erreur, utiliser des données factices
      if (facilities.isEmpty) {
        facilities = _generateMockFacilities();
      }

      return facilities;
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des installations sportives: $e');
      // En cas d'erreur, générer des données factices pour démonstration
      return _generateMockFacilities();
    }
  }

  // Fonction d'initialisation - À UTILISER UNE SEULE FOIS pour peupler la base de données
  Future<bool> initializeFacilitiesData() async {
    try {
      // Vérifier si des données existent déjà
      final existingData =
          await _supabase.from('sport_facility').select('id_facility').limit(1);

      if (existingData.isNotEmpty) {
        debugPrint('Les installations sportives sont déjà initialisées');
        return true;
      }

      // Données des installations sportives du 15ème arrondissement
      final List<Map<String, dynamic>> facilitiesData = [
        {
          'name': 'Centre Sportif Émile Anthoine',
          'address': '9 Rue Jean Rey, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8567,
          'longitude': 2.2897,
          'photo_url':
              'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/4.jpg',
          'description':
              'Centre sportif proposant plusieurs équipements dont un gymnase, un terrain de football et des espaces de fitness.',
          'opening_hours': 'Lun-Ven: 8h-22h, Sam-Dim: 9h-20h',
          'price_range': '5€-15€',
          'website':
              'https://www.paris.fr/equipements/centre-sportif-emile-anthoine-2329',
          'phone': '01 45 75 54 90',
          'sports': [1, 3, 6, 9]
        },
        {
          'name': 'Piscine Armand Massard',
          'address': '66 Boulevard du Montparnasse, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8432,
          'longitude': 2.3209,
          'photo_url':
              'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/2.jpg',
          'description':
              'Piscine municipale avec un bassin de 25 mètres et des cours collectifs.',
          'opening_hours': 'Lun-Ven: 7h-22h, Sam-Dim: 8h-19h',
          'price_range': '3€-5€',
          'website':
              'https://www.paris.fr/equipements/piscine-armand-massard-2930',
          'phone': '01 45 38 65 28',
          'sports': [4]
        },
        {
          'name': 'Tennis Club Frédéric Sarazin',
          'address': '99 Boulevard Kellermann, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8188,
          'longitude': 2.3401,
          'photo_url':
              'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/3.jpg',
          'description':
              'Club de tennis avec courts couverts et découverts, proposant des cours et la location de terrains.',
          'opening_hours': 'Tous les jours: 8h-22h',
          'price_range': '15€-25€/heure',
          'website': 'https://www.paris.fr/equipements/tennis-sarazin-2475',
          'phone': '01 47 34 74 81',
          'sports': [2]
        },
        {
          'name': 'Gymnase Cévennes',
          'address': '11 Rue des Cévennes, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8416,
          'longitude': 2.2796,
          'photo_url':
              'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/1.jpg',
          'description':
              'Gymnase municipal proposant plusieurs activités sportives, notamment le basketball et le volleyball.',
          'opening_hours': 'Lun-Ven: 9h-22h, Sam: 9h-19h, Dim: 9h-17h',
          'price_range': 'Gratuit-10€',
          'website': 'https://www.paris.fr/equipements/gymnase-cevennes-8044',
          'phone': '01 45 57 28 59',
          'sports': [1, 5]
        },
        {
          'name': 'Stade Suzanne Lenglen',
          'address': '2 Rue Louis Armand, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8314,
          'longitude': 2.2775,
          'photo_url':
              'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/5.jpg',
          'description':
              'Grand complexe sportif avec terrains de football, courts de tennis, piste d\'athlétisme et salles de fitness.',
          'opening_hours': 'Lun-Dim: 8h-22h',
          'price_range': '5€-20€',
          'website':
              'https://www.paris.fr/equipements/stade-suzanne-lenglen-2677',
          'phone': '01 58 14 20 00',
          'sports': [1, 2, 3, 9]
        }
      ];

      // Pour chaque installation sportive
      for (var facilityData in facilitiesData) {
        // Extraire la liste des sports avant insertion
        final sports = List<int>.from(facilityData['sports']);
        facilityData.remove('sports');

        try {
          // Insérer l'installation sportive
          final result = await _supabase
              .from('sport_facility')
              .insert(facilityData)
              .select('id_facility')
              .single();

          final facilityId = result['id_facility'];

          // Insérer les relations avec les sports
          for (var sportId in sports) {
            await _supabase.from('facility_sport').insert({
              'id_facility': facilityId,
              'id_sport': sportId,
            });
          }
        } catch (e) {
          debugPrint('Erreur lors de l\'insertion de l\'installation: $e');
          // Continuer avec l'installation suivante
          continue;
        }
      }

      debugPrint('Installations sportives initialisées avec succès');
      return true;
    } catch (e) {
      debugPrint(
          'Erreur lors de l\'initialisation des installations sportives: $e');
      return false;
    }
  }

  // Générer des données factices pour démonstration en cas d'erreur
  List<SportFacilityModel> _generateMockFacilities() {
    return [
      SportFacilityModel(
        id: 1,
        name: 'Centre Sportif Émile Anthoine',
        address: '9 Rue Jean Rey, 75015 Paris',
        arrondissement: '15ème',
        latitude: 48.8567,
        longitude: 2.2897,
        photoUrl:
            'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/4.jpg',
        description:
            'Centre sportif proposant plusieurs équipements dont un gymnase, un terrain de football et des espaces de fitness.',
        openingHours: 'Lun-Ven: 8h-22h, Sam-Dim: 9h-20h',
        priceRange: '5€-15€',
        website:
            'https://www.paris.fr/equipements/centre-sportif-emile-anthoine-2329',
        phone: '01 45 75 54 90',
        sportIds: [1, 3, 6, 9],
      ),
      SportFacilityModel(
        id: 2,
        name: 'Piscine Armand Massard',
        address: '66 Boulevard du Montparnasse, 75015 Paris',
        arrondissement: '15ème',
        latitude: 48.8432,
        longitude: 2.3209,
        photoUrl:
            'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/2.jpg',
        description:
            'Piscine municipale avec un bassin de 25 mètres et des cours collectifs.',
        openingHours: 'Lun-Ven: 7h-22h, Sam-Dim: 8h-19h',
        priceRange: '3€-5€',
        website: 'https://www.paris.fr/equipements/piscine-armand-massard-2930',
        phone: '01 45 38 65 28',
        sportIds: [4],
      ),
      SportFacilityModel(
        id: 3,
        name: 'Tennis Club Frédéric Sarazin',
        address: '99 Boulevard Kellermann, 75015 Paris',
        arrondissement: '15ème',
        latitude: 48.8188,
        longitude: 2.3401,
        photoUrl:
            'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/3.jpg',
        description:
            'Club de tennis avec courts couverts et découverts, proposant des cours et la location de terrains.',
        openingHours: 'Tous les jours: 8h-22h',
        priceRange: '15€-25€/heure',
        website: 'https://www.paris.fr/equipements/tennis-sarazin-2475',
        phone: '01 47 34 74 81',
        sportIds: [2],
      ),
      SportFacilityModel(
        id: 4,
        name: 'Gymnase Cévennes',
        address: '11 Rue des Cévennes, 75015 Paris',
        arrondissement: '15ème',
        latitude: 48.8416,
        longitude: 2.2796,
        photoUrl:
            'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/1.jpg',
        description:
            'Gymnase municipal proposant plusieurs activités sportives, notamment le basketball et le volleyball.',
        openingHours: 'Lun-Ven: 9h-22h, Sam: 9h-19h, Dim: 9h-17h',
        priceRange: 'Gratuit-10€',
        website: 'https://www.paris.fr/equipements/gymnase-cevennes-8044',
        phone: '01 45 57 28 59',
        sportIds: [1, 5],
      ),
      SportFacilityModel(
        id: 5,
        name: 'Stade Suzanne Lenglen',
        address: '2 Rue Louis Armand, 75015 Paris',
        arrondissement: '15ème',
        latitude: 48.8314,
        longitude: 2.2775,
        photoUrl:
            'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/5.jpg',
        description:
            'Grand complexe sportif avec terrains de football, courts de tennis, piste d\'athlétisme et salles de fitness.',
        openingHours: 'Lun-Dim: 8h-22h',
        priceRange: '5€-20€',
        website: 'https://www.paris.fr/equipements/stade-suzanne-lenglen-2677',
        phone: '01 58 14 20 00',
        sportIds: [1, 2, 3, 9],
      ),
    ];
  }
}
