import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/match_repository.dart';
import 'profile_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  final _sportRepository = SportRepository();
  final _matchRepository = MatchRepository();

  UserModel? _currentUser;
  List<SportModel> _sports = [];
  SportModel? _selectedSport;
  List<UserModel> _potentialMatches = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  // Pour le filtrage
  final List<String> _levels = [
    'Tous niveaux',
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert'
  ];
  String _selectedLevel = 'Tous niveaux';
  double _maxDistance = 20.0; // km

  // Données simulées pour les utilisateurs
  final List<UserModel> _simulatedUsers = [
    UserModel(
      id: '1',
      pseudo: 'SportFan42',
      firstName: 'Sophie',
      description:
          'Passionnée de tennis et de randonnée. Recherche des partenaires pour des matchs amicaux.',
      photo: 'https://randomuser.me/api/portraits/women/32.jpg',
    ),
    UserModel(
      id: '2',
      pseudo: 'RunnerPro',
      firstName: 'Thomas',
      description:
          'Coureur semi-pro, 10km en 42min. Disponible le weekend pour des sessions d\'entraînement.',
      photo: 'https://randomuser.me/api/portraits/men/45.jpg',
    ),
    UserModel(
      id: '3',
      pseudo: 'YogaLover',
      firstName: 'Emma',
      description:
          'Prof de yoga cherchant à former un groupe pour des sessions en plein air.',
      photo: 'https://randomuser.me/api/portraits/women/63.jpg',
    ),
    UserModel(
      id: '4',
      pseudo: 'BasketballKing',
      firstName: 'Lucas',
      description:
          'Basketteur depuis 10 ans, niveau intermédiaire. Je cherche une équipe pour des matchs hebdomadaires.',
      photo: 'https://randomuser.me/api/portraits/men/22.jpg',
    ),
    UserModel(
      id: '5',
      pseudo: 'ClimbingQueen',
      firstName: 'Laura',
      description:
          'Passionnée d\'escalade. Je cherche des partenaires pour grimper en salle ou en extérieur.',
      photo: 'https://randomuser.me/api/portraits/women/43.jpg',
    ),
    UserModel(
      id: '6',
      pseudo: 'FootballFan',
      firstName: 'Julien',
      description:
          'Amateur de football du dimanche. Je recherche une équipe sympa pour des matchs à 5 ou 7.',
      photo: 'https://randomuser.me/api/portraits/men/67.jpg',
    ),
    UserModel(
      id: '7',
      pseudo: 'DanceQueen',
      firstName: 'Chloé',
      description:
          'Danseuse niveau intermédiaire. J\'adore la salsa et le rock, et je cherche des partenaires pour progresser.',
      photo: 'https://randomuser.me/api/portraits/women/17.jpg',
    ),
    UserModel(
      id: '8',
      pseudo: 'BoxingPro',
      firstName: 'Karim',
      description:
          'Boxeur depuis 5 ans. Je cherche des partenaires d\'entraînement sérieux pour progresser ensemble.',
      photo: 'https://randomuser.me/api/portraits/men/35.jpg',
    ),
  ];

  // Données simulées pour les sports des utilisateurs
  final Map<String, List<Map<String, dynamic>>> _simulatedUserSports = {
    '1': [
      {
        'sportId': 2,
        'level': 'Intermédiaire',
        'lookingForPartners': true
      }, // Tennis
      {
        'sportId': 5,
        'level': 'Débutant',
        'lookingForPartners': false
      }, // Randonnée
    ],
    '2': [
      {
        'sportId': 4,
        'level': 'Avancé',
        'lookingForPartners': true
      }, // Course à pied
    ],
    '3': [
      {'sportId': 6, 'level': 'Expert', 'lookingForPartners': true}, // Yoga
    ],
    '4': [
      {
        'sportId': 1,
        'level': 'Intermédiaire',
        'lookingForPartners': true
      }, // Basketball
    ],
    '5': [
      {'sportId': 7, 'level': 'Avancé', 'lookingForPartners': true}, // Escalade
    ],
    '6': [
      {
        'sportId': 3,
        'level': 'Débutant',
        'lookingForPartners': true
      }, // Football
    ],
    '7': [
      {
        'sportId': 8,
        'level': 'Intermédiaire',
        'lookingForPartners': true
      }, // Danse
    ],
    '8': [
      {'sportId': 9, 'level': 'Avancé', 'lookingForPartners': true}, // Boxe
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer l'utilisateur actuel
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        // Récupérer tous les sports
        _sports = await _sportRepository.getAllSports();

        if (_sports.isEmpty) {
          // Ajouter des sports par défaut si la liste est vide (pour la démo)
          _sports = [
            SportModel(id: 1, name: 'Basketball'),
            SportModel(id: 2, name: 'Tennis'),
            SportModel(id: 3, name: 'Football'),
            SportModel(id: 4, name: 'Course à pied'),
            SportModel(id: 5, name: 'Randonnée'),
            SportModel(id: 6, name: 'Yoga'),
            SportModel(id: 7, name: 'Escalade'),
            SportModel(id: 8, name: 'Danse'),
            SportModel(id: 9, name: 'Boxe'),
          ];
        }

        if (_sports.isNotEmpty) {
          _selectedSport = _sports.first;
          await _loadPotentialMatches();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPotentialMatches() async {
    if (_currentUser == null || _selectedSport == null) return;

    setState(() {
      _isSearching = true;
      _potentialMatches = [];
    });

    try {
      // Dans une vraie application, utilisez cette méthode pour obtenir les matchs depuis le repository
      // final matchingUserIds = await _matchRepository.getPotentialMatches(_currentUser!.id, _selectedSport!.id);

      // Pour la démo, nous simulons des données
      List<UserModel> filteredUsers = [];

      // Filtrer les utilisateurs par sport et niveau
      for (var user in _simulatedUsers) {
        // Ne pas inclure l'utilisateur actuel
        if (user.id == _currentUser!.id) continue;

        // Vérifier si l'utilisateur pratique le sport sélectionné
        final userSports = _simulatedUserSports[user.id] ?? [];
        final hasSport =
            userSports.any((sport) => sport['sportId'] == _selectedSport!.id);

        if (hasSport) {
          // Vérifier le niveau si un filtre est appliqué
          if (_selectedLevel != 'Tous niveaux') {
            final sportInfo = userSports.firstWhere(
              (sport) => sport['sportId'] == _selectedSport!.id,
              orElse: () => {'level': ''},
            );

            if (sportInfo['level'] != _selectedLevel) {
              continue;
            }
          }

          // Simuler une distance aléatoire
          final distance = Random().nextDouble() * 20;
          if (distance > _maxDistance) {
            continue;
          }

          filteredUsers.add(user);
        }
      }

      setState(() {
        _potentialMatches = filteredUsers;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des matchs: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSportSelected(SportModel sport) {
    setState(() {
      _selectedSport = sport;
      _potentialMatches = [];
    });
    _loadPotentialMatches();
  }

  void _showFilterDialog() {
    double tempMaxDistance = _maxDistance;
    String tempSelectedLevel = _selectedLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Filtre de niveau
                  const Text(
                    'Niveau',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tempSelectedLevel,
                    items: _levels.map((level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempSelectedLevel = value!;
                      });
                    },
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
                          value: tempMaxDistance,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${tempMaxDistance.round()} km',
                          onChanged: (value) {
                            setModalState(() {
                              tempMaxDistance = value;
                            });
                          },
                        ),
                      ),
                      Text('${tempMaxDistance.round()} km'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _maxDistance = tempMaxDistance;
                            _selectedLevel = tempSelectedLevel;
                          });
                          Navigator.pop(context);
                          _loadPotentialMatches();
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

  void _onLike(UserModel user) {
    // Dans une vraie application, appeler le repository
    // _matchRepository.createMatchRequest(_currentUser!.id, user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous avez proposé à ${user.pseudo ?? user.firstName}'),
        backgroundColor: Colors.green,
      ),
    );

    // Retirer l'utilisateur du deck
    setState(() {
      _potentialMatches.remove(user);
    });
  }

  void _onSkip(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Vous avez passé ${user.pseudo ?? user.firstName ?? "cet utilisateur"}'),
        duration: const Duration(seconds: 1),
      ),
    );

    // Retirer l'utilisateur du deck
    setState(() {
      _potentialMatches.remove(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Découvrir')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
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
                          onSelected: (_) => _onSportSelected(sport),
                          backgroundColor: Colors.grey[200],
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

          // Info filtrage
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Filtres: ${_selectedLevel}, max. ${_maxDistance.round()} km',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Indicateur de chargement pendant la recherche
          if (_isSearching) const LinearProgressIndicator(),

          // Message d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Liste des matches potentiels
          Expanded(
            child: _potentialMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? 'Recherche en cours...'
                              : 'Aucun match disponible pour ${_selectedSport?.name ?? "ce sport"}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Essayez d\'autres filtres ou un autre sport',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        if (!_isSearching)
                          ElevatedButton.icon(
                            onPressed: _loadPotentialMatches,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                          ),
                      ],
                    ),
                  )
                : Stack(
                    children: _potentialMatches.map((user) {
                      // Créer des cartes empilées avec la dernière (premier élément de la liste) au-dessus
                      bool isTop = user == _potentialMatches.first;
                      return Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: isTop
                              ? 1.0
                              : 0.0, // Seule la carte du dessus est visible
                          duration: const Duration(milliseconds: 300),
                          child: ProfileCard(
                            user: user,
                            sport: _selectedSport!,
                            onLike: () => _onLike(user),
                            onSkip: () => _onSkip(user),
                            isActive:
                                isTop, // Seule la carte du dessus peut être swipée
                            sportLevel: _simulatedUserSports[user.id]
                                    ?.firstWhere(
                                        (sport) =>
                                            sport['sportId'] ==
                                            _selectedSport!.id,
                                        orElse: () =>
                                            {'level': 'Inconnu'})['level'] ??
                                'Inconnu',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
