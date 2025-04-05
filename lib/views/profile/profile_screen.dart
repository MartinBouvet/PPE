import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/user_model.dart';
import '../../models/sport_user_model.dart';
import '../../models/sport_model.dart';
import '../../models/badge_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_user_repository.dart';
import '../../repositories/badge_repository.dart';
import '../../services/image_service.dart';
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
  final _sportUserRepository = SportUserRepository();
  final _badgeRepository = BadgeRepository();
  final _imageService = ImageService();

  UserModel? _user;
  List<SportUserModel> _userSports = [];
  List<BadgeModel> _userBadges = [];
  Map<int, SportModel> _sportsMap = {};
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        setState(() {
          _user = user;
        });

        final allSports = await _sportUserRepository.getAllSports();
        final Map<int, SportModel> sportsMap = {};
        for (var sport in allSports) {
          sportsMap[sport.id] = sport;
        }
        setState(() {
          _sportsMap = sportsMap;
        });

        final userSports = await _sportUserRepository.getUserSports(user.id);
        setState(() {
          _userSports = userSports;
        });

        final userBadges = await _badgeRepository.getUserBadges(user.id);
        setState(() {
          _userBadges = userBadges;
        });
      } else {
        debugPrint('Aucun utilisateur connecté trouvé');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement du profil: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        await _userRepository.updateUserProfile(_user!.id, {'photo': photoUrl});

        setState(() {
          _user = _user!..photo = photoUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  String _getGenderText(String genderCode) {
    switch (genderCode) {
      case 'M':
        return 'Homme';
      case 'F':
        return 'Femme';
      case 'O':
        return 'Autre';
      case 'U':
        return 'Non précisé';
      default:
        return 'Non précisé';
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
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 215,
                    pinned: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Modifier le profil',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfileScreen(user: _user!),
                            ),
                          );
                          if (result == true) {
                            _loadUserData();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Déconnexion',
                        onPressed: _logout,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('@${_user?.pseudo ?? "Sans pseudo"}'),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _pickAndUploadImage,
                                    child: Stack(
                                      children: [
                                        _isUploadingImage
                                            ? const CircleAvatar(
                                                radius: 60,
                                                backgroundColor: Colors.white54,
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : CircleAvatar(
                                                radius: 60,
                                                backgroundColor: Colors.white,
                                                backgroundImage: _user?.photo !=
                                                        null
                                                    ? CachedNetworkImageProvider(
                                                            _user!.photo!)
                                                        as ImageProvider
                                                    : null,
                                                child: _user?.photo == null
                                                    ? const Icon(Icons.person,
                                                        size: 60,
                                                        color: Colors.blue)
                                                    : null,
                                              ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      if (_user?.description != null &&
                          (_user?.description ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(_user?.description ?? ''),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Text(
                                    'Ajoutez une description pour vous présenter...'),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistiques',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                    context,
                                    Icons.sports_tennis,
                                    '${_userSports.length}',
                                    'Sports',
                                    Colors.blue.shade200,
                                  ),
                                  _buildStatCard(
                                    context,
                                    Icons.people,
                                    '12',
                                    'Partenaires',
                                    Colors.green.shade200,
                                  ),
                                  _buildStatCard(
                                    context,
                                    Icons.emoji_events,
                                    '${_userBadges.length}',
                                    'Badges',
                                    Colors.orange.shade200,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mes sports',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SportSelectionScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _loadUserData();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _userSports.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.sports,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Vous n\'avez pas encore ajouté de sports',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ajoutez des sports pour trouver des partenaires',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _userSports.length,
                              itemBuilder: (context, index) {
                                final sportUser = _userSports[index];
                                final sport = _sportsMap[sportUser.sportId];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              (sport?.name ?? 'S')[0],
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      sport?.name ??
                                                          'Sport #${sportUser.sportId}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (sportUser
                                                        .lookingForPartners) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .green.shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          'Recherche',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .green.shade800,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                if (sportUser.skillLevel !=
                                                    null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Niveau : ${sportUser.skillLevel}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                                if (sportUser.clubName !=
                                                        null &&
                                                    sportUser.clubName!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Club : ${sportUser.clubName}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          color: Colors.red,
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Supprimer le sport'),
                                                content: Text(
                                                    'Êtes-vous sûr de vouloir supprimer ${sport?.name ?? "ce sport"} de votre profil?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child:
                                                        const Text('Annuler'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _loadUserData();
                                                    },
                                                    child: const Text(
                                                      'Supprimer',
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mes badges',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _userBadges.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.emoji_events,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun badge obtenu pour le moment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Continuez à pratiquer vos sports pour gagner des badges !',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _userBadges.length,
                              itemBuilder: (context, index) {
                                final badge = _userBadges[index];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: badge.logo != null
                                              ? Image.network(
                                                  badge.logo!,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Icon(
                                                        Icons.emoji_events,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        size: 50);
                                                  },
                                                )
                                              : Icon(Icons.emoji_events,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  size: 50),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                badge.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                badge.description,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Obtenu le ${DateFormat('dd/MM/yyyy').format(badge.dateObtained)}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations personnelles',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.blue.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_user?.firstName ?? "Non défini"}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Prénom',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.cake,
                                          color: Colors.orange.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _user?.birthDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_user!.birthDate!)
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Naissance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.calendar_today,
                                          color: Colors.green.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _user?.inscriptionDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_user!.inscriptionDate!)
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Inscription',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_user?.gender != null &&
                                      _user!.gender!.isNotEmpty)
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.wc,
                                            color: Colors.purple.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _getGenderText(_user!.gender!),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Genre',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Paramètres',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                        Icons.notifications_outlined),
                                    title: const Text('Notifications'),
                                    trailing: Switch(
                                      value: true,
                                      onChanged: (value) {},
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.language_outlined),
                                    title: const Text('Langue'),
                                    trailing: const Text('Français'),
                                    onTap: () {},
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.privacy_tip_outlined),
                                    title: const Text('Confidentialité'),
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'AKOS v1.0',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
