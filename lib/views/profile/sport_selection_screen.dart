import 'package:flutter/material.dart';
import '../../models/sport_model.dart';
import '../../models/sport_user_model.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';

class SportSelectionScreen extends StatefulWidget {
  const SportSelectionScreen({Key? key}) : super(key: key);

  @override
  _SportSelectionScreenState createState() => _SportSelectionScreenState();
}

class _SportSelectionScreenState extends State<SportSelectionScreen> {
  final _sportRepository = SportRepository();
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();

  List<SportModel> _allSports = [];
  List<SportUserModel> _userSports = [];
  List<SportModel> _selectedSports = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  final Map<int, String> _skillLevels = {};
  final Map<int, bool> _lookingForPartners = {};

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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuel
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception("Utilisateur non connecté");
      }

      _userId = currentUser.id;

      // Charger tous les sports disponibles
      _allSports = await _sportRepository.getAllSports();

      // Charger les sports de l'utilisateur
      if (_userId != null) {
        _userSports = await _userRepository.getUserSports(_userId!);

        // Marquer les sports déjà sélectionnés
        for (var userSport in _userSports) {
          final sport = _allSports.firstWhere(
            (s) => s.id == userSport.sportId,
            orElse: () =>
                SportModel(id: userSport.sportId, name: 'Sport inconnu'),
          );

          _selectedSports.add(sport);
          _skillLevels[sport.id] = userSport.skillLevel ?? 'Débutant';
          _lookingForPartners[sport.id] = userSport.lookingForPartners;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserSports() async {
    if (_userId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Pour chaque sport sélectionné
      for (var sport in _selectedSports) {
        final skillLevel = _skillLevels[sport.id] ?? 'Débutant';
        final lookingForPartners = _lookingForPartners[sport.id] ?? false;

        // Ajouter ou mettre à jour le sport pour l'utilisateur
        await _sportRepository.addSportToUser(
          _userId!,
          sport.id,
          skillLevel: skillLevel,
          lookingForPartners: lookingForPartners,
        );
      }

      // Pour les sports qui étaient sélectionnés mais ne le sont plus, il faudrait les supprimer
      // Ceci est un exemple simple, vous pourriez vouloir implémenter une logique plus sophistiquée

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vos sports ont été enregistrés avec succès')),
      );

      Navigator.pop(context, true); // Retour avec résultat positif
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _toggleSportSelection(SportModel sport) {
    setState(() {
      if (_selectedSports.contains(sport)) {
        _selectedSports.remove(sport);
      } else {
        _selectedSports.add(sport);
        // Valeurs par défaut
        _skillLevels[sport.id] = 'Débutant';
        _lookingForPartners[sport.id] = false;
      }
    });
  }

  void _showSportConfigDialog(SportModel sport) {
    // Valeurs actuelles ou par défaut
    String currentLevel = _skillLevels[sport.id] ?? 'Débutant';
    bool isLookingForPartners = _lookingForPartners[sport.id] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text('Configuration pour ${sport.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre niveau:'),
              DropdownButton<String>(
                value: currentLevel,
                isExpanded: true,
                items: _availableLevels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    currentLevel = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Je recherche des partenaires'),
                value: isLookingForPartners,
                onChanged: (value) {
                  setState(() {
                    isLookingForPartners = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirmer'),
              onPressed: () {
                // Mettre à jour les valeurs
                this.setState(() {
                  _skillLevels[sport.id] = currentLevel;
                  _lookingForPartners[sport.id] = isLookingForPartners;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sélection des sports')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection des sports'),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveUserSports,
                  tooltip: 'Enregistrer',
                ),
        ],
      ),
      body: Column(
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisissez vos sports',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez les sports que vous pratiquez et configurez vos préférences',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Sports sélectionnés
          if (_selectedSports.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vos sports:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSports.map((sport) {
                      return InkWell(
                        onTap: () => _showSportConfigDialog(sport),
                        child: Chip(
                          label: Text(sport.name),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => _toggleSportSelection(sport),
                          avatar: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              sport.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const Divider(height: 32),

          // Liste des sports disponibles
          Expanded(
            child: ListView.builder(
              itemCount: _allSports.length,
              itemBuilder: (context, index) {
                final sport = _allSports[index];
                final isSelected = _selectedSports.contains(sport);

                return ListTile(
                  title: Text(sport.name),
                  subtitle: isSelected
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Niveau: ${_skillLevels[sport.id] ?? "Débutant"}'),
                            Text(_lookingForPartners[sport.id] == true
                                ? 'Recherche de partenaires: Oui'
                                : 'Recherche de partenaires: Non'),
                          ],
                        )
                      : Text(sport.description ?? 'Touchez pour ajouter'),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200,
                    child: Icon(
                      isSelected ? Icons.check : Icons.sports,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  trailing: isSelected
                      ? IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () => _showSportConfigDialog(sport),
                          tooltip: 'Configurer',
                        )
                      : null,
                  onTap: () => _toggleSportSelection(sport),
                  selected: isSelected,
                  selectedTileColor: Colors.blue.shade50,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
