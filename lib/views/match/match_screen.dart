// lib/views/match/match_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import '../../models/match_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/match_repository.dart';
import '../chat/conversation_screen.dart';

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

  int? _selectedSportId;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

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

        // Set initial selected sport (first sport, or null if no sports)
        _selectedSportId = _sports.isNotEmpty ? _sports.first.id : null;

        // Load potential matches, pending requests, and accepted matches
        await Future.wait([
          _loadPotentialMatches(),
          _loadPendingRequests(),
          _loadAcceptedMatches(),
        ]);
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
    } catch (e) {
      debugPrint('Error loading potential matches: $e');
    }
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
    return _potentialMatches[_selectedSportId] ?? [];
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
    // Sport filter chips
    Widget sportsFilter = Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _sports.isEmpty
          ? const Center(child: Text('Aucun sport disponible'))
          : ListView(
              scrollDirection: Axis.horizontal,
              children: _sports.map((sport) {
                final isSelected = _selectedSportId == sport.id;
                final hasMatches = _potentialMatches.containsKey(sport.id) &&
                    _potentialMatches[sport.id]!.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(sport.name),
                    selected: isSelected,
                    onSelected: (_) => _selectSport(sport.id),
                    avatar: hasMatches ? const Icon(Icons.people) : null,
                    backgroundColor: hasMatches ? Colors.green.shade100 : null,
                  ),
                );
              }).toList(),
            ),
    );

    // Potential matches for the selected sport
    final potentialMatches = _getCurrentPotentialMatches();

    Widget matchesContent = potentialMatches.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _potentialMatches.isEmpty
                      ? 'Aucun partenaire potentiel trouvé'
                      : 'Aucun partenaire pour le sport sélectionné',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez de sélectionner un autre sport',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: potentialMatches.length,
            itemBuilder: (context, index) {
              final user = potentialMatches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User photo
                    user.photo != null
                        ? SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: CachedNetworkImage(
                              imageUrl: user.photo!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(Icons.person, size: 64),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.blue.shade100,
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),

                    // User info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.pseudo ?? 'Utilisateur inconnu',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_selectedSportId != null)
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
                                    _sports
                                        .firstWhere(
                                            (s) => s.id == _selectedSportId,
                                            orElse: () => SportModel(
                                                id: _selectedSportId!,
                                                name: 'Sport'))
                                        .name,
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (user.firstName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                user.firstName!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _sendMatchRequest(user.id),
                                icon: const Icon(Icons.thumb_up),
                                label: const Text('Proposer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Remove from list (skip)
                                  setState(() {
                                    _potentialMatches[_selectedSportId!]
                                        ?.remove(user);
                                  });
                                },
                                icon: const Icon(Icons.thumb_down),
                                label: const Text('Passer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );

    return Column(
      children: [
        sportsFilter,
        Expanded(child: matchesContent),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: requester.photo != null
                          ? CachedNetworkImageProvider(requester.photo!)
                          : null,
                      child: requester.photo == null
                          ? const Icon(Icons.person)
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
                          if (requester.firstName != null)
                            Text(
                              requester.firstName!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Veut être votre partenaire sportif',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _respondToMatchRequest(request.requesterId, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _respondToMatchRequest(request.requesterId, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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
            Text(
              'Proposez à des utilisateurs pour trouver vos partenaires de sport',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.explore),
              label: const Text('Découvrir'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _acceptedMatches.length,
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

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: user.photo != null
                          ? CachedNetworkImageProvider(user.photo!)
                          : null,
                      child:
                          user.photo == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.pseudo ?? 'Utilisateur inconnu',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.firstName != null)
                            Text(
                              user.firstName!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to user profile
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Fonctionnalité à venir')),
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
        );
      },
    );
  }
}
