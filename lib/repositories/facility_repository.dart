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

      return facilities;
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des installations sportives: $e');

      // En cas d'erreur, générer des données factices pour démonstration
      if (e.toString().contains('does not exist')) {
        return _generateMockFacilities();
      }

      return [];
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
              'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/3.png',
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
              'https://www.nageurscom.com/documents/image/news/2021/piscine-armand-massard-5-bassins-parisiens-prioritaires-jep.jpg',
          'description':
              'Piscine municipale avec un bassin de 25 mètres et des cours collectifs.',
          'opening_hours': 'Lun-Ven: 7h-22h, Sam-Dim: 8h-19h',
          'price_range': '3€-5€',
          'website':
              'https://www.paris.fr/equipements/piscine-armand-massard-2930',
          'phone': '01 45 38 65 28',
          'sports': [4] // IDs des sports: Natation
        },
        {
          'name': 'Tennis Club Frédéric Sarazin',
          'address': '99 Boulevard Kellermann, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8188,
          'longitude': 2.3401,
          'photo_url':
              'https://www.paris.fr/media/tennis-4_115886/cover-r4x3w1000-5f7452f3d54b8-tennis-courts-courts-67533.jpg',
          'description':
              'Club de tennis avec courts couverts et découverts, proposant des cours et la location de terrains.',
          'opening_hours': 'Tous les jours: 8h-22h',
          'price_range': '15€-25€/heure',
          'website': 'https://www.paris.fr/equipements/tennis-sarazin-2475',
          'phone': '01 47 34 74 81',
          'sports': [2] // IDs des sports: Tennis
        },
        {
          'name': 'Gymnase Cévennes',
          'address': '11 Rue des Cévennes, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8416,
          'longitude': 2.2796,
          'photo_url':
              'https://www.leparisien.fr/resizer/s2oI075W3qw7Lw-bFJbX52YVS8s=/622x389/cloudfront-eu-central-1.images.arcpublishing.com/leparisien/F2ZK7FTFPRDBDCCXXZVKWMX4LE.jpg',
          'description':
              'Gymnase municipal proposant plusieurs activités sportives, notamment le basketball et le volleyball.',
          'opening_hours': 'Lun-Ven: 9h-22h, Sam: 9h-19h, Dim: 9h-17h',
          'price_range': 'Gratuit-10€',
          'website': 'https://www.paris.fr/equipements/gymnase-cevennes-8044',
          'phone': '01 45 57 28 59',
          'sports': [1, 5] // IDs des sports: Basketball, Volleyball
        },
        {
          'name': 'Stade Suzanne Lenglen',
          'address': '2 Rue Louis Armand, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8314,
          'longitude': 2.2775,
          'photo_url':
              'https://www.paris.fr/media/suzanne-lenglen-sdpe_34626/cover-r4x3w1000-579609c4d5720-suzanne-lenglen-sdpe.jpg',
          'description':
              'Grand complexe sportif avec terrains de football, courts de tennis, piste d\'athlétisme et salles de fitness.',
          'opening_hours': 'Lun-Dim: 8h-22h',
          'price_range': '5€-20€',
          'website':
              'https://www.paris.fr/equipements/stade-suzanne-lenglen-2677',
          'phone': '01 58 14 20 00',
          'sports': [
            1,
            2,
            3,
            9
          ] // IDs des sports: Basketball, Tennis, Football, Course à pied
        },
        {
          'name': 'Salle d\'Escalade MurMur Issy-les-Moulineaux',
          'address':
              '91-95 Boulevard Gallieni, 92130 Issy-les-Moulineaux (proche 15ème)',
          'arrondissement': 'Proche 15ème',
          'latitude': 48.8253,
          'longitude': 2.2651,
          'photo_url':
              'https://media.routard.com/image/87/0/murmur.1473870.jpg',
          'description':
              'Grande salle d\'escalade avec plus de 150 voies, cours pour tous niveaux.',
          'opening_hours': 'Lun-Ven: 12h-23h, Sam-Dim: 10h-19h',
          'price_range': '15€-22€',
          'website': 'https://www.murmur.fr/',
          'phone': '01 58 88 72 50',
          'sports': [7] // IDs des sports: Escalade
        },
        {
          'name': 'Fitness Park Convention',
          'address': '204 Rue de la Convention, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8387,
          'longitude': 2.2932,
          'photo_url':
              'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/67/c6/37/caption.jpg?w=1200&h=-1&s=1',
          'description':
              'Salle de fitness avec équipements de musculation, cardio et cours collectifs.',
          'opening_hours': 'Lun-Dim: 6h-23h',
          'price_range': '20€-40€/mois',
          'website': 'https://www.fitnesspark.fr/',
          'phone': '01 45 54 32 78',
          'sports': [6] // IDs des sports: Fitness
        },
        {
          'name': 'Parc André Citroën',
          'address': '2 Rue Cauchy, 75015 Paris',
          'arrondissement': '15ème',
          'latitude': 48.8417,
          'longitude': 2.2753,
          'photo_url':
              'https://www.unjourdeplusaparis.com/wp-content/uploads/2016/08/parc-andre-citroen-paris.jpg',
          'description':
              'Grand parc avec parcours de jogging et espaces pour activités sportives en plein air.',
          'opening_hours': 'Ouvert tous les jours de 8h à 20h',
          'price_range': 'Gratuit',
          'website': 'https://www.paris.fr/equipements/parc-andre-citroen-1791',
          'phone': '01 53 98 98 98',
          'sports': [9, 10] // IDs des sports: Course à pied, Yoga en plein air
        },
        {
          'name': 'Complexe Sportif Jean Bouin',
          'address': '20-40 Avenue du Général Sarrail, 75016 Paris',
          'arrondissement': '16ème',
          'latitude': 48.8434,
          'longitude': 2.2519,
          'photo_url':
              'https://www.paris.fr/media/jean-bouin_34570/cover-r4x3w1000-579609de68a66-jean-bouin.jpg',
          'description':
              'Grand complexe sportif offrant des terrains de rugby, football, hockey et des pistes d\'athlétisme. Le stade Jean Bouin est également connu pour accueillir des événements sportifs majeurs.',
          'opening_hours': 'Lun-Dim: 8h-22h (selon activités)',
          'price_range': '5€-25€ selon activités',
          'website': 'https://www.paris.fr/equipements/stade-jean-bouin-9234',
          'phone': '01 40 71 33 64',
          'sports': [3, 9, 1] // Football, Course à pied, Basketball
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
          debugPrint('Erreur lors de l\'insertion: $e');
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
            'https://www.paris.fr/media/emile-anthoine-sdpe_34617/cover-r4x3w1000-579609ab1be56-emile-anthoine-sdpe.jpg',
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
            'https://www.nageurscom.com/documents/image/news/2021/piscine-armand-massard-5-bassins-parisiens-prioritaires-jep.jpg',
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
            'https://www.paris.fr/media/tennis-4_115886/cover-r4x3w1000-5f7452f3d54b8-tennis-courts-courts-67533.jpg',
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
            'https://www.leparisien.fr/resizer/s2oI075W3qw7Lw-bFJbX52YVS8s=/622x389/cloudfront-eu-central-1.images.arcpublishing.com/leparisien/F2ZK7FTFPRDBDCCXXZVKWMX4LE.jpg',
        description:
            'Gymnase municipal proposant plusieurs activités sportives, notamment le basketball et le volleyball.',
        openingHours: 'Lun-Ven: 9h-22h, Sam: 9h-19h, Dim: 9h-17h',
        priceRange: 'Gratuit-10€',
        website: 'https://www.paris.fr/equipements/gymnase-cevennes-8044',
        phone: '01 45 57 28 59',
        sportIds: [1, 5],
      ),
    ];
  }

  // Récupérer les installations sportives filtrées par arrondissement
  Future<List<SportFacilityModel>> getFacilitiesByArrondissement(
      String arrondissement) async {
    try {
      final facilitiesData = await _supabase
          .from('sport_facility')
          .select('*')
          .eq('arrondissement', arrondissement)
          .order('name');

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

      return facilities;
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des installations par arrondissement: $e');
      return [];
    }
  }

  // Récupérer les installations sportives par sport
  Future<List<SportFacilityModel>> getFacilitiesBySport(int sportId) async {
    try {
      // Récupérer les IDs des installations qui proposent ce sport
      final facilitySports = await _supabase
          .from('facility_sport')
          .select('id_facility')
          .eq('id_sport', sportId);

      if (facilitySports.isEmpty) {
        return [];
      }

      List<int> facilityIds =
          facilitySports.map<int>((fs) => fs['id_facility'] as int).toList();

      // Récupérer les détails des installations
      final facilitiesData = await _supabase
          .from('sport_facility')
          .select('*')
          .in_('id_facility', facilityIds)
          .order('name');

      List<SportFacilityModel> facilities = [];

      for (var facilityData in facilitiesData) {
        // Récupérer tous les sports associés à cette installation
        final sportsData = await _supabase
            .from('facility_sport')
            .select('id_sport')
            .eq('id_facility', facilityData['id_facility']);

        List<int> sportIds =
            sportsData.map<int>((sport) => sport['id_sport'] as int).toList();

        facilities
            .add(SportFacilityModel.fromJson(facilityData, sports: sportIds));
      }

      return facilities;
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des installations par sport: $e');
      return [];
    }
  }

  // Récupérer les détails d'une installation sportive spécifique
  Future<SportFacilityModel?> getFacilityById(int facilityId) async {
    try {
      final facilityData = await _supabase
          .from('sport_facility')
          .select('*')
          .eq('id_facility', facilityId)
          .single();

      final sportsData = await _supabase
          .from('facility_sport')
          .select('id_sport')
          .eq('id_facility', facilityId);

      List<int> sportIds =
          sportsData.map<int>((sport) => sport['id_sport'] as int).toList();

      return SportFacilityModel.fromJson(facilityData, sports: sportIds);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'installation: $e');
      return null;
    }
  }
}
