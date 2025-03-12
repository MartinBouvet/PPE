// lib/views/profile/add_sport_screen.dart
import 'package:flutter/material.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';

class AddSportScreen extends StatefulWidget {
  const AddSportScreen({Key? key}) : super(key: key);

  @override
  _AddSportScreenState createState() => _AddSportScreenState();
}

class _AddSportScreenState extends State<AddSportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  final _sportRepository = SportRepository();

  String? _userId;
  List<SportModel> _allSports = [];
  SportModel? _selectedSport;
  final _clubNameController = TextEditingController();
  final _skillLevelController = TextEditingController();
  bool _lookingForPartners = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Liste des niveaux disponibles
  final List<String> _availableLevels = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    _skillLevelController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _userId = user.id;

        // Charger tous les sports disponibles
        _allSports = await _sportRepository.getAllSports();

        if (_allSports.isNotEmpty) {
          setState(() {
            _selectedSport = _allSports.first;
            _skillLevelController.text = 'Débutant'; // Niveau par défaut
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Vous devez être connecté pour ajouter un sport';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
      });
      debugPrint('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSport() async {
    if (!_formKey.currentState!.validate() ||
        _userId == null ||
        _selectedSport == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Vérifier si l'utilisateur a déjà ce sport
      final userSports = await _userRepository.getUserSports(_userId!);
      final alreadyHasSport =
          userSports.any((s) => s.sportId == _selectedSport!.id);

      if (alreadyHasSport) {
        setState(() {
          _errorMessage = 'Vous avez déjà ajouté ce sport à votre profil';
          _isSaving = false;
        });
        return;
      }

      // Ajouter le sport à l'utilisateur
      final success = await _sportRepository.addSportToUser(
        _userId!,
        _selectedSport!.id,
        clubName: _clubNameController.text.trim().isNotEmpty
            ? _clubNameController.text.trim()
            : null,
        skillLevel: _skillLevelController.text.trim(),
        lookingForPartners: _lookingForPartners,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sport ajouté avec succès')),
        );
        Navigator.pop(
            context, true); // Retourne true pour indiquer un changement
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Échec de l\'ajout du sport';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
      debugPrint('Erreur lors de l\'ajout du sport: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajouter un sport')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un sport'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveSport,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    const Text(
                      'Ajouter un nouveau sport',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez un sport et définissez vos informations',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sélection du sport
                    const Text(
                      'Sport',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SportModel>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(Icons.sports),
                      ),
                      value: _selectedSport,
                      items: _allSports.map((sport) {
                        return DropdownMenuItem<SportModel>(
                          value: sport,
                          child: Text(sport.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSport = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un sport';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Niveau
                    const Text(
                      'Niveau',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(Icons.trending_up),
                      ),
                      value: _skillLevelController.text.isNotEmpty
                          ? _skillLevelController.text
                          : 'Débutant',
                      items: _availableLevels.map((level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _skillLevelController.text = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un niveau';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Nom du club (optionnel)
                    const Text(
                      'Club (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _clubNameController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Club de Tennis Paris 15',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recherche de partenaires
                    SwitchListTile(
                      title: const Text(
                        'Je recherche des partenaires',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Activez cette option pour être visible des autres utilisateurs',
                      ),
                      value: _lookingForPartners,
                      onChanged: (value) {
                        setState(() {
                          _lookingForPartners = value;
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _lookingForPartners
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people,
                          color: _lookingForPartners
                              ? Colors.green.shade700
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton d'enregistrement
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSport,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Ajouter ce sport',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
