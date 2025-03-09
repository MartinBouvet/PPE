import 'package:flutter/material.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';

class AddSportScreen extends StatefulWidget {
  const AddSportScreen({Key? key}) : super(key: key);

  @override
  _AddSportScreenState createState() => _AddSportScreenState();
}

class _AddSportScreenState extends State<AddSportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();

  String? _userId;
  List<SportModel> _allSports = [];
  SportModel? _selectedSport;
  final _clubNameController = TextEditingController();
  final _skillLevelController = TextEditingController();
  bool _lookingForPartners = false;
  bool _isLoading = true;
  bool _isSaving = false;

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
    });

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _userId = user.id;
        _allSports = await _userRepository.getAllSports();

        if (_allSports.isNotEmpty) {
          _selectedSport = _allSports.first;
        }
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

  Future<void> _saveSport() async {
    if (!_formKey.currentState!.validate() ||
        _userId == null ||
        _selectedSport == null)
      return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Vérifier si l'utilisateur a déjà ce sport
      final userSports = await _userRepository.getUserSports(_userId!);
      final alreadyHasSport = userSports.any(
        (s) => s.sportId == _selectedSport!.id,
      );

      if (alreadyHasSport) {
        throw Exception('Vous avez déjà ajouté ce sport à votre profil');
      }

      // Ajouter le sport à l'utilisateur
      await _supabase.from('sport_user').insert({
        'id_user': _userId,
        'id_sport': _selectedSport!.id,
        'club_name': _clubNameController.text.trim(),
        'skill_level': _skillLevelController.text.trim(),
        'looking_for_partners': _lookingForPartners,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sport ajouté avec succès')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisir un sport',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SportModel>(
                value: _selectedSport,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items:
                    _allSports.map((sport) {
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

              const SizedBox(height: 16),

              const Text(
                'Informations complémentaires',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _clubNameController,
                decoration: const InputDecoration(
                  labelText: 'Club (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _skillLevelController,
                decoration: const InputDecoration(
                  labelText: 'Niveau (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Débutant, Intermédiaire, Avancé',
                ),
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Je recherche des partenaires'),
                value: _lookingForPartners,
                onChanged: (value) {
                  setState(() {
                    _lookingForPartners = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
