// lib/views/social/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/friend_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final _authRepository = AuthRepository();
  final _friendRepository = FriendRepository();

  late TabController _tabController;
  UserModel? _currentUser;
  List<UserModel> _friends = [];
  List<UserModel> _requests = [];
  List<UserModel> _suggestedFriends = [];

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _searchQuery = '';

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
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        await Future.wait([
          _loadFriends(),
          _loadFriendRequests(),
          _loadSuggestedFriends(),
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

  Future<void> _loadFriends() async {
    if (_currentUser == null) return;

    try {
      _friends = await _friendRepository.getUserFriends(_currentUser!.id);
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
  }

  Future<void> _loadFriendRequests() async {
    if (_currentUser == null) return;

    try {
      _requests = await _friendRepository.getFriendRequests(_currentUser!.id);
    } catch (e) {
      debugPrint('Error loading friend requests: $e');
    }
  }

  Future<void> _loadSuggestedFriends() async {
    if (_currentUser == null) return;

    try {
      // In a real app, you would implement a repository method to get friend suggestions
      // For now, we'll create some mock data
      _suggestedFriends = [
        UserModel(
          id: 'user1',
          pseudo: 'TennisFan92',
          firstName: 'Marie',
          photo: 'https://randomuser.me/api/portraits/women/92.jpg',
        ),
        UserModel(
          id: 'user2',
          pseudo: 'JoggingLover',
          firstName: 'Thomas',
          photo: 'https://randomuser.me/api/portraits/men/45.jpg',
        ),
        UserModel(
          id: 'user3',
          pseudo: 'BasketballPro',
          firstName: 'Sophie',
          photo: 'https://randomuser.me/api/portraits/women/22.jpg',
        ),
        UserModel(
          id: 'user4',
          pseudo: 'FootballKing',
          firstName: 'Lucas',
          photo: 'https://randomuser.me/api/portraits/men/32.jpg',
        ),
      ];
    } catch (e) {
      debugPrint('Error loading suggested friends: $e');
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _friendRepository.sendFriendRequest(
        _currentUser!.id,
        userId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami envoyée')),
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

  Future<void> _acceptFriendRequest(String senderId) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _friendRepository.acceptFriendRequest(
        senderId,
        _currentUser!.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami acceptée')),
        );

        // Refresh data
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Échec de l\'acceptation de la demande')),
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

  Future<void> _rejectFriendRequest(String senderId) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _friendRepository.rejectFriendRequest(
        senderId,
        _currentUser!.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami refusée')),
        );

        // Refresh data
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du refus de la demande')),
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

  Future<void> _removeFriend(String friendId) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _friendRepository.removeFriend(
        _currentUser!.id,
        friendId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ami supprimé')),
        );

        // Refresh data
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression de l\'ami')),
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

  List<UserModel> _getFilteredFriends() {
    if (_searchQuery.isEmpty) return _friends;

    return _friends.where((friend) {
      final query = _searchQuery.toLowerCase();
      return (friend.pseudo?.toLowerCase().contains(query) ?? false) ||
          (friend.firstName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<UserModel> _getFilteredRequests() {
    if (_searchQuery.isEmpty) return _requests;

    return _requests.where((user) {
      final query = _searchQuery.toLowerCase();
      return (user.pseudo?.toLowerCase().contains(query) ?? false) ||
          (user.firstName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<UserModel> _getFilteredSuggestions() {
    if (_searchQuery.isEmpty) return _suggestedFriends;

    return _suggestedFriends.where((user) {
      final query = _searchQuery.toLowerCase();
      return (user.pseudo?.toLowerCase().contains(query) ?? false) ||
          (user.firstName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Amis')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Amis')),
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
        title: const Text('Amis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Mes amis',
              icon: Badge(
                isLabelVisible: _friends.isNotEmpty,
                label: Text(_friends.length.toString()),
                child: const Icon(Icons.people),
              ),
            ),
            Tab(
              text: 'Demandes',
              icon: Badge(
                isLabelVisible: _requests.isNotEmpty,
                label: Text(_requests.length.toString()),
                child: const Icon(Icons.person_add),
              ),
            ),
            const Tab(
              text: 'Suggestions',
              icon: Icon(Icons.person_search),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.zero,
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
                // Friends tab
                _buildFriendsTab(),

                // Requests tab
                _buildRequestsTab(),

                // Suggestions tab
                _buildSuggestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    final filteredFriends = _getFilteredFriends();

    if (filteredFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _friends.isEmpty
                  ? 'Vous n\'avez pas encore d\'amis'
                  : 'Aucun ami ne correspond à votre recherche',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            if (_friends.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(2); // Go to suggestions tab
                },
                icon: const Icon(Icons.person_search),
                label: const Text('Trouver des amis'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = filteredFriends[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: friend.photo != null
                ? CachedNetworkImageProvider(friend.photo!)
                : null,
            child: friend.photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(friend.pseudo ?? 'Utilisateur inconnu'),
          subtitle: Text(friend.firstName ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.message),
                        title: const Text('Envoyer un message'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Navigate to conversation screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Fonctionnalité à venir')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.sports),
                        title: const Text('Voir les sports en commun'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Show sports in common
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Fonctionnalité à venir')),
                          );
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.person_remove, color: Colors.red),
                        title: const Text(
                          'Supprimer de mes amis',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer cet ami'),
                              content: Text(
                                  'Êtes-vous sûr de vouloir supprimer ${friend.pseudo} de vos amis ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _removeFriend(friend.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          onTap: () {
            // TODO: Navigate to friend profile
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonctionnalité à venir')),
            );
          },
        );
      },
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
              _requests.isEmpty
                  ? 'Aucune demande d\'ami en attente'
                  : 'Aucune demande ne correspond à votre recherche',
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
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: request.photo != null
                ? CachedNetworkImageProvider(request.photo!)
                : null,
            child: request.photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(request.pseudo ?? 'Utilisateur inconnu'),
          subtitle: const Text('Veut vous ajouter comme ami'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _rejectFriendRequest(request.id),
                tooltip: 'Refuser',
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _acceptFriendRequest(request.id),
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

  Widget _buildSuggestionsTab() {
    final filteredSuggestions = _getFilteredSuggestions();

    if (filteredSuggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _suggestedFriends.isEmpty
                  ? 'Aucune suggestion d\'ami disponible'
                  : 'Aucune suggestion ne correspond à votre recherche',
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
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: suggestion.photo != null
                ? CachedNetworkImageProvider(suggestion.photo!)
                : null,
            child: suggestion.photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(suggestion.pseudo ?? 'Utilisateur inconnu'),
          subtitle: Text(suggestion.firstName ?? ''),
          trailing: ElevatedButton(
            onPressed: () => _sendFriendRequest(suggestion.id),
            child: const Text('Ajouter'),
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
}
