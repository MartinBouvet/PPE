// lib/views/match/match_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/match_repository.dart';
import '../../widgets/match/match_card.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  final _sportRepository = SportRepository();
  final _matchRepository = MatchRepository();

  UserModel? _currentUser;
  List<SportModel> _sports = [];
  SportModel? _selectedSport;
  List<UserModel> _potentialMatches = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

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
      // Récupérer l'utilisateur actuel
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        // Récupérer tous les sports
        _sports = await _sportRepository.getAllSports();

        if (_sports.isNotEmpty) {
          _selectedSport = _sports.first;
          await _loadPotentialMatches();
        }
      }
    } catch (e) {
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

  Future<void> _loadPotentialMatches() async {
    if (_currentUser == null || _selectedSport == null) return;

    setState(() {
      _isSearching = true;
      _potentialMatches = [];
    });

    try {
      final matchIds = await _matchRepository.getPotentialMatches(
        _currentUser!.id,
        _selectedSport!.id,
      );

      for (final userId in matchIds) {
        final user = await _userRepository.getUserProfile(userId);
        if (user != null) {
          setState(() {
            _potentialMatches.add(user);
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des matchs: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSportSelected(SportModel sport) {
    setState(() {
      _selectedSport = sport;
      _potentialMatches = [];
    });
    _loadPotentialMatches();
  }

  void _onLike(UserModel user) async {
    if (_currentUser == null) return;

    try {
      await _matchRepository.createMatchRequest(_currentUser!.id, user.id);

      // Retirer l'utilisateur des matches potentiels
      setState(() {
        _potentialMatches.remove(user);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande envoyée à ${user.pseudo}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text('Erreur: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _onSkip(UserModel user) {
    setState(() {
      _potentialMatches.remove(user);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous avez passé ${user.pseudo ?? "cet utilisateur"}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AKOS')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AKOS'), actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),
      ]),
      body: Column(
        children: [
          // Sélecteur de sport
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _sports.isEmpty
                ? const Center(child: Text('Aucun sport disponible'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sports.length,
                    itemBuilder: (context, index) {
                      final sport = _sports[index];
                      final isSelected = _selectedSport?.id == sport.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(sport.name),
                          selected: isSelected,
                          onSelected: (_) => _onSportSelected(sport),
                          backgroundColor: Colors.grey[200],
                          selectedColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Indicateur de chargement pendant la recherche
          if (_isSearching) const LinearProgressIndicator(),

          // Message d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Liste des matches potentiels
          Expanded(
            child: _potentialMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? 'Recherche en cours...'
                              : 'Aucun match disponible pour ${_selectedSport?.name ?? "ce sport"}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (!_isSearching)
                          ElevatedButton.icon(
                            onPressed: _loadPotentialMatches,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Rafraîchir'),
                          ),
                      ],
                    ),
                  )
                : PageView.builder(
                    itemCount: _potentialMatches.length,
                    itemBuilder: (context, index) {
                      final user = _potentialMatches[index];
                      return MatchCard(
                        user: user,
                        sport: _selectedSport!,
                        onLike: () => _onLike(user),
                        onSkip: () => _onSkip(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
