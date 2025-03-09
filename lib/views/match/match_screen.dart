// lib/views/match/match_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
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
  final _matchRepository = MatchRepository();

  UserModel? _currentUser;
  List<SportModel> _sports = [];
  SportModel? _selectedSport;
  List<UserModel> _potentialMatches = [];
  bool _isLoading = true;

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
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        // Récupérer tous les sports
        _sports = await _userRepository.getAllSports();

        if (_sports.isNotEmpty) {
          _selectedSport = _sports.first;
          await _loadPotentialMatches();
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

  Future<void> _loadPotentialMatches() async {
    if (_currentUser == null || _selectedSport == null) return;

    try {
      final matchIds = await _matchRepository.getPotentialMatches(
        _currentUser!.id,
        _selectedSport!.id,
      );

      _potentialMatches = [];

      for (final userId in matchIds) {
        final user = await _userRepository.getUserProfile(userId);
        if (user != null) {
          _potentialMatches.add(user);
        }
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement des matches: ${e.toString()}',
          ),
        ),
      );
    }
  }

  void _onSportSelected(SportModel sport) {
    setState(() {
      _selectedSport = sport;
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
        SnackBar(content: Text('Demande envoyée à ${user.pseudo}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  void _onSkip(UserModel user) {
    setState(() {
      _potentialMatches.remove(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AKOS')),
      body: Column(
        children: [
          // Sélecteur de sport
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              // lib/views/match/match_screen.dart (suite)
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
                  ),
                );
              },
            ),
          ),

          // Liste des matches potentiels
          Expanded(
            child:
                _potentialMatches.isEmpty
                    ? const Center(
                      child: Text('Aucun match disponible pour ce sport'),
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
