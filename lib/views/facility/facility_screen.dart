// lib/views/facility/facility_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../models/user_model.dart';
import '../../models/facility_model.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/facility_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../services/image_service.dart';
import '../../utils/test_data_initializer.dart';
import 'facility_detail_screen.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({Key? key}) : super(key: key);

  @override
  _FacilityScreenState createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  final _authRepository = AuthRepository();
  final _facilityRepository = FacilityRepository();
  final _sportRepository = SportRepository();
  final _imageService = ImageService();

  UserModel? _user;
  List<SportFacilityModel> _facilities = [];
  List<SportModel> _sports = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedArrondissement;
  int? _selectedSportId;

  final List<String> _arrondissements = [
    'Tous',
    '1er',
    '2ème',
    '3ème',
    '4ème',
    '5ème',
    '6ème',
    '7ème',
    '8ème',
    '9ème',
    '10ème',
    '11ème',
    '12ème',
    '13ème',
    '14ème',
    '15ème',
    '16ème',
    '17ème',
    '18ème',
    '19ème',
    '20ème',
    'Proche 15ème',
  ];

  @override
  void initState() {
    super.initState();
    _selectedArrondissement = 'Tous';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _user = await _authRepository.getCurrentUser();

      // Charger les sports d'abord
      _sports = await _sportRepository.getAllSports();

      // Essayer de charger les installations depuis la base de données
      try {
        // Force l'initialisation des données de test avant de charger les installations
        await _facilityRepository.initializeFacilitiesData();

        // Ensuite charger les installations
        _facilities = await _facilityRepository.getAllFacilities();
        debugPrint('Nombre d\'installations chargées: ${_facilities.length}');
      } catch (facilityError) {
        debugPrint(
            'Erreur lors du chargement des installations: $facilityError');
        // Utiliser des installations factices en cas d'erreur
        _facilities = _generateMockFacilities();
      }

      // Si aucune installation n'est disponible ou moins de 2, utiliser les données factices
      if (_facilities.isEmpty || _facilities.length < 2) {
        debugPrint(
            "Utilisation des installations factices (moins de 2 trouvées)");
        _facilities = _generateMockFacilities();
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
      });
      debugPrint("ERREUR: $e");

      // En cas d'erreur générale, utiliser quand même les installations factices
      _facilities = _generateMockFacilities();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // Reste du code inchangé

  List<SportFacilityModel> _getFilteredFacilities() {
    // Si aucune installation n'est disponible ou s'il y en a moins de 2,
    // utiliser les installations factices générées localement
    if (_facilities.isEmpty || _facilities.length < 2) {
      debugPrint(
          "Utilisation des installations factices car moins de 2 installations trouvées");
      _facilities = _generateMockFacilities();
    }

    return _facilities.where((facility) {
      // Filtre de recherche par nom ou adresse
      final nameMatches =
          facility.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final addressMatches =
          facility.address.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtre par arrondissement
      final arrondissementMatches = _selectedArrondissement == null ||
          _selectedArrondissement == 'Tous' ||
          facility.arrondissement == _selectedArrondissement;

      // Filtre par sport
      final sportMatches = _selectedSportId == null ||
          facility.sportIds.contains(_selectedSportId);

      return (nameMatches || addressMatches) &&
          arrondissementMatches &&
          sportMatches;
    }).toList();
  }

  List<SportFacilityModel> _generateMockFacilities() {
    debugPrint("Génération d'installations sportives factices");
    return [
      SportFacilityModel(
        id: 1,
        name: 'Centre Sportif Émile Anthoine',
        address: '9 Rue Jean Rey, 75015 Paris',
        arrondissement: '15ème',
        latitude: 48.8567,
        longitude: 2.2897,
        photoUrl:
            'https://media.istockphoto.com/id/1311303481/photo/basketball-gym.jpg?s=612x612&w=0&k=20&c=ZJ4avELfbxhAYkTZKP-LmYPDH7wK2mglEJ_Tz9ArGPw=',
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
            'https://media.istockphoto.com/id/864327070/photo/swimming-lanes.jpg?s=612x612&w=0&k=20&c=1KJnkLwqa7U3CwVxeXQEXL-XQSIfqeV5wfP-BfE9vu0=',
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
            'https://media.istockphoto.com/id/139962036/photo/tennis-court.jpg?s=612x612&w=0&k=20&c=J5LskGbaQpZqfDYKJlHkQRMcnOuTkDLUSLAhg8ETZ8U=',
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
            'https://media.istockphoto.com/id/170096587/photo/empty-basketball-court.jpg?s=612x612&w=0&k=20&c=jCKwAkx-Vcic4CKfTVGh4n4T-MgJnVw52O7FV5Xptxo=',
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
            'https://media.istockphoto.com/id/468841758/photo/soccer-stadium.jpg?s=612x612&w=0&k=20&c=KLbMuBhW2oehmXMVU5hPdvUzXpqXuZ4xGNr5LH-hkqw=',
        description:
            'Grand complexe sportif avec terrains de football, courts de tennis, piste d\'athlétisme et salles de fitness.',
        openingHours: 'Lun-Dim: 8h-22h',
        priceRange: '5€-20€',
        website: 'https://www.paris.fr/equipements/stade-suzanne-lenglen-2677',
        phone: '01 58 14 20 00',
        sportIds: [1, 2, 3, 9],
      ),
      // Ajout de nouvelles installations pour garantir plus d'options
      SportFacilityModel(
        id: 6,
        name: 'Salle de Fitness Parc des Princes',
        address: '24 Rue du Commandant Guilbaud, 75016 Paris',
        arrondissement: '16ème',
        latitude: 48.8414,
        longitude: 2.2530,
        photoUrl:
            'https://media.istockphoto.com/id/1322158059/photo/empty-modern-gym-with-various-equipment.jpg?s=612x612&w=0&k=20&c=39RPTXfv3JTKNBBEiGO7uzGYZoyS6mE8U9q8mNGoh-w=',
        description:
            'Salle de fitness moderne avec équipements de musculation et de cardio, ainsi que des cours collectifs.',
        openingHours: 'Lun-Dim: 6h-23h',
        priceRange: '15€-30€',
        website: 'https://example.com/fitness-parc-princes',
        phone: '01 45 24 67 89',
        sportIds: [6, 8],
      ),
      SportFacilityModel(
        id: 7,
        name: 'Centre d\'Escalade Vertical Art',
        address: '18 Rue du Général Malleterre, 75016 Paris',
        arrondissement: 'Proche 15ème',
        latitude: 48.8393,
        longitude: 2.2624,
        photoUrl:
            'https://media.istockphoto.com/id/1366252784/photo/indoor-climbing-gym-with-exercise-equipment.jpg?s=612x612&w=0&k=20&c=B5JqVVpHDFJIc1yxpNwIMyeQxT9hBTkBzZAweCTt-9E=',
        description:
            'Centre d\'escalade indoor avec murs de différents niveaux de difficulté et cours pour tous les âges.',
        openingHours: 'Lun-Ven: 11h-22h, Sam-Dim: 10h-20h',
        priceRange: '15€-20€',
        website: 'https://verticalart.fr',
        phone: '01 46 87 32 89',
        sportIds: [7],
      ),
    ];
  }

  // Méthode pour calculer une distance aléatoire mais cohérente pour chaque installation
  double _getRandomDistance(int facilityId) {
    // Utiliser l'ID comme seed pour avoir la même valeur à chaque fois
    final random = math.Random(facilityId);
    return random.nextDouble() * 10 + 0.1; // Entre 0.1 et 10.1 km
  }

  // Méthode pour obtenir une image aléatoire si l'installation n'en a pas
  String _getDefaultImage(int sportId) {
    final sportImages = {
      1: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/1.jpg', // Basketball
      2: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/3.jpg', // Tennis
      3: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/5.jpg', // Football
      4: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/2.jpg', // Natation
      5: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/8.jpg', // Randonnée
      6: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/4.jpg', // Yoga
      7: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/6.jpg', // Escalade
      8: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/8.jpg', // Fitness
      9: 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/8.jpg', // Course à pied
    };

    if (sportId > 0 && sportImages.containsKey(sportId)) {
      return '${sportImages[sportId]}?w=800&q=80';
    }

    // Image par défaut
    return 'https://aaygogjvrgskhmlgymik.supabase.co/storage/v1/object/public/bucket_image/images/logo.png';
  }

  // Format de prix en euros
  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) {
      return 'Prix non disponible';
    }
    if (price == 'Gratuit') return price;
    return price;
  }

  // Méthode pour obtenir le nom du sport à partir de son ID
  String _getSportName(int sportId) {
    final sport = _sports.firstWhere(
      (s) => s.id == sportId,
      orElse: () => SportModel(id: sportId, name: 'Sport $sportId'),
    );
    return sport.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredFacilities = _getFilteredFacilities();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installations sportives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une installation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filtres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Arrondissement',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    value: _selectedArrondissement ?? 'Tous',
                    items: _arrondissements
                        .map((arr) => DropdownMenuItem(
                              value: arr,
                              child: Text(arr),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedArrondissement = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: 'Sport',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                    value: _selectedSportId,
                    hint: const Text('Tous'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tous'),
                      ),
                      ..._sports.map((sport) => DropdownMenuItem(
                            value: sport.id,
                            child: Text(sport.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSportId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Liste des installations
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : filteredFacilities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_gymnastics,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune installation trouvée',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isNotEmpty ||
                                _selectedArrondissement != 'Tous' ||
                                _selectedSportId != null)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedArrondissement = 'Tous';
                                    _selectedSportId = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Effacer les filtres'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredFacilities.length,
                        itemBuilder: (context, index) {
                          final facility = filteredFacilities[index];

                          // Déterminer le sport principal pour l'image
                          int primarySportId = 0;
                          if (facility.sportIds.isNotEmpty) {
                            primarySportId = _selectedSportId != null &&
                                    facility.sportIds.contains(_selectedSportId)
                                ? _selectedSportId!
                                : facility.sportIds.first;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FacilityDetailScreen(
                                      facility: facility,
                                      sports: _sports,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: facility.photoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: facility.photoUrl!,
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 150,
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Image.network(
                                              _getDefaultImage(primarySportId),
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Image.network(
                                            _getDefaultImage(primarySportId),
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              height: 150,
                                              color: Colors.blue.shade100,
                                              child: Center(
                                                child: Icon(Icons.sports,
                                                    size: 48,
                                                    color:
                                                        Colors.blue.shade700),
                                              ),
                                            ),
                                          ),
                                  ),

                                  // Informations
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                facility.name,
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            // Badge avec la distance
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.directions_walk,
                                                      size: 14,
                                                      color: Colors
                                                          .green.shade800),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_getRandomDistance(facility.id).toStringAsFixed(1)} km',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .green.shade800,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 16,
                                                color: Colors.grey.shade700),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                facility.address,
                                                style: TextStyle(
                                                    color:
                                                        Colors.grey.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Prix
                                        if (facility.priceRange != null)
                                          Row(
                                            children: [
                                              Icon(Icons.euro,
                                                  size: 16,
                                                  color: Colors.grey.shade700),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatPrice(
                                                    facility.priceRange),
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),

                                        const SizedBox(height: 8),

                                        // Sports & Arrondissement
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                facility.arrondissement,
                                                style: TextStyle(
                                                    color: Colors.blue.shade800,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (facility.sportIds.isNotEmpty &&
                                                facility.sportIds.length <= 3)
                                              ...facility.sportIds
                                                  .take(3)
                                                  .map((sportId) {
                                                final sportName =
                                                    _getSportName(sportId);
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.green.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      sportName,
                                                      style: TextStyle(
                                                          color: Colors
                                                              .green.shade800,
                                                          fontSize: 10),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            if (facility.sportIds.length > 3)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  "+${facility.sportIds.length - 3} sports",
                                                  style: TextStyle(
                                                      color:
                                                          Colors.amber.shade800,
                                                      fontSize: 10),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
