// lib/views/profile/sport_selection_screen.dart
import 'package:flutter/material.dart';
import '../../models/sport_model.dart';
import '../../models/sport_user_model.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/user_repository.dart';
import '../../config/supabase_config.dart'; // Ajout de l'import

class SportSelectionScreen extends StatefulWidget {
  final String userId;

  const SportSelectionScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _SportSelectionScreenState createState() => _SportSelectionScreenState();
}

class _SportSelectionScreenState extends State<SportSelectionScreen> {
  final _sportRepository = SportRepository();
  final _userRepository = UserRepository();
  final _supabase = SupabaseConfig.client;
  List<SportUserModel> _userSports = [];
  List<SportModel> _selectedSports = [];
  List<SportModel> _allSports = []; // Ajoutez cette ligne
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      // Charger tous les sports disponibles
      _allSports = await _sportRepository.getAllSports();
      debugPrint('Sports chargés: ${_allSports.length}');

      // Charger les sports de l'utilisateur
      _userSports = await _userRepository.getUserSports(widget.userId);
      debugPrint('Sports de l\'utilisateur chargés: ${_userSports.length}');

      // Initialiser les sports déjà sélectionnés
      final selectedSports = <SportModel>[];
      for (var userSport in _userSports) {
        final sport = _allSports.firstWhere(
          (s) => s.id == userSport.sportId,
          orElse: () => SportModel(
              id: userSport.sportId, name: 'Sport #${userSport.sportId}'),
        );

        selectedSports.add(sport);
        _skillLevels[sport.id] = userSport.skillLevel ?? 'Débutant';
        _lookingForPartners[sport.id] = userSport.lookingForPartners;
      }

      setState(() {
        _selectedSports = selectedSports;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Dans SportSelectionScreen - méthode _saveUserSports
  Future<void> _saveUserSports() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Sauvegarde des sports pour l\'utilisateur ${widget.userId}');

      // Liste des sports actuels de l'utilisateur
      final currentSportIds = _userSports.map((s) => s.sportId).toSet();

      // Liste des sports sélectionnés
      final selectedSportIds = _selectedSports.map((s) => s.id).toSet();

      debugPrint('Sports actuels: $currentSportIds');
      debugPrint('Sports sélectionnés: $selectedSportIds');

      bool success = true;

      // Sports à ajouter
      for (var sport in _selectedSports) {
        final sportId = sport.id;
        final skillLevel = _skillLevels[sportId] ?? 'Débutant';
        final lookingForPartners = _lookingForPartners[sportId] ?? false;

        // Utiliser upsert pour ajouter ou mettre à jour
        try {
          await _supabase.from('sport_user').upsert({
            'id_user': widget.userId,
            'id_sport': sportId,
            'club_name': '', // Valeur vide par défaut
            'skill_level': skillLevel,
            'looking_for_partners': lookingForPartners,
          }, onConflict: 'id_user,id_sport');

          debugPrint('Sport $sportId ajouté/mis à jour avec succès');
        } catch (e) {
          debugPrint(
              'Erreur lors de l\'ajout/mise à jour du sport $sportId: $e');
          success = false;
        }
      }

      // Sports à supprimer (ceux qui étaient présents mais ne sont plus sélectionnés)
      for (var sportUser in _userSports) {
        if (!selectedSportIds.contains(sportUser.sportId)) {
          try {
            await _supabase
                .from('sport_user')
                .delete()
                .eq('id_user', widget.userId)
                .eq('id_sport', sportUser.sportId);

            debugPrint('Sport ${sportUser.sportId} supprimé avec succès');
          } catch (e) {
            debugPrint(
                'Erreur lors de la suppression du sport ${sportUser.sportId}: $e');
            success = false;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success
                  ? 'Sports enregistrés avec succès'
                  : 'Certaines opérations ont échoué')),
        );
        Navigator.pop(
            context, true); // Retourner true pour indiquer des changements
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement: $e');
      setState(() {
        _errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _removeSportFromUser(int sportId) async {
    try {
      await _sportRepository.removeSportFromUser(widget.userId, sportId);
    } catch (e) {
      throw Exception(
          'Erreur lors de la suppression du sport: ${e.toString()}');
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes sports')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes sports'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveUserSports,
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
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
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
          : Column(
              children: [
                // En-tête avec instructions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sélectionnez vos sports',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez les sports que vous pratiquez et personnalisez vos préférences pour chacun.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Sports sélectionnés
                if (_selectedSports.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sports sélectionnés:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_selectedSports.length} sport(s)',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
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
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _toggleSportSelection(sport),
                                backgroundColor:
                                    _lookingForPartners[sport.id] == true
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                labelStyle: TextStyle(
                                  color: _lookingForPartners[sport.id] == true
                                      ? Colors.green.shade800
                                      : Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Icons.sports,
                                    size: 16,
                                    color: _lookingForPartners[sport.id] == true
                                        ? Colors.green.shade800
                                        : Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

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
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
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
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveUserSports,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Enregistrer mes sports'),
          ),
        ),
      ),
    );
  }
}
