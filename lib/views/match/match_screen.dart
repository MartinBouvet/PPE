import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import '../../models/match_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../repositories/match_repository.dart';
import '../chat/conversation_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  final _sportRepository = SportRepository();
  final _matchRepository = MatchRepository();

  late TabController _tabController;
  UserModel? _currentUser;
  List<SportModel> _sports = [];
  Map<int, List<UserModel>> _potentialMatches = {};
  List<MatchModel> _pendingRequests = [];
  List<MatchModel> _acceptedMatches = [];
  Map<String, UserModel?> _usersMap = {};
  Map<int, SportModel> _sportsMap = {};

  int? _selectedSportId;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  int _currentCardIndex = 0;
  double _cardOffset = 0;
  double _cardAngle = 0;
  bool _dragging = false;

  // Animation controllers
  late AnimationController _matchAnimationController;
  late AnimationController _likeAnimationController;
  late AnimationController _skipAnimationController;
  late AnimationController _cardEnterController;
  bool _showMatchAnimation = false;
  UserModel? _matchedUser;

  // Filter variables
  String _selectedLevel = 'Tous';
  double _maxDistance = 20.0;
  final List<String> _levels = [
    'Tous',
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize animation controllers
    _matchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _skipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cardEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _loadData();

    // Listen for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matchAnimationController.dispose();
    _likeAnimationController.dispose();
    _skipAnimationController.dispose();
    _cardEnterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        // Get all sports
        _sports = await _sportRepository.getAllSports();

        // Create sport lookup map
        _sportsMap = {for (var sport in _sports) sport.id: sport};

        // Set initial selected sport
        if (_selectedSportId == null && _sports.isNotEmpty) {
          _selectedSportId = _sports.first.id;
        }

        // Load data
        await Future.wait([
          _loadPotentialMatches(),
          _loadPendingRequests(),
          _loadAcceptedMatches(),
        ]);

        // Start card enter animation
        _cardEnterController.forward();
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
      debugPrint("ERREUR MATCH SCREEN: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPotentialMatches() async {
    if (_currentUser == null) return;

    try {
      _potentialMatches.clear();

      // Generate demo users for all sports
      _generateDemoUsers();
    } catch (e) {
      debugPrint('Error loading potential matches: $e');
    }
  }

  void _generateDemoUsers() {
    // Generate a fixed set of users with specific sports
    final demoUsersByType = {
      1: [
        // Basketball
        UserModel(
          id: 'demo1_basketball',
          pseudo: 'BasketPro',
          firstName: 'Nicolas',
          description:
              'Basketteur depuis 8 ans, niveau avancé. Je cherche des joueurs pour des matchs 3v3 le weekend.',
          photo:
              'https://images.pexels.com/photos/2269872/pexels-photo-2269872.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
        UserModel(
          id: 'demo2_basketball',
          pseudo: 'LanaHoops',
          firstName: 'Lana',
          description:
              'Joueuse de basket en club, niveau intermédiaire. Disponible les soirs de semaine pour s\'entraîner.',
          photo:
              'https://images.pexels.com/photos/1102341/pexels-photo-1102341.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
        UserModel(
          id: 'demo3_basketball',
          pseudo: 'JordanB',
          firstName: 'Jordan',
          description:
              'Passionné de basket depuis mon plus jeune âge. Je recherche des partenaires pour shooter au parc.',
          photo:
              'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
      ],
      2: [
        // Tennis
        UserModel(
          id: 'demo1_tennis',
          pseudo: 'TennisAce',
          firstName: 'Sophie',
          description:
              'Joueuse de tennis depuis 10 ans, classée 15/4. Cherche partenaire niveau similaire pour matchs réguliers.',
          photo:
              'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
        UserModel(
          id: 'demo2_tennis',
          pseudo: 'ServeKing',
          firstName: 'Thomas',
          description:
              'Joueur de tennis du dimanche, niveau débutant+. Disponible le weekend pour progresser ensemble.',
          photo:
              'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
        UserModel(
          id: 'demo3_tennis',
          pseudo: 'RafaelF',
          firstName: 'Raphaël',
          description:
              'Ancien joueur de tournois régionaux, je reprends après une pause. Cherche partenaires motivés!',
          photo:
              'https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
      ],
      3: [
        // Football
        UserModel(
          id: 'demo1_football',
          pseudo: 'FootballFan',
          firstName: 'Hugo',
          description:
              'Joueur de foot amateur depuis 15 ans. Je cherche une équipe pour des matchs à 5 ou 7.',
          photo:
              'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
        UserModel(
          id: 'demo2_football',
          pseudo: 'GoalKeeper',
          firstName: 'Laura',
          description:
              'Gardienne de but en recherche d\'une équipe féminine ou mixte pour des matchs réguliers.',
          photo:
              'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
        UserModel(
          id: 'demo3_football',
          pseudo: 'MbappeJr',
          firstName: 'Kylian',
          description:
              'Attaquant rapide cherchant des joueurs pour des 5v5 hebdomadaires, niveau intermédiaire.',
          photo:
              'https://images.pexels.com/photos/1250426/pexels-photo-1250426.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
      ],
      4: [
        // Natation
        UserModel(
          id: 'demo1_natation',
          pseudo: 'SwimProdigy',
          firstName: 'Maxime',
          description:
              'Nageur confirmé, spécialité crawl et papillon. Je cherche des partenaires pour s\'entraîner ensemble.',
          photo:
              'https://images.pexels.com/photos/1121796/pexels-photo-1121796.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
        UserModel(
          id: 'demo2_natation',
          pseudo: 'AquaGirl',
          firstName: 'Marine',
          description:
              'Nageuse régulière, tous niveaux. J\'adore les séances d\'aquagym aussi !',
          photo:
              'https://images.pexels.com/photos/1462637/pexels-photo-1462637.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
      ],
      5: [
        // Volleyball
        UserModel(
          id: 'demo1_volleyball',
          pseudo: 'VolleyStrike',
          firstName: 'Emma',
          description:
              'Joueuse de volleyball en club, niveau avancé. Recherche partenaires pour beach volley cet été.',
          photo:
              'https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
        UserModel(
          id: 'demo2_volleyball',
          pseudo: 'SpikeKing',
          firstName: 'Victor',
          description:
              'Joueur de volley passionné depuis 5 ans. Cherche équipe pour tournois amicaux.',
          photo:
              'https://images.pexels.com/photos/1300402/pexels-photo-1300402.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
      ],
      6: [
        // Fitness
        UserModel(
          id: 'demo1_fitness',
          pseudo: 'FitForLife',
          firstName: 'Julie',
          description:
              'Coach fitness certifiée. Cherche partenaires pour séances de HIIT et musculation.',
          photo:
              'https://images.pexels.com/photos/1065084/pexels-photo-1065084.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
        UserModel(
          id: 'demo2_fitness',
          pseudo: 'GymRat',
          firstName: 'Antoine',
          description:
              'Passionné de musculation, je m\'entraîne 5 fois par semaine. Cherche partenaire motivé!',
          photo:
              'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
      ],
      7: [
        // Escalade
        UserModel(
          id: 'demo1_escalade',
          pseudo: 'RockClimber',
          firstName: 'Alex',
          description:
              'Grimpeur passionné, niveau 6b. Je cherche des partenaires pour grimper en salle et en falaise.',
          photo:
              'https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
        UserModel(
          id: 'demo2_escalade',
          pseudo: 'AlpineGirl',
          firstName: 'Sarah',
          description:
              'Grimpeuse intermédiaire, à la recherche de partenaires pour des sessions régulières.',
          photo:
              'https://images.pexels.com/photos/1065084/pexels-photo-1065084.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
      ],
      8: [
        // Danse
        UserModel(
          id: 'demo1_danse',
          pseudo: 'DanceQueen',
          firstName: 'Chloe',
          description:
              'Danseuse confirmée en salsa et bachata. Je cherche un partenaire pour pratiquer et progresser.',
          photo:
              'https://images.pexels.com/photos/1462637/pexels-photo-1462637.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
        UserModel(
          id: 'demo2_danse',
          pseudo: 'SalsaKing',
          firstName: 'Roberto',
          description:
              'Danseur de salsa et bachata depuis 3 ans. Cherche partenaire pour pratique régulière.',
          photo:
              'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
      ],
      9: [
        // Course à pied
        UserModel(
          id: 'demo1_running',
          pseudo: 'RunnerPro',
          firstName: 'Paul',
          description:
              'Coureur semi-marathon en 1h45. Je cherche des partenaires pour des sorties longues le weekend.',
          photo:
              'https://images.pexels.com/photos/1250426/pexels-photo-1250426.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        ),
        UserModel(
          id: 'demo2_running',
          pseudo: 'JoggerGirl',
          firstName: 'Elodie',
          description:
              'Coureuse régulière, 10km en 55min. Cherche partenaires motivés pour courir en semaine.',
          photo:
              'https://images.pexels.com/photos/1065084/pexels-photo-1065084.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        ),
      ],
    };

    // Add users to _potentialMatches
    demoUsersByType.forEach((sportId, users) {
      _potentialMatches[sportId] = users;

      // Add users to _usersMap
      for (var user in users) {
        _usersMap[user.id] = user;
      }
    });

    // Add generic users for sports without specific users
    for (var sport in _sports) {
      if (!_potentialMatches.containsKey(sport.id)) {
        final demoUsers = [
          UserModel(
            id: 'generic_${sport.id}_1',
            pseudo: 'Sportif${sport.id}',
            firstName: 'Utilisateur',
            description:
                'Passionné(e) de ${sport.name}. Je cherche des partenaires pour pratiquer régulièrement.',
            photo:
                'https://images.pexels.com/photos/1251171/pexels-photo-1251171.jpeg?auto=compress&cs=tinysrgb&w=800',
            gender: 'M',
          ),
          UserModel(
            id: 'generic_${sport.id}_2',
            pseudo: 'Sport${sport.id}Fan',
            firstName: 'Amateur',
            description:
                'Amateur de ${sport.name} cherchant à progresser avec des partenaires réguliers.',
            photo:
                'https://images.pexels.com/photos/1065084/pexels-photo-1065084.jpeg?auto=compress&cs=tinysrgb&w=800',
            gender: 'F',
          ),
        ];

        _potentialMatches[sport.id] = demoUsers;

        for (var user in demoUsers) {
          _usersMap[user.id] = user;
        }
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    if (_currentUser == null) return;

    try {
      _pendingRequests =
          await _matchRepository.getPendingMatchRequests(_currentUser!.id);

      for (final request in _pendingRequests) {
        if (!_usersMap.containsKey(request.requesterId)) {
          final user =
              await _userRepository.getUserProfile(request.requesterId);
          if (user != null) {
            _usersMap[request.requesterId] = user;
          }
        }
      }

      // For demo purposes, add some pending requests if none exist
      if (_pendingRequests.isEmpty) {
        // Add 2 fake pending requests
        final demoRequester1 = UserModel(
          id: 'pending_request_1',
          pseudo: 'TennisLover',
          firstName: 'Marc',
          description:
              'Passionné de tennis cherchant des partenaires pour des matchs réguliers.',
          photo:
              'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        );

        final demoRequester2 = UserModel(
          id: 'pending_request_2',
          pseudo: 'RunningQueen',
          firstName: 'Léa',
          description:
              'Coureuse régulière cherchant des partenaires pour des sorties en forêt.',
          photo:
              'https://images.pexels.com/photos/1065084/pexels-photo-1065084.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        );

        _usersMap[demoRequester1.id] = demoRequester1;
        _usersMap[demoRequester2.id] = demoRequester2;

        _pendingRequests = [
          MatchModel(
            id: 'demo_pending_1',
            requesterId: demoRequester1.id,
            likedUserId: _currentUser!.id,
            requestStatus: 'pending',
            requestDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
          MatchModel(
            id: 'demo_pending_2',
            requesterId: demoRequester2.id,
            likedUserId: _currentUser!.id,
            requestStatus: 'pending',
            requestDate: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
      }
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }
  }

  Future<void> _loadAcceptedMatches() async {
    if (_currentUser == null) return;

    try {
      _acceptedMatches =
          await _matchRepository.getAcceptedMatches(_currentUser!.id);

      for (final match in _acceptedMatches) {
        final otherUserId = match.requesterId == _currentUser!.id
            ? match.likedUserId
            : match.requesterId;

        if (!_usersMap.containsKey(otherUserId)) {
          final user = await _userRepository.getUserProfile(otherUserId);
          if (user != null) {
            _usersMap[otherUserId] = user;
          }
        }
      }

      // For demo purposes, add some accepted matches if none exist
      if (_acceptedMatches.isEmpty) {
        // Add 3 fake accepted matches
        final demoMatch1 = UserModel(
          id: 'accepted_match_1',
          pseudo: 'BasketballStar',
          firstName: 'Kevin',
          description:
              'Basketteur passionné cherchant des partenaires pour des sessions régulières.',
          photo:
              'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        );

        final demoMatch2 = UserModel(
          id: 'accepted_match_2',
          pseudo: 'DanceGirl',
          firstName: 'Zoé',
          description:
              'Danseuse moderne cherchant des partenaires pour s\'entraîner ensemble.',
          photo:
              'https://images.pexels.com/photos/1462637/pexels-photo-1462637.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'F',
        );

        final demoMatch3 = UserModel(
          id: 'accepted_match_3',
          pseudo: 'TennisAce',
          firstName: 'Pierre',
          description:
              'Joueur de tennis cherchant des partenaires pour des matchs le weekend.',
          photo:
              'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=800',
          gender: 'M',
        );

        _usersMap[demoMatch1.id] = demoMatch1;
        _usersMap[demoMatch2.id] = demoMatch2;
        _usersMap[demoMatch3.id] = demoMatch3;

        _acceptedMatches = [
          MatchModel(
            id: 'demo_match_1',
            requesterId: demoMatch1.id,
            likedUserId: _currentUser!.id,
            requestStatus: 'accepted',
            requestDate: DateTime.now().subtract(const Duration(days: 10)),
            responseDate: DateTime.now().subtract(const Duration(days: 9)),
          ),
          MatchModel(
            id: 'demo_match_2',
            requesterId: _currentUser!.id,
            likedUserId: demoMatch2.id,
            requestStatus: 'accepted',
            requestDate: DateTime.now().subtract(const Duration(days: 5)),
            responseDate: DateTime.now().subtract(const Duration(days: 4)),
          ),
          MatchModel(
            id: 'demo_match_3',
            requesterId: demoMatch3.id,
            likedUserId: _currentUser!.id,
            requestStatus: 'accepted',
            requestDate: DateTime.now().subtract(const Duration(days: 2)),
            responseDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
      }
    } catch (e) {
      debugPrint('Error loading accepted matches: $e');
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _dragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_dragging) return;

    setState(() {
      _cardOffset += details.delta.dx;
      _cardAngle = _cardOffset / 300 * (math.pi / 10); // Max ~18 degrees
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_cardOffset.abs() > screenWidth * 0.4) {
      // Swipe threshold reached
      if (_cardOffset > 0) {
        _handleLike();
      } else {
        _handleSkip();
      }
    } else {
      // Return to center
      setState(() {
        _cardOffset = 0;
        _cardAngle = 0;
        _dragging = false;
      });
    }
  }

  Future<void> _handleLike() async {
    if (_selectedSportId == null) return;

    final matches = _potentialMatches[_selectedSportId] ?? [];
    if (matches.isEmpty || _currentCardIndex >= matches.length) return;

    final currentUser = matches[_currentCardIndex];

    // Start like animation
    _likeAnimationController.reset();
    _likeAnimationController.forward();

    // For demo, determine randomly if it's a match (40% chance)
    final random = math.Random();
    final isMatch = random.nextInt(10) < 4; // 40% chance

    if (isMatch) {
      await Future.delayed(const Duration(milliseconds: 700));
      _matchedUser = currentUser;
      setState(() {
        _showMatchAnimation = true;
      });
      _matchAnimationController.reset();
      _matchAnimationController.forward();

      // Add to accepted matches
      _acceptedMatches.add(MatchModel(
        id: 'match_${DateTime.now().millisecondsSinceEpoch}',
        requesterId: currentUser.id,
        likedUserId: _currentUser!.id,
        requestStatus: 'accepted',
        requestDate: DateTime.now().subtract(const Duration(minutes: 2)),
        responseDate: DateTime.now(),
      ));

      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _showMatchAnimation = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de partenariat envoyée !'),
          backgroundColor: Colors.green,
        ),
      );
    }

    _moveToNextCard();
  }

  void _handleSkip() {
    _skipAnimationController.reset();
    _skipAnimationController.forward();
    _moveToNextCard();
  }

  void _moveToNextCard() {
    if (_selectedSportId == null) return;

    final matches = _potentialMatches[_selectedSportId] ?? [];

    if (matches.isNotEmpty && _currentCardIndex < matches.length - 1) {
      setState(() {
        _cardOffset = 0;
        _cardAngle = 0;
        _dragging = false;
        _currentCardIndex++;

        // Animate new card entrance
        _cardEnterController.reset();
        _cardEnterController.forward();
      });
    } else {
      // We've gone through all cards, reset to first
      setState(() {
        _cardOffset = 0;
        _cardAngle = 0;
        _dragging = false;
        _currentCardIndex = 0;

        // Animate new card entrance
        _cardEnterController.reset();
        _cardEnterController.forward();
      });
    }
  }

  Future<void> _respondToMatchRequest(String requesterId, bool accept) async {
    if (_currentUser == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (requesterId.startsWith('pending_request')) {
        // Demo requester
        await Future.delayed(const Duration(milliseconds: 800));

        // If accepted, show the match animation
        if (accept) {
          _matchedUser = _usersMap[requesterId];
          setState(() {
            _showMatchAnimation = true;
          });
          _matchAnimationController.reset();
          _matchAnimationController.forward();

          await Future.delayed(const Duration(seconds: 3));
          setState(() {
            _showMatchAnimation = false;
          });
        }

        setState(() {
          _pendingRequests
              .removeWhere((request) => request.requesterId == requesterId);

          // If accepted, add to matches
          if (accept) {
            _acceptedMatches.add(MatchModel(
              id: 'new_match_${DateTime.now().millisecondsSinceEpoch}',
              requesterId: requesterId,
              likedUserId: _currentUser!.id,
              requestStatus: 'accepted',
              requestDate: DateTime.now().subtract(const Duration(days: 1)),
              responseDate: DateTime.now(),
            ));
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept
                ? 'Demande de partenariat acceptée'
                : 'Demande de partenariat refusée'),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
        );
      } else {
        final success = await _matchRepository.respondToMatchRequest(
          requesterId,
          _currentUser!.id,
          accept,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(accept
                  ? 'Demande de partenariat acceptée'
                  : 'Demande de partenariat refusée'),
              backgroundColor: accept ? Colors.green : Colors.red,
            ),
          );

          // Refresh data
          await _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de la réponse à la demande')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _startConversation(String userId, String pseudo) async {
    if (_currentUser == null) return;

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            conversationId: 'match_${_currentUser!.id}_$userId',
            otherUserPseudo: pseudo,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _selectSport(int sportId) {
    setState(() {
      _selectedSportId = sportId;
      _currentCardIndex = 0; // Reset card index when changing sport

      // Animate new card entrance
      _cardEnterController.reset();
      _cardEnterController.forward();
    });
  }

  void _showFilterDialog() {
    double tempMaxDistance = _maxDistance;
    String tempSelectedLevel = _selectedLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Skill level filter
                  const Text(
                    'Niveau',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tempSelectedLevel,
                    items: _levels.map((level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempSelectedLevel = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Distance filter
                  const Text(
                    'Distance maximale',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: tempMaxDistance,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${tempMaxDistance.round()} km',
                          onChanged: (value) {
                            setModalState(() {
                              tempMaxDistance = value;
                            });
                          },
                        ),
                      ),
                      Text('${tempMaxDistance.round()} km'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _maxDistance = tempMaxDistance;
                            _selectedLevel = tempSelectedLevel;

                            // For demo, shuffle the users to simulate filtering
                            if (_selectedSportId != null) {
                              final users = _potentialMatches[_selectedSportId];
                              if (users != null && users.isNotEmpty) {
                                users.shuffle();
                                _currentCardIndex = 0;

                                // Animate new card entrance
                                _cardEnterController.reset();
                                _cardEnterController.forward();
                              }
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Appliquer'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getRandomLevel() {
    const levels = ['Débutant', 'Intermédiaire', 'Avancé', 'Expert'];
    return levels[math.Random().nextInt(levels.length)];
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'quelques secondes';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partenaires')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partenaires')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Vous devez être connecté pour accéder à cette fonctionnalité',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.pop(context);
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    // Match animation overlay (shown when users match)
    if (_showMatchAnimation) {
      return AnimatedBuilder(
        animation: _matchAnimationController,
        builder: (context, child) {
          final animation = _matchAnimationController.value;

          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Background animation
                Positioned.fill(
                  child: Opacity(
                    opacity: math.min(1.0, animation * 2),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.purple.shade700,
                            Colors.indigo.shade800
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Particles effect (simulated with small circles)
                ...List.generate(30, (index) {
                  final random = math.Random(index);
                  final size = random.nextDouble() * 15 + 5;
                  final left =
                      random.nextDouble() * MediaQuery.of(context).size.width;
                  final top =
                      random.nextDouble() * MediaQuery.of(context).size.height;
                  final speed = random.nextDouble() * 2 + 1;

                  return Positioned(
                    left: left,
                    top: top - animation * 300 * speed,
                    child: Opacity(
                      opacity: math.min(1.0, animation * 3) * 0.7,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: [
                            Colors.pink,
                            Colors.purple,
                            Colors.indigo,
                            Colors.blue
                          ][random.nextInt(4)],
                        ),
                      ),
                    ),
                  );
                }),

                // Match text
                Center(
                  child: Opacity(
                    opacity:
                        math.max(0.0, math.min(1.0, (animation - 0.1) * 2)),
                    child: Transform.scale(
                      scale: 0.8 + animation * 0.5,
                      child: const Text(
                        'MATCH !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.pink,
                              blurRadius: 15,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // User photos
                if (_matchedUser != null)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity:
                          math.max(0.0, math.min(1.0, (animation - 0.3) * 2)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Current user photo
                          Transform.translate(
                            offset: Offset(-100 + animation * 50, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: Colors.white,
                                backgroundImage: _currentUser?.photo != null
                                    ? NetworkImage(_currentUser!.photo!)
                                    : null,
                                child: _currentUser?.photo == null
                                    ? const Icon(Icons.person,
                                        size: 70, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ),

                          // Matched user photo
                          Transform.translate(
                            offset: Offset(100 - animation * 50, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: Colors.white,
                                backgroundImage: _matchedUser?.photo != null
                                    ? NetworkImage(_matchedUser!.photo!)
                                    : null,
                                child: _matchedUser?.photo == null
                                    ? const Icon(Icons.person,
                                        size: 70, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // User names
                if (_matchedUser != null)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.55,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity:
                          math.max(0.0, math.min(1.0, (animation - 0.4) * 2)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentUser?.firstName ??
                                _currentUser?.pseudo ??
                                "Vous",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "  &  ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            _matchedUser?.firstName ??
                                _matchedUser?.pseudo ??
                                "Partenaire",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Message button
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity:
                          math.max(0.0, math.min(1.0, (animation - 0.6) * 2.5)),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showMatchAnimation = false;
                          });

                          if (_matchedUser != null) {
                            _startConversation(
                              _matchedUser!.id,
                              _matchedUser!.pseudo ?? 'Utilisateur',
                            );
                          }
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Envoyer un message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),

                // Skip button
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () {
                      setState(() {
                        _showMatchAnimation = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partenaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              text: 'Découvrir',
              icon: Icon(Icons.explore),
            ),
            Tab(
              text: 'Demandes',
              icon: Badge(
                isLabelVisible: _pendingRequests.isNotEmpty,
                label: Text(_pendingRequests.length.toString()),
                child: const Icon(Icons.person_add),
              ),
            ),
            Tab(
              text: 'Matches',
              icon: Badge(
                isLabelVisible: _acceptedMatches.isNotEmpty,
                label: Text(_acceptedMatches.length.toString()),
                child: const Icon(Icons.favorite),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Loading indicator
          if (_isProcessing) const LinearProgressIndicator(),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Sport filter chips for Discover tab
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _tabController.index == 0 && _sports.isNotEmpty
                ? Container(
                    key: const ValueKey('sport-filters'),
                    height: 70,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _sports.map((sport) {
                        final isSelected = _selectedSportId == sport.id;
                        final hasMatches = _potentialMatches
                                .containsKey(sport.id) &&
                            (_potentialMatches[sport.id]?.isNotEmpty ?? false);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(sport.name),
                            selected: isSelected,
                            onSelected: (_) => _selectSport(sport.id),
                            avatar:
                                hasMatches ? const Icon(Icons.people) : null,
                            backgroundColor:
                                hasMatches ? Colors.green.shade100 : null,
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
                      }).toList(),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty-filters'), height: 0),
          ),

          // Filter indicators
          if (_tabController.index == 0)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Filtres: $_selectedLevel, max. ${_maxDistance.round()} km',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Discover tab
                _buildDiscoverTab(),

                // Requests tab
                _buildRequestsTab(),

                // Matches tab
                _buildMatchesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_selectedSportId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'Sélectionnez un sport pour commencer',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 250,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                "Balayez les profils vers la droite pour proposer un match, ou vers la gauche pour passer",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    final matches = _potentialMatches[_selectedSportId] ?? [];

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun partenaire trouvé pour ${_sportsMap[_selectedSportId]?.name ?? "ce sport"}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez un autre sport ou modifiez vos filtres',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Get current user profile to show
    final currentUserAtIndex =
        _currentCardIndex < matches.length ? matches[_currentCardIndex] : null;

    if (currentUserAtIndex == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_satisfied_alt,
                size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Plus de profils disponibles pour le moment !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentCardIndex = 0;

                  // Animate new card entrance
                  _cardEnterController.reset();
                  _cardEnterController.forward();
                });
              },
              child: const Text('Voir plus de profils'),
            ),
          ],
        ),
      );
    }

    // Build the swipeable card
    final user = currentUserAtIndex;
    final sportLevel = _getRandomLevel();
    final randomDistance = (1 + math.Random().nextInt(15)).toDouble();
    final sport =
        _sportsMap[_selectedSportId] ?? SportModel(id: 0, name: "Sport");

    return Stack(
      children: [
        // Like animation
        AnimatedBuilder(
          animation: _likeAnimationController,
          builder: (context, child) {
            final value = _likeAnimationController.value;
            if (value == 0) return const SizedBox.shrink();

            return Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: value < 0.5 ? value * 2 : 2.0 - value * 2,
                    child: Transform.scale(
                      scale: 0.5 + value * 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Text(
                          'MATCH !',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Skip animation
        AnimatedBuilder(
          animation: _skipAnimationController,
          builder: (context, child) {
            final value = _skipAnimationController.value;
            if (value == 0) return const SizedBox.shrink();

            return Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: value < 0.5 ? value * 2 : 2.0 - value * 2,
                    child: Transform.scale(
                      scale: 0.5 + value * 0.5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Text(
                          'PASSER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Card
        Center(
          child: AnimatedBuilder(
            animation: _cardEnterController,
            builder: (context, child) {
              final value = _cardEnterController.value;

              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(_cardOffset, 0),
                    child: Transform.rotate(
                      angle: _cardAngle,
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.height * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                // Background image
                                Positioned.fill(
                                  child: user.photo != null
                                      ? CachedNetworkImage(
                                          imageUrl: user.photo!,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.person,
                                                size: 100, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.person,
                                              size: 100, color: Colors.grey),
                                        ),
                                ),

                                // Gradient overlay for readability
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 200,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // User info
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Name and sport badge
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user.firstName ??
                                                    user.pseudo ??
                                                    "Utilisateur",
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                sport.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Username
                                        if (user.pseudo != null)
                                          Text(
                                            "@${user.pseudo}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey.shade300,
                                            ),
                                          ),

                                        const SizedBox(height: 12),

                                        // Badges row
                                        Row(
                                          children: [
                                            // Level badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                      Icons.fitness_center,
                                                      size: 14,
                                                      color: Colors.white),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    sportLevel,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // Distance badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.location_on,
                                                      size: 14,
                                                      color: Colors.white),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "${randomDistance.toStringAsFixed(1)} km",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        // Description
                                        if (user.description != null)
                                          Text(
                                            user.description!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Like and Skip stamps
                                if (_cardOffset.abs() > 20)
                                  Positioned(
                                    top: 40,
                                    right: _cardOffset > 0 ? null : 20,
                                    left: _cardOffset > 0 ? 20 : null,
                                    child: Transform.rotate(
                                      angle: _cardOffset > 0 ? -0.2 : 0.2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _cardOffset > 0
                                              ? Colors.green
                                              : Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.white, width: 3),
                                        ),
                                        child: Text(
                                          _cardOffset > 0
                                              ? "MATCH !"
                                              : "PASSER",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Control buttons
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip button
              ElevatedButton(
                onPressed: _handleSkip,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  elevation: 5,
                ),
                child: const Icon(Icons.close, size: 30, color: Colors.red),
              ),

              // Like button
              ElevatedButton(
                onPressed: _handleLike,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  elevation: 5,
                ),
                child:
                    const Icon(Icons.favorite, size: 30, color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune demande de partenariat en attente',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                "Lorsque quelqu'un vous propose un match, la demande apparaîtra ici",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingRequests.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final requester = _usersMap[request.requesterId];

        if (requester == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header with user photo and info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // User photo
                    Hero(
                      tag: "request_${requester.id}",
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: requester.photo != null
                            ? CachedNetworkImageProvider(requester.photo!)
                            : null,
                        child: requester.photo == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            requester.firstName ??
                                requester.pseudo ??
                                'Utilisateur inconnu',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (requester.pseudo != null)
                            Text(
                              '@${requester.pseudo}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Demande envoyée il y a ${_formatTimeAgo(request.requestDate)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Random sport badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _sports.isNotEmpty
                            ? _sports[math.Random().nextInt(_sports.length)]
                                .name
                            : 'Sport',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Description
              if (requester.description != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      requester.description!,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Reject button
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                        onPressed: () =>
                            _respondToMatchRequest(requester.id, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Accept button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Accepter'),
                        onPressed: () =>
                            _respondToMatchRequest(requester.id, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    if (_acceptedMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Vous n\'avez pas encore de partenaires',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    "Proposez à des utilisateurs pour trouver vos partenaires de sport",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.pink.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.explore),
                    label: const Text('Découvrir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _acceptedMatches.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final match = _acceptedMatches[index];
        final otherUserId = match.requesterId == _currentUser!.id
            ? match.likedUserId
            : match.requesterId;
        final user = _usersMap[otherUserId];

        if (user == null) {
          return const SizedBox.shrink();
        }

        // Random sport for this match
        final randomSport = _sports.isNotEmpty
            ? _sports[math.Random(index).nextInt(_sports.length)]
            : SportModel(id: 0, name: "Sport");

        // Random match date
        final matchDate = match.responseDate ??
            DateTime.now()
                .subtract(Duration(days: 1 + math.Random(index).nextInt(10)));

        // Random number of sessions
        final sessionCount = 1 + math.Random(index).nextInt(8);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () =>
                _startConversation(user.id, user.pseudo ?? 'Utilisateur'),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // User photo with match badge
                Stack(
                  children: [
                    // User photo
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: user.photo != null
                            ? CachedNetworkImage(
                                imageUrl: user.photo!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade300,
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // User name
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Text(
                        user.firstName ?? user.pseudo ?? 'Partenaire',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Match badge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Match !',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sport badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          randomSport.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Match information
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Matchés le ${matchDate.day}/${matchDate.month}/${matchDate.year}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.sports,
                              size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '$sessionCount session${sessionCount > 1 ? 's' : ''} ensemble',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      // User description
                      if (user.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              user.description!,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Message button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _startConversation(
                              user.id, user.pseudo ?? 'Utilisateur'),
                          icon: const Icon(Icons.message),
                          label: const Text('Envoyer un message'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
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
    );
  }
}
