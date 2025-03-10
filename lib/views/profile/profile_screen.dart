// lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/sport_user_model.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../services/image_service.dart';
import '../../utils/test_data_initializer.dart'; // Ajout de l'import ici
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
  final _imageService = ImageService();

  UserModel? _user;
  List<SportUserModel> _userSports = [];
  Map<int, SportModel> _sportsMap = {};
  bool _isLoading = true;
  bool _isUploadingImage = false;
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

  Future<void> _pickAndUploadImage() async {
    if (_user == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final imageFile = File(pickedFile.path);
      final photoUrl =
          await _imageService.uploadProfileImage(imageFile, _user!.id);

      if (photoUrl != null) {
        // Mettre à jour le profil avec la nouvelle photo
        await _userRepository.updateUserProfile(_user!.id, {'photo': photoUrl});

        // Recharger les données du profil
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erreur lors du téléchargement de l\'image: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _navigateToSportSelection() async {
    if (_user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SportSelectionScreen(userId: _user!.id),
      ),
    );

    if (result == true) {
      // Si des modifications ont été faites, recharger les données
      _loadUserData();
    }
  }

  // Nouvelle méthode pour initialiser les données de test
  Future<void> _initializeTestData() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initialisation des données de test...'),
              ],
            ),
          );
        },
      );

      // Initialiser toutes les données de test
      final result = await TestDataInitializer.initializeAllTestData();

      // Fermer la boîte de dialogue
      if (mounted) Navigator.pop(context);

      // Afficher un message de succès ou d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result
                ? 'Données de test initialisées avec succès'
                : 'Échec de l\'initialisation des données de test'),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fermer la boîte de dialogue en cas d'erreur
      if (mounted) Navigator.pop(context);

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                            Stack(
                              children: [
                                // Photo de profil
                                _isUploadingImage
                                    ? const CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey,
                                        child: CircularProgressIndicator(),
                                      )
                                    : GestureDetector(
                                        onTap: _pickAndUploadImage,
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            shape: BoxShape.circle,
                                            image: _user?.photo != null
                                                ? DecorationImage(
                                                    image:
                                                        CachedNetworkImageProvider(
                                                            _user!.photo!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: _user?.photo == null
                                              ? Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.blue.shade800,
                                                )
                                              : null,
                                        ),
                                      ),
                                // Bouton pour changer la photo
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: _pickAndUploadImage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '@${_user?.pseudo ?? "Sans pseudo"}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_user?.firstName != null)
                              Text(
                                _user?.firstName ?? '',
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
                      if (_user?.description != null &&
                          (_user?.description ?? '').isNotEmpty) ...[
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
                          child: Text(_user?.description ?? ''),
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

                      // Statistiques
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
                                  _buildStatItem(context, 'Sports',
                                      '${_userSports.length}'),
                                  _buildStatItem(context, 'Partenaires', '0'),
                                  _buildStatItem(context, 'Lieux visités', '0'),
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
                            // Ajout du bouton Admin ici
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.admin_panel_settings),
                              title:
                                  const Text('Initialiser les données de test'),
                              subtitle: const Text(
                                  'Ajoute des utilisateurs et des lieux fictifs'),
                              onTap: _initializeTestData,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),
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
