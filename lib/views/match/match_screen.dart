import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import '../../models/match_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/match_repository.dart';
import '../chat/conversation_screen.dart';

// Extension pour ajouter skillLevel à UserModel
extension UserModelExtension on UserModel {
  String? skillLevel;
}

class MatchScreen extends StatefulWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
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
  Map<int, SportModel> _sportsMap = {};

  int? _selectedSportId;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  int _currentCardIndex = 0;

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
    });

    try {
      // Get current user
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        // Get all sports
        _sports = await _sportRepository.getAllSports();

        // Create sport lookup map
        _sportsMap = {for (var sport in _sports) sport.id: sport};

        // Set initial selected sport
        if (_selectedSportId == null && _sports.isNotEmpty) {
          _selectedSportId = _sports.first.id;
        }

        // Load data
        await Future.wait([
          _loadPotentialMatches(),
          _loadPendingRequests(),
          _loadAcceptedMatches(),
        ]);
      } else {
        setState(() {
          _errorMessage = 'Vous devez être connecté pour accéder à cette fonctionnalité';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: ${e.toString()}';
      });
      debugPrint("ERREUR MATCH SCREEN: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPotentialMatches() async {
    if (_currentUser == null) return;

    try {
      _potentialMatches.clear();
      
      // Génère des utilisateurs démo pour tous les sports
      _generateDemoUsers();
    } catch (e) {
      debugPrint('Error loading potential matches: $e');
    }
  }

  void _generateDemoUsers() {
    // Génère un ensemble fixe d'utilisateurs avec des sports spécifiques
    final demoUsersByType = {
      1: [ // Basketball
        UserModel(
          id: 'demo1_basketball',
          pseudo: 'BasketPro',
          firstName: 'Nicolas',
          description: 'Basketteur depuis 8 ans, niveau avancé. Je cherche des joueurs pour des matchs 3v3 le weekend.',
          photo: 'https://images.pexels.com/photos/2269872/pexels-photo-2269872.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
        UserModel(
          id: 'demo2_basketball',
          pseudo: 'LanaHoops',
          firstName: 'Lana',
          description: 'Joueuse de basket en club, niveau intermédiaire. Disponible les soirs de semaine pour s\'entraîner.',
          photo: 'https://images.pexels.com/photos/1102341/pexels-photo-1102341.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      2: [ // Tennis
        UserModel(
          id: 'demo1_tennis',
          pseudo: 'TennisAce',
          firstName: 'Sophie',
          description: 'Joueuse de tennis depuis 10 ans, classée 15/4. Cherche partenaire niveau similaire pour matchs réguliers.',
          photo: 'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
        UserModel(
          id: 'demo2_tennis',
          pseudo: 'ServeKing',
          firstName: 'Thomas',
          description: 'Joueur de tennis du dimanche, niveau débutant+. Disponible le weekend pour progresser ensemble.',
          photo: 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      3: [ // Football
        UserModel(
          id: 'demo1_football',
          pseudo: 'FootballFan',
          firstName: 'Hugo',
          description: 'Joueur de foot amateur depuis 15 ans. Je cherche une équipe pour des matchs à 5 ou 7.',
          photo: 'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
        UserModel(
          id: 'demo2_football',
          pseudo: 'GoalKeeper',
          firstName: 'Laura',
          description: 'Gardienne de but en recherche d\'une équipe féminine ou mixte pour des matchs réguliers.',
          photo: 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      4: [ // Natation
        UserModel(
          id: 'demo1_natation',
          pseudo: 'SwimProdigy',
          firstName: 'Maxime',
          description: 'Nageur confirmé, spécialité crawl et papillon. Je cherche des partenaires pour s\'entraîner ensemble.',
          photo: 'https://images.pexels.com/photos/1121796/pexels-photo-1121796.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      5: [ // Volleyball
        UserModel(
          id: 'demo1_volleyball',
          pseudo: 'VolleyStrike',
          firstName: 'Emma',
          description: 'Joueuse de volleyball en club, niveau avancé. Recherche partenaires pour beach volley cet été.',
          photo: 'https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      6: [ // Fitness
        UserModel(
          id: 'demo1_fitness',
          pseudo: 'FitForLife',
          firstName: 'Julie',
          description: 'Coach fitness certifiée. Cherche partenaires pour séances de HIIT et musculation.',
          photo: 'https://images.pexels.com/photos/1894723/pexels-photo-1894723.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      7: [ // Escalade
        UserModel(
          id: 'demo1_escalade',
          pseudo: 'RockClimber',
          firstName: 'Alex',
          description: 'Grimpeur passionné, niveau 6b. Je cherche des partenaires pour grimper en salle et en falaise.',
          photo: 'https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      8: [ // Danse
        UserModel(
          id: 'demo1_danse',
          pseudo: 'DanceQueen',
          firstName: 'Chloe',
          description: 'Danseuse confirmée en salsa et bachata. Je cherche un partenaire pour pratiquer et progresser.',
          photo: 'https://images.pexels.com/photos/1462637/pexels-photo-1462637.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
      9: [ // Course à pied
        UserModel(
          id: 'demo1_running',
          pseudo: 'RunnerPro',
          firstName: 'Paul',
          description: 'Coureur semi-marathon en 1h45. Je cherche des partenaires pour des sorties longues le weekend.',
          photo: 'https://images.pexels.com/photos/1250426/pexels-photo-1250426.jpeg?auto=compress&cs=tinysrgb&w=800',
        ),
      ],
    };

    // Assigne les niveaux de compétence à chaque utilisateur par sport
    final sportLevels = {
      'demo1_basketball': 'Avancé',
      'demo2_basketball': 'Intermédiaire',
      'demo1_tennis': 'Expert',
      'demo2_tennis': 'Débutant+',
      'demo1_football': 'Intermédiaire',
      'demo2_football': 'Intermédiaire',
      'demo1_natation': 'Avancé',
      'demo1_volleyball': 'Avancé',
      'demo1_fitness': 'Expert',
      'demo1_escalade': 'Intermédiaire',
      'demo1_danse': 'Avancé',
      'demo1_running': 'Avancé',
    };

    // Pour chaque sport, ajoute les utilisateurs à _potentialMatches
    demoUsersByType.forEach((sportId, users) {
      _potentialMatches[sportId] = users;
      
      // Ajoute les utilisateurs à _usersMap avec leurs niveaux
      for (var user in users) {
        user.skillLevel = sportLevels[user.id] ?? 'Intermédiaire';
        _usersMap[user.id] = user;
      }
    });

    // Ajoute des utilisateurs génériques pour les sports sans utilisateurs spécifiques
    for (var sport in _sports) {
      if (!_potentialMatches.containsKey(sport.id)) {
        final genericUser = UserModel(
          id: 'generic_${sport.id}',
          pseudo: 'Sportif${sport.id}',
          firstName: 'Utilisateur',
          description: 'Passionné(e) de ${sport.name}. Je cherche des partenaires pour pratiquer régulièrement.',
          photo: 'https://images.pexels.com/photos/1251171/pexels-photo-1251171.jpeg?auto=compress&cs=tinysrgb&w=800',
          skillLevel: 'Intermédiaire',
        );
        
        _potentialMatches[sport.id] = [genericUser];
        _usersMap[genericUser.id] = genericUser;
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    if (_currentUser == null) return;

    try {
      _pendingRequests = await _matchRepository.getPendingMatchRequests(_currentUser!.id);

      for (final request in _pendingRequests) {
        if (!_usersMap.containsKey(request.requesterId)) {
          final user = await _userRepository.getUserProfile(request.requesterId);
          if (user != null) {
            _usersMap[request.requesterId] = user;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }
  }

  Future<void> _loadAcceptedMatches() async {
    if (_currentUser == null) return;

    try {
      _acceptedMatches = await _matchRepository.getAcceptedMatches(_currentUser!.id);

      for (final match in _acceptedMatches) {
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
    } catch (e) {
      debugPrint('Error loading accepted matches: $e');
    }
  }

  Future<void> _sendMatchRequest(String userId) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // For demo users, simulate success
      if (userId.startsWith('demo')) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de partenariat envoyée !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Move to next card
        _moveToNextCard();
      } else {
        final success = await _matchRepository.createMatchRequest(
          _currentUser!.id,
          userId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande de partenariat envoyée')),
          );
          
          // Move to next card if successful
          _moveToNextCard();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'envoi de la demande')),
          );
        }
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
                : 'Demande de partenariat refusée'),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
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

  void _moveToNextCard() {
    if (_selectedSportId == null) return;
    
    final matches = _potentialMatches[_selectedSportId] ?? [];
    
    if (matches.isNotEmpty && _currentCardIndex < matches.length - 1) {
      setState(() {
        _currentCardIndex++;
      });
    } else {
      // We've gone through all cards
      setState(() {
        _currentCardIndex = 0;
        // Optionally regenerate new matches
        if (_selectedSportId != null) {
          _generateDemoUsers(_selectedSportId!);
        }
      });
    }
  }

  Future<void> _startConversation(String userId, String pseudo) async {
    if (_currentUser == null) return;

    try {
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
      _currentCardIndex = 0; // Reset card index when changing sport
    });
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
              text: 'Matches',
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

    final matches = _potentialMatches[_selectedSportId] ?? [];

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun partenaire trouvé pour ${_sportsMap[_selectedSportId]?.name ?? "ce sport"}',
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    final currentUser = matches.isNotEmpty && _currentCardIndex < matches.length 
        ? matches[_currentCardIndex] 
        : null;

    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_satisfied_alt, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Plus de profils disponibles pour le moment !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentCardIndex = 0;
                });
              },
              child: const Text('Voir plus de profils'),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _SwipeableCard(
          key: ValueKey('${currentUser.id}_${_selectedSportId}'),
          user: currentUser,
          sport: _sportsMap[_selectedSportId]!,
          onLike: () => _sendMatchRequest(currentUser.id),
          onSkip: _moveToNextCard,
        ),
        Positioned(
          bottom: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Skip button
              Material(
                elevation: 5,
                shape: const CircleBorder(),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 32, color: Colors.red),
                    onPressed: _moveToNextCard,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Like button
              Material(
                elevation: 5,
                shape: const CircleBorder(),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.favorite, size: 32, color: Colors.green),
                    onPressed: () => _sendMatchRequest(currentUser.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune demande de partenariat en attente',
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
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final requester = _usersMap[request.requesterId];

        if (requester == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: requester.photo != null
                          ? CachedNetworkImageProvider(requester.photo!)
                          : null,
                      child: requester.photo == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            requester.pseudo ?? 'Utilisateur inconnu',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Souhaite être votre partenaire sportif',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                        onPressed: () => _respondToMatchRequest(requester.id, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Accepter'),
                        onPressed: () => _respondToMatchRequest(requester.id, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        final otherUserId = match.requesterId == _currentUser!.id
            ? match.likedUserId
            : match.requesterId;
        final user = _usersMap[otherUserId];

        if (user == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _startConversation(user.id, user.pseudo ?? 'Utilisateur'),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // User photo with sport badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: user.photo != null
                            ? CachedNetworkImage(
                                imageUrl: user.photo!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                      ),
                    ),
                    // Gradient overlay for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Match date badge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Match depuis ${DateTime.now().difference(match.requestDate).inDays} jours',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    // User name overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Text(
                        user.pseudo ?? user.firstName ?? 'Partenaire',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // User info and action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User description
                      if (user.description != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            user.description!,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Show profile
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fonctionnalité à venir')),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
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
    );
  }
}

class _SwipeableCard extends StatefulWidget {
  final UserModel user;
  final SportModel sport;
  final VoidCallback onLike;
  final VoidCallback onSkip;

  const _SwipeableCard({
    Key? key,
    required this.user,
    required this.sport,
    required this.onLike,
    required this.onSkip,
  }) : super(key: key);

  @override
  _SwipeableCardState createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _dragPosition = Offset.zero;
  double _angle = 0;
  bool _isDragging = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    final delta = details.delta;
    setState(() {
      _dragPosition += delta;
      // Calculate angle based on horizontal drag
      _angle = (_dragPosition.dx / 200) * 0.2; // max ~11.5 degrees
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine if swipe is decisive enough
    if (_dragPosition.dx.abs() > screenWidth * 0.4) {
      _animateExit(_dragPosition.dx > 0);
    } else {
      _resetPosition();
    }
    
    setState(() {
      _isDragging = false;
    });
  }

  void _resetPosition() {
    setState(() {
      _isExiting = false;
    });
    
    final resetTween = Tween<Offset>(
      begin: _dragPosition,
      end: Offset.zero,
    );
    
    final angleTween = Tween<double>(
      begin: _angle,
      end: 0.0,
    );
    
    Animation<Offset> posAnimation = resetTween.animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
    
    Animation<double> angleAnimation = angleTween.animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
    
    posAnimation.addListener(() {
      setState(() {
        _dragPosition = posAnimation.value;
        _angle = angleAnimation.value;
      });
    });
    
    _animationController.reset();
    _animationController.forward();
  }

  void _animateExit(bool isLike) {
    setState(() {
      _isExiting = true;
    });
    
    final screenWidth = MediaQuery.of(context).size.width;
    final endPos = Offset(isLike ? screenWidth * 1.5 : -screenWidth * 1.5, 0);
    
    final exitTween = Tween<Offset>(
      begin: _dragPosition,
      end: endPos,
    );
    
    Animation<Offset> exitAnimation = exitTween.animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
    
    exitAnimation.addListener(() {
      setState(() {
        _dragPosition = exitAnimation.value;
      });
    });
    
    _animationController.reset();
    _animationController.forward().then((_) {
      if (isLike) {
        widget.onLike();
      } else {
        widget.onSkip();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate swipe percentage for overlay opacity
    final swipePercentage = math.min((_dragPosition.dx.abs() / (screenSize.width * 0.5)), 1.0);
    
    // Color overlay based on swipe direction
    final overlayColor = _dragPosition.dx > 0
        ? Colors.green.withOpacity(0.3 * swipePercentage) // Like - Green
        : Colors.red.withOpacity(0.3 * swipePercentage);  // Skip - Red
    
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragPosition,
        child: Transform.rotate(
          angle: _angle,
          child: Container(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Card content
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User photo
                        Expanded(
                          flex: 3,
                          child: widget.user.photo != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.user.photo!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 100,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Image non disponible',
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 100,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Pas de photo',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        
                        // User info
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.user.firstName ?? '',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '@${widget.user.pseudo ?? ""}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.sport.name,
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // User description
                                if (widget.user.description != null)
                                  Expanded(
                                    child: Text(
                                      widget.user.description!,
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 4,
                                    ),
                                  ),
                                
                                // Boutons d'action
                                if (!_isDragging && _dragPosition == Offset.zero)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_back, color: Colors.red.shade600, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Passer',
                                              style: TextStyle(color: Colors.red.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Proposer',
                                              style: TextStyle(color: Colors.green.shade600),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.arrow_forward, color: Colors.green.shade600, size: 16),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Color overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: overlayColor,
                  ),
                ),
                
                // Like/Skip indicators
                if (_dragPosition.dx.abs() > 20)
                  Positioned(
                    top: 20,
                    right: _dragPosition.dx < 0 ? 20 : null,
                    left: _dragPosition.dx > 0 ? 20 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _dragPosition.dx > 0 ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        _dragPosition.dx > 0 ? "MATCH !" : "PASSER",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}