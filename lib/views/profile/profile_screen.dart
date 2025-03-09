// lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sport_user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();

  UserModel? _user;
  List<SportUserModel> _userSports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _user = await _authRepository.getCurrentUser();

      if (_user != null) {
        _userSports = await _userRepository.getUserSports(_user!.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vous n\'êtes pas connecté'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
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
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: _user!),
                ),
              );
              _loadUserData(); // Rafraîchir les données après modification
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
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
                          image:
                              _user!.photo != null
                                  ? DecorationImage(
                                    image: NetworkImage(_user!.photo!),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _user!.photo == null
                                ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blue.shade800,
                                )
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '@${_user!.pseudo}',
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
                if (_user!.description != null) ...[
                  const Text(
                    'À propos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_user!.description!),
                  const SizedBox(height: 24),
                ],

                // Sports
                const Text(
                  'Mes sports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _userSports.isEmpty
                    ? const Text('Aucun sport ajouté')
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _userSports.length,
                      itemBuilder: (context, index) {
                        final sportUser = _userSports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(sportUser.sportId.toString()),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sportUser.clubName != null)
                                  Text('Club: ${sportUser.clubName}'),
                                if (sportUser.skillLevel != null)
                                  Text('Niveau: ${sportUser.skillLevel}'),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sportUser.clubName != null)
                                  Text('Club: ${sportUser.clubName}'),
                                if (sportUser.skillLevel != null)
                                  Text('Niveau: ${sportUser.skillLevel}'),
                              ],
                            ),
                            trailing:
                                sportUser.lookingForPartners
                                    ? Chip(
                                      label: const Text('Recherche partenaire'),
                                      backgroundColor: Colors.green.shade100,
                                    )
                                    : null,
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Naviguer vers l'écran d'ajout de sport
          // TODO: Implémenter l'écran d'ajout de sport
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
