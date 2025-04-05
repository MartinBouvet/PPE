import 'package:flutter/material.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/sport_user_repository.dart';

class SportSelectionScreen extends StatefulWidget {
  const SportSelectionScreen({Key? key}) : super(key: key);

  @override
  _SportSelectionScreenState createState() => _SportSelectionScreenState();
}

class _SportSelectionScreenState extends State<SportSelectionScreen> {
  final _authRepository = AuthRepository();
  final _sportUserRepository = SportUserRepository();

  String? _userId;
  List<SportModel> _allSports = [];
  List<SportModel> _selectedSports = [];
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
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _userId = user.id;

        _allSports = await _sportUserRepository.getAllSports();

        setState(() {
          _selectedSports = _allSports
              .where((sport) => sport.id == 11 || sport.id == 9)
              .toList();

          for (var sport in _selectedSports) {
            if (sport.id == 11) {
              _skillLevels[sport.id] = 'Intermédiaire';
              _lookingForPartners[sport.id] = true;
            } else if (sport.id == 9) {
              _skillLevels[sport.id] = 'Avancé';
              _lookingForPartners[sport.id] = true;
            }
          }
        });
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
      debugPrint('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserSports() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sports enregistrés avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
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
        _skillLevels.remove(sport.id);
        _lookingForPartners.remove(sport.id);
      } else {
        _selectedSports.add(sport);
        _skillLevels[sport.id] = 'Débutant';
        _lookingForPartners[sport.id] = false;
      }
    });
  }

  void _showSportConfigDialog(SportModel sport) {
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

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes sports')),
        body: Center(
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
        ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionnez vos sports',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez les sports que vous pratiquez et personnalisez vos préférences pour chacun.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (_selectedSports.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                          backgroundColor: _lookingForPartners[sport.id] == true
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
                            child: Text(
                              sport.name[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _lookingForPartners[sport.id] == true
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
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
                    child: Text(
                      sport.name[0],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
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
