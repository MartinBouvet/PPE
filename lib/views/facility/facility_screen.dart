import 'package:flutter/material.dart';
import '../../models/sport_model.dart';
import '../../repositories/sport_repository.dart';

// Modèle pour les installations sportives
class SportFacility {
  final String id;
  final String name;
  final String address;
  final double distance; // en km
  final List<int> sportIds;
  final String? photoUrl;
  final double rating;
  final String? openingHours;
  final double price; // prix par heure en euros

  SportFacility({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.sportIds,
    this.photoUrl,
    this.rating = 0.0,
    this.openingHours,
    this.price = 0.0,
  });
}

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({Key? key}) : super(key: key);

  @override
  _FacilityScreenState createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  final _sportRepository = SportRepository();
  List<SportModel> _sports = [];
  SportModel? _selectedSport;
  List<SportFacility> _facilities = [];
  List<SportFacility> _filteredFacilities = [];
  bool _isLoading = true;
  double _maxDistance = 10.0; // 10 km par défaut
  double _maxPrice = 50.0; // 50€ par défaut
  bool _isMapView = false; // Vue liste par défaut

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les sports
      _sports = await _sportRepository.getAllSports();
      if (_sports.isNotEmpty) {
        _selectedSport = _sports.first;
      }

      // Données fictives pour les installations sportives
      _facilities = [
        SportFacility(
          id: '1',
          name: 'Gymnase Jean Moulin',
          address: '28 Rue des Sports, Paris',
          distance: 2.3,
          sportIds: [1, 3, 5], // IDs des sports disponibles
          photoUrl:
              'https://images.unsplash.com/photo-1535131749006-b7f58c99034b',
          rating: 4.5,
          openingHours: 'Lun-Ven: 8h-22h, Week-end: 10h-18h',
          price: 15.0,
        ),
        SportFacility(
          id: '2',
          name: 'Centre sportif du Parc',
          address: '45 Avenue du Parc, Paris',
          distance: 3.7,
          sportIds: [1, 2, 4],
          photoUrl: 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8',
          rating: 4.2,
          openingHours: 'Lun-Dim: 9h-21h',
          price: 20.0,
        ),
        SportFacility(
          id: '3',
          name: 'Stade Municipal',
          address: '12 Rue des Athlètes, Paris',
          distance: 5.1,
          sportIds: [1, 5, 6],
          photoUrl:
              'https://images.unsplash.com/photo-1534710961216-75c88202f43e',
          rating: 3.8,
          openingHours: 'Lun-Sam: 10h-20h, Dim: Fermé',
          price: 12.0,
        ),
        SportFacility(
          id: '4',
          name: 'Court de Tennis ABC',
          address: '89 Boulevard des Raquettes, Paris',
          distance: 1.8,
          sportIds: [2],
          photoUrl:
              'https://images.unsplash.com/photo-1595435934349-5c8a329b5209',
          rating: 4.7,
          openingHours: 'Tous les jours: 7h-22h',
          price: 25.0,
        ),
        SportFacility(
          id: '5',
          name: 'Piscine Olympique',
          address: '34 Rue du Plongeon, Paris',
          distance: 8.2,
          sportIds: [3],
          photoUrl:
              'https://images.unsplash.com/photo-1571902943202-507ec2618e8f',
          rating: 4.3,
          openingHours: 'Lun-Ven: 7h-21h, Week-end: 9h-19h',
          price: 8.0,
        ),
      ];

      // Filtrer par défaut avec le premier sport
      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (_selectedSport == null) return;

    setState(() {
      _filteredFacilities = _facilities.where((facility) {
        // Filtrer par sport
        final hasSport = facility.sportIds.contains(_selectedSport!.id);

        // Filtrer par distance
        final isNearby = facility.distance <= _maxDistance;

        // Filtrer par prix
        final isAffordable = facility.price <= _maxPrice;

        return hasSport && isNearby && isAffordable;
      }).toList();

      // Trier par distance
      _filteredFacilities.sort((a, b) => a.distance.compareTo(b.distance));
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Filtre de distance
                  const Text(
                    'Distance maximale',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxDistance,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: '${_maxDistance.round()} km',
                          onChanged: (value) {
                            setModalState(() {
                              _maxDistance = value;
                            });
                          },
                        ),
                      ),
                      Text('${_maxDistance.round()} km'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filtre de prix
                  const Text(
                    'Budget maximum',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxPrice,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          label: '${_maxPrice.round()}€',
                          onChanged: (value) {
                            setModalState(() {
                              _maxPrice = value;
                            });
                          },
                        ),
                      ),
                      Text('${_maxPrice.round()}€'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        child: const Text('Appliquer'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFacilityCard(SportFacility facility) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: facility.photoUrl != null
                ? Image.network(
                    facility.photoUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.sports,
                          size: 50,
                          color: Colors.grey.shade700,
                        ),
                      );
                    },
                  )
                : Container(
                    height: 150,
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.sports,
                      size: 50,
                      color: Colors.grey.shade700,
                    ),
                  ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom et distance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        facility.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${facility.distance} km',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Adresse
                Text(
                  facility.address,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 8),

                // Horaires et évaluation
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        facility.openingHours ?? 'Horaires non disponibles',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(
                          ' ${facility.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${facility.price.toStringAsFixed(0)}€/heure',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigation vers l'écran de détail/réservation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Réservation pour ${facility.name}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Réserver'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lieux sportifs')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieux sportifs'),
        actions: [
          // Bouton pour changer de vue (liste/carte)
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            tooltip: _isMapView ? 'Vue liste' : 'Vue carte',
          ),
          // Bouton de filtres
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtres',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de sport
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _sports.isEmpty
                ? const Center(child: Text('Aucun sport disponible'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sports.length,
                    itemBuilder: (context, index) {
                      final sport = _sports[index];
                      final isSelected = _selectedSport?.id == sport.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(sport.name),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedSport = sport;
                            });
                            _applyFilters();
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Liste ou carte des installations
          Expanded(
            child: _isMapView
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 64, color: Colors.grey.shade400),
                        const Text('Vue carte non disponible dans cette démo'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isMapView = false;
                            });
                          },
                          child: const Text('Revenir à la liste'),
                        ),
                      ],
                    ),
                  )
                : _filteredFacilities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey.shade400),
                            const Text('Aucun lieu trouvé avec ces critères'),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _maxDistance = 20.0;
                                  _maxPrice = 100.0;
                                });
                                _applyFilters();
                              },
                              child: const Text('Élargir la recherche'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFacilities.length,
                        itemBuilder: (context, index) {
                          return _buildFacilityCard(_filteredFacilities[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
