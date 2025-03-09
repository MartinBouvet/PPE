import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../models/sport_user_model.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import 'edit_profile_screen.dart';
import 'sport_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  final _sportRepository = SportRepository();

  UserModel? _user;
  List<SportUserModel> _userSports = [];
  Map<int, SportModel> _sportsMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _user = await _authRepository.getCurrentUser();

      if (_user != null) {
        // Charger les sports de l'utilisateur
        _userSports = await _userRepository.getUserSports(_user!.id);

        // Charger les détails des sports
        for (var sportUser in _userSports) {
          final sport = await _sportRepository.getSportById(sportUser.sportId);
          if (sport != null) {
            setState(() {
              _sportsMap[sport.id] = sport;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du profil: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authRepository.signOut();

      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _navigateToSportSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SportSelectionScreen(),
      ),
    );

    if (result == true) {
      // Si des modifications ont été faites, recharger les données
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vous n\'êtes pas connecté'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.go('/login');
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
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: _user!),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadUserData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête du profil avec photo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                                image: _user!.photo != null
                                    ? DecorationImage(
                                        image: NetworkImage(_user!.photo!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _user!.photo == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.blue.shade800,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '@${_user!.pseudo ?? "Sans pseudo"}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_user!.firstName != null)
                              Text(
                                _user!.firstName!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      if (_user!.description != null &&
                          _user!.description!.isNotEmpty) ...[
                        const Text(
                          'À propos',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_user!.description!),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Sports
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mes sports',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _navigateToSportSelection,
                            icon: const Icon(Icons.add),
                            label: const Text('Gérer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _userSports.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.sports,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Aucun sport ajouté',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _navigateToSportSelection,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Ajouter un sport'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _userSports.length,
                              itemBuilder: (context, index) {
                                final sportUser = _userSports[index];
                                final sport = _sportsMap[sportUser.sportId];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.2),
                                                  child: Icon(
                                                    Icons.sports,
                                                    size: 18,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  sport?.name ??
                                                      'Sport #${sportUser.sportId}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (sportUser.lookingForPartners)
                                              Chip(
                                                label: const Text(
                                                    'Recherche partenaire'),
                                                backgroundColor:
                                                    Colors.green.shade100,
                                                labelStyle: TextStyle(
                                                  color: Colors.green.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (sportUser.clubName != null &&
                                            sportUser.clubName!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.business,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Text(
                                                    'Club: ${sportUser.clubName}'),
                                              ],
                                            ),
                                          ),
                                        if (sportUser.skillLevel != null &&
                                            sportUser.skillLevel!.isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.trending_up,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                  'Niveau: ${sportUser.skillLevel}'),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      const SizedBox(height: 32),

                      // Autres sections (statistiques, matchs, etc.)
                      const Text(
                        'Statistiques',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(context, 'Matchs', '5'),
                                  _buildStatItem(context, 'Partenaires', '3'),
                                  _buildStatItem(context, 'Réservations', '2'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section paramètres
                      const Text(
                        'Paramètres',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.notifications),
                              title: const Text('Notifications'),
                              trailing: Switch(
                                value: true,
                                onChanged: (value) {},
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: const Text('Langue'),
                              trailing: const Text('Français'),
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.privacy_tip),
                              title: const Text('Confidentialité'),
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.help_outline),
                              title: const Text('Aide et support'),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 60), // Espace en bas pour le scroll
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSportSelection,
        child: const Icon(Icons.sports),
        tooltip: 'Gérer mes sports',
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
