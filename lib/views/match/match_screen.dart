// lib/views/match/match_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import '../../models/match_model.dart';
import '../../models/sport_user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/match_repository.dart';
import '../../utils/test_data_initializer.dart';
import '../chat/conversation_screen.dart';
import '../discover/profile_card.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  final _sportRepository = SportRepository();
  final _matchRepository = MatchRepository();

  late TabController _tabController;
  UserModel? _currentUser;
  List<SportModel> _sports = [];
  Map<int, List<UserModel>> _potentialMatches = {};
  List<MatchModel> _pendingRequests = [];
  List<MatchModel> _acceptedMatches = [];
  Map<String, UserModel?> _usersMap = {};
  Map<String, Map<int, SportUserModel>> _userSportsMap = {};
  Map<int, SportModel> _sportsMap = {};

  int? _selectedSportId;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _showEmptyMatchMessage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showEmptyMatchMessage = false;
    });

    try {
      // Get current user
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        // Get all sports
        _sports = await _sportRepository.getAllSports();

        // Create sport lookup map
        _sportsMap = {for (var sport in _sports) sport.id: sport};

        // Set initial selected sport (first sport, or null if no sports)
        if (_selectedSportId == null && _sports.isNotEmpty) {
          _selectedSportId = _sports.first.id;
        }

        // Load potential matches, pending requests, and accepted matches
        await Future.wait([
          _loadPotentialMatches(),
          _loadPendingRequests(),
          _loadAcceptedMatches(),
        ]);

        // If there are no users in the system, initialize test data
        if (_usersMap.isEmpty) {
          debugPrint("Aucun utilisateur trouvé, initialisation des données de test...");
          
          // Try to initialize test data
          await TestDataInitializer.initializeAllTestData();
          
          // Reload data after initialization
          await Future.wait([
            _loadPotentialMatches(),
            _loadPendingRequests(),
            _loadAcceptedMatches(),
          ]);
        }

        // Load user sport info for each potential match
        await _loadUserSportInfo();
      } else {
        setState(() {
          _errorMessage =
              'Vous devez être connecté pour accéder à cette fonctionnalité';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
      });
      debugPrint("ERREUR MATCH SCREEN: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Show empty message after a delay if no matches
          if (_currentUser != null &&
              _potentialMatches.isEmpty &&
              _pendingRequests.isEmpty &&
              _acceptedMatches.isEmpty) {
            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _showEmptyMatchMessage = true;
                });
              }
            });
          }
        });
      }
    }
  }

  Future<void> _loadPotentialMatches() async {
    if (_currentUser == null) return;

    try {
      _potentialMatches.clear();

      // Pour chaque sport, chercher les matches potentiels
      for (final sport in _sports) {
        final matchIds = await _matchRepository.getPotentialMatches(
            _currentUser!.id, sport.id);

        if (matchIds.isNotEmpty) {
          List<UserModel> users = [];

          for (final userId in matchIds) {
            final user = await _userRepository.getUserProfile(userId);
            if (user != null) {
              users.add(user);
              _usersMap[userId] = user;
            }
          }

          if (users.isNotEmpty) {
            _potentialMatches[sport.id] = users;
          }
        }
      }

      // Si aucun match n'a été trouvé, générer des utilisateurs factices
      // pour démonstration
      if (_potentialMatches.isEmpty && _selectedSportId != null) {
        _generateDemoUsers(_selectedSportId!);
      }
    } catch (e) {
      debugPrint('Error loading potential matches: $e');
    }
  }

  // Fonction pour générer des utilisateurs factices pour la démo
  void _generateDemoUsers(int sportId) {
    debugPrint("Génération d'utilisateurs factices pour la démo");
    
    final demoUsers = [
      UserModel(
        id: 'demo1',
        pseudo: 'SportFan42',
        firstName: 'Sophie',
        description:
            'Passionnée de sport et toujours partante pour une nouvelle activité !',
        photo: 'https://randomuser.me/api/portraits/women/32.jpg',
      ),
      UserModel(
        id: 'demo2',
        pseudo: 'RunnerPro',
        firstName: 'Thomas',
        description:
            'Coureur semi-pro, 10km en 42min. Disponible le weekend pour des sessions d\'entraînement.',
        photo: 'https://randomuser.me/api/portraits/men/45.jpg',
      ),
      UserModel(
        id: 'demo3',
        pseudo: 'YogaLover',
        firstName: 'Emma',
        description:
            'Prof de yoga cherchant à former un groupe pour des sessions en plein air.',
        photo: 'https://randomuser.me/api/portraits/women/63.jpg',
      ),
      UserModel(
        id: 'demo4',
        pseudo: 'BasketballKing',
        firstName: 'Lucas',
        description:
            'Basketteur depuis 10 ans, niveau intermédiaire. Je cherche une équipe pour des matchs hebdomadaires.',
        photo: 'https://randomuser.me/api/portraits/men/22.jpg',
      ),
    ];

    _potentialMatches[sportId] = demoUsers;

    for (var user in demoUsers) {
      _usersMap[user.id] = user;

      // Ajouter des informations de sport factices
      if (_userSportsMap[user.id] == null) {
        _userSportsMap[user.id] = {};
      }

      _userSportsMap[user.id]![sportId] = SportUserModel(
        userId: user.id,
        sportId: sportId,
        skillLevel: [
          'Débutant',
          'Intermédiaire',
          'Avancé',
          'Expert'
        ][demoUsers.indexOf(user) % 4],
        lookingForPartners: true,
      );
    }
    
    debugPrint("${demoUsers.length} utilisateurs factices générés");
  }

  Future<void> _loadPendingRequests() async {
    if (_currentUser == null) return;

    try {
      _pendingRequests =
          await _matchRepository.getPendingMatchRequests(_currentUser!.id);

      for (final request in _pendingRequests) {
        if (!_usersMap.containsKey(request.requesterId)) {
          final user =
              await _userRepository.getUserProfile(request.requesterId);
          if (user != null) {
            _usersMap[request.requesterId] = user;
          }
        }
      }
      
      debugPrint("Nombre de demandes en attente: ${_pendingRequests.length}");
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }
  }

  Future<void> _loadAcceptedMatches() async {
    if (_currentUser == null) return;

    try {
      _acceptedMatches =
          await _matchRepository.getAcceptedMatches(_currentUser!.id);

      for (final match in _acceptedMatches) {
        // Get the other user ID (requester or liked user)
        final otherUserId = match.requesterId == _currentUser!.id
            ? match.likedUserId
            : match.requesterId;

        if (!_usersMap.containsKey(otherUserId)) {
          final user = await _userRepository.getUserProfile(otherUserId);
          if (user != null) {
            _usersMap[otherUserId] = user;
          }
        }
      }
      
      debugPrint("Nombre de matches acceptés: ${_acceptedMatches.length}");
    } catch (e) {
      debugPrint('Error loading accepted matches: $e');
    }
  }

  Future<void> _loadUserSportInfo() async {
    if (_currentUser == null) return;

    try {
      // Pour chaque utilisateur, charger ses informations sportives
      for (final userId in _usersMap.keys) {
        if (_userSportsMap[userId] == null) {
          _userSportsMap[userId] = {};
          final userSports = await _userRepository.getUserSports(userId);

          for (final sport in userSports) {
            _userSportsMap[userId]![sport.sportId] = sport;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user sport info: $e');
    }
  }

  Future<void> _sendMatchRequest(String userId) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _matchRepository.createMatchRequest(
        _currentUser!.id,
        userId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande de partenariat envoyée')),
        );

        // Refresh data
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l\'envoi de la demande')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _respondToMatchRequest(String requesterId, bool accept) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _matchRepository.respondToMatchRequest(
        requesterId,
        _currentUser!.id,
        accept,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(accept
                  ? 'Demande de partenariat acceptée'
                  : 'Demande de partenariat refusée')),
        );

        // Refresh data
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la réponse à la demande')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _startConversation(String userId, String pseudo) async {
    if (_currentUser == null) return;

    try {
      // TODO: Implement this with a ChatRepository
      // For now, just navigate to a dummy conversation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            conversationId: 'match_${_currentUser!.id}_$userId',
            otherUserPseudo: pseudo,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _selectSport(int sportId) {
    setState(() {
      _selectedSportId = sportId;
    });
  }

  List<UserModel> _getCurrentPotentialMatches() {
    if (_selectedSportId == null) return [];

    var matches = _potentialMatches[_selectedSportId] ?? [];

    // Si aucun match et que c'est en mode démo, on génère des utilisateurs
    if (matches.isEmpty && _selectedSportId != null) {
      _generateDemoUsers(_selectedSportId!);
      return _potentialMatches[_selectedSportId] ?? [];
    }

    return matches;
  }

  List<UserModel> _getFilteredRequests() {
    return _pendingRequests
        .map((request) => _usersMap[request.requesterId])
        .whereType<UserModel>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partenaires')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partenaires')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Vous devez être connecté pour accéder à cette fonctionnalité',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.pop(context);
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partenaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              text: 'Découvrir',
              icon: Icon(Icons.explore),
            ),
            Tab(
              text: 'Demandes',
              icon: Badge(
                isLabelVisible: _pendingRequests.isNotEmpty,
                label: Text(_pendingRequests.length.toString()),
                child: const Icon(Icons.person_add),
              ),
            ),
            Tab(
              text: 'Mes matches',
              icon: Badge(
                isLabelVisible: _acceptedMatches.isNotEmpty,
                label: Text(_acceptedMatches.length.toString()),
                child: const Icon(Icons.favorite),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Loading indicator
          if (_isProcessing) const LinearProgressIndicator(),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Sport filter chips for Discover tab
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _tabController.index == 0 && _sports.isNotEmpty
                ? Container(
                    key: const ValueKey('sport-filters'),
                    height: 60,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _sports.map((sport) {
                        final isSelected = _selectedSportId == sport.id;
                        final hasMatches =
                            _potentialMatches.containsKey(sport.id) &&
                                _potentialMatches[sport.id]!.isNotEmpty;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(sport.name),
                            selected: isSelected,
                            onSelected: (_) => _selectSport(sport.id),
                            avatar:
                                hasMatches ? const Icon(Icons.people) : null,
                            backgroundColor:
                                hasMatches ? Colors.green.shade100 : null,
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty-filters'), height: 0),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Discover tab
                _buildDiscoverTab(),

                // Requests tab
                _buildRequestsTab(),

                // Matches tab
                _buildMatchesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final potentialMatches = _getCurrentPotentialMatches();

    // Aucun sport sélectionné
    if (_selectedSportId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'Sélectionnez un sport pour commencer',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 250,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                "Balayez les profils vers la droite pour proposer un match, ou vers la gauche pour passer",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    // Aucun match potentiel pour ce sport
    if (potentialMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _showEmptyMatchMessage
                  ? 'Aucun partenaire trouvé pour ${_sportsMap[_selectedSportId]?.name ?? "ce sport"}'
                  : 'Recherche de partenaires...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez un autre sport ou revenez plus tard',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Stack de cartes pour la pile de profils
    return Stack(
      children: potentialMatches.map((user) {
        // La première carte (dernier élément) est au-dessus
        final isTop = user == potentialMatches.first;

        // Trouver le niveau de compétence pour ce sport
        final sportInfo = _userSportsMap[user.id]?[_selectedSportId!];
        final skillLevel = sportInfo?.skillLevel ?? 'Intermédiaire';

        return Positioned.fill(
          child: AnimatedOpacity(
            opacity: isTop ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: ProfileCard(
              user: user,
              sport: _sportsMap[_selectedSportId]!,
              onLike: () {
                if (user.id.startsWith('demo')) {
                  // Pour les utilisateurs de démo, on simule un match
                  setState(() {
                    potentialMatches.remove(user);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match proposé avec succès !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  });
                } else {
                  _sendMatchRequest(user.id);
                }
              },
              onSkip: () {
                setState(() {
                  potentialMatches.remove(user);
                });
              },
              isActive: isTop,
              sportLevel: skillLevel,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRequestsTab() {
    final filteredRequests = _getFilteredRequests();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _pendingRequests.isEmpty
                  ? 'Aucune demande de partenariat en attente'
                  : 'Aucune demande ne correspond à votre recherche',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                "Lorsque quelqu'un vous propose un match, la demande apparaîtra ici",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final requester = filteredRequests[index];
        final request = _pendingRequests.firstWhere(
          (req) => req.requesterId == requester.id,
          orElse: () => MatchModel(
            requesterId: requester.id,
            likedUserId: _currentUser!.id,
            requestStatus: 'pending',
            requestDate: DateTime.now(),
          ),
        );

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: requester.photo != null
                ? CachedNetworkImageProvider(requester.photo!)
                : null,
            child: requester.photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(requester.pseudo ?? 'Utilisateur inconnu'),
          subtitle: const Text('Veut être votre partenaire sportif'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _respondToMatchRequest(requester.id, false),
                tooltip: 'Refuser',
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _respondToMatchRequest(requester.id, true),
                tooltip: 'Accepter',
              ),
            ],
          ),
          onTap: () {
            // TODO: Navigate to user profile
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonctionnalité à venir')),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    if (_acceptedMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Vous n\'avez pas encore de partenaires',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    "Proposez à des utilisateurs pour trouver vos partenaires de sport",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.pink.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.explore),
                    label: const Text('Découvrir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _acceptedMatches.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final match = _acceptedMatches[index];

        // Get the other user (requester or liked user)
        final otherUserId = match.requesterId == _currentUser!.id
            ? match.likedUserId
            : match.requesterId;
        final user = _usersMap[otherUserId];

        if (user == null) {
          return const SizedBox.shrink();
        }

        // Trouver les sports en commun
        final currentUserSports =
            _userSportsMap[_currentUser!.id]?.keys.toSet() ?? {};
        final otherUserSports = _userSportsMap[user.id]?.keys.toSet() ?? {};
        final commonSportIds =
            currentUserSports.intersection(otherUserSports).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: InkWell(
            onTap: () => _startConversation(
              user.id,
              user.pseudo ?? 'Utilisateur',
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'avatar-${user.id}',
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: user.photo != null
                              ? CachedNetworkImageProvider(user.photo!)
                              : null,
                          child: user.photo == null
                              ? Icon(Icons.person,
                                  size: 32, color: Colors.grey.shade400)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.pseudo ?? 'Utilisateur inconnu',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user.firstName != null)
                              Text(
                                user.firstName!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Partenaire depuis ${DateTime.now().difference(match.requestDate).inDays} jours',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (user.description != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  // Sports en commun
                  if (commonSportIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Sports en commun:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonSportIds.map((sportId) {
                        final sport = _sports.firstWhere(
                          (s) => s.id == sportId,
                          orElse: () =>
                              SportModel(id: sportId, name: 'Sport $sportId'),
                        );
                        return Chip(
                          label: Text(sport.name),
                          backgroundColor: Colors.blue.shade100,
                          labelStyle: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  // Actions buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to user profile
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fonctionnalité à venir'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person),
                          label: const Text('Profil'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startConversation(
                            user.id,
                            user.pseudo ?? 'Utilisateur',
                          ),
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }