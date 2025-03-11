// lib/views/discover/profile_card.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/user_model.dart';
import '../../models/sport_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileCard extends StatefulWidget {
  final UserModel user;
  final SportModel sport;
  final VoidCallback onLike;
  final VoidCallback onSkip;
  final bool isActive;
  final String sportLevel;

  const ProfileCard({
    Key? key,
    required this.user,
    required this.sport,
    required this.onLike,
    required this.onSkip,
    this.isActive = true,
    this.sportLevel = 'Inconnu',
  }) : super(key: key);

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;
  double _dragExtent = 0;
  bool _isDragging = false;
  bool _isExiting = false;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startDrag(DragStartDetails details) {
    if (!widget.isActive) return;
    setState(() {
      _dragStart = details.localPosition;
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || !widget.isActive) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final dragDelta = details.localPosition - _dragStart;

    // Calcul de l'angle de rotation basé sur le déplacement horizontal
    // Plus on est loin du centre, plus l'angle est important
    final newAngle = dragDelta.dx / screenWidth * 0.5; // Max ~30 degrés

    setState(() {
      _dragPosition = details.localPosition;
      _dragExtent = dragDelta.dx;
      _angle = newAngle;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging || !widget.isActive) return;
    _isDragging = false;

    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final isRightSwipe = _dragExtent > screenWidth * 0.4 || velocity > 700;
    final isLeftSwipe = _dragExtent < -screenWidth * 0.4 || velocity < -700;

    if (isRightSwipe) {
      _animateExit(true);
    } else if (isLeftSwipe) {
      _animateExit(false);
    } else {
      // Retour à la position initiale avec une animation
      _resetPosition();
    }
  }

  void _resetPosition() {
    setState(() {
      _isExiting = false;
    });

    // Animation de retour au centre
    final resetTween = Tween<double>(begin: _dragExtent, end: 0.0);
    final angleTween = Tween<double>(begin: _angle, end: 0.0);

    Animation<double> resetAnimation = resetTween.animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    Animation<double> angleAnimation = angleTween.animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    resetAnimation.addListener(() {
      setState(() {
        _dragExtent = resetAnimation.value;
        _angle = angleAnimation.value;
      });
    });

    _animationController.reset();
    _animationController.forward();
  }

  void _animateExit(bool isLike) {
    setState(() {
      _isExiting = true;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isLike ? screenWidth * 1.5 : -screenWidth * 1.5;
    final exitTween = Tween<double>(begin: _dragExtent, end: targetX);

    Animation<double> exitAnimation = exitTween.animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    exitAnimation.addListener(() {
      setState(() {
        _dragExtent = exitAnimation.value;
      });
    });

    _animationController.reset();
    _animationController.forward().then((_) {
      if (isLike) {
        widget.onLike();
      } else {
        widget.onSkip();
      }
    });
  }

  // lib/views/discover/profile_card.dart - MODIFICATION PARTIELLE

// Modifiez le build de la classe ProfileCard pour gérer correctement les images
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final opacity = widget.isActive ? 1.0 : 0.8;

    // Calculer le pourcentage de déplacement par rapport à la largeur de l'écran
    final swipePercentage = _dragExtent.abs() / (screenSize.width * 0.5);
    final cappedSwipePercentage = swipePercentage.clamp(0.0, 1.0);

    // Calculer la couleur de l'overlay en fonction de la direction du swipe
    final overlayColor = _dragExtent > 0
        ? Colors.green.withOpacity(0.2 * cappedSwipePercentage) // Like - Vert
        : Colors.red.withOpacity(0.2 * cappedSwipePercentage); // Skip - Rouge

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(_dragExtent, 0),
        child: Transform.rotate(
          angle: _angle,
          child: Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onPanStart: _startDrag,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Photo de profil
                    Positioned.fill(
                      child: widget.user.photo != null
                          ? Image.network(
                              widget.user.photo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    "Erreur de chargement d'image: $error");
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.person,
                                      size: 80, color: Colors.grey.shade800),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.person,
                                  size: 80, color: Colors.grey.shade800),
                            ),
                    ),

                    // Overlay coloré pour indiquer la direction du swipe
                    Positioned.fill(
                      child: Container(
                        color: overlayColor,
                      ),
                    ),

                    // Indicateurs de swipe
                    if (_dragExtent.abs() > 20)
                      Positioned(
                        top: 40,
                        left: _dragExtent > 0 ? 20 : null,
                        right: _dragExtent < 0 ? 20 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _dragExtent > 0 ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            _dragExtent > 0 ? "MATCH !" : "PASSER",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),

                    // Overlay dégradé en bas pour le texte
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.user.firstName ??
                                        widget.user.pseudo ??
                                        "Anonyme",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.sport.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.user.pseudo != null &&
                                widget.user.firstName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "@${widget.user.pseudo}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),

                            // Niveau de sport
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fitness_center,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Niveau: ${widget.sportLevel}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Paris',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            if (widget.user.description != null)
                              Text(
                                widget.user.description!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: widget.onSkip,
                                  icon: const Icon(Icons.close),
                                  label: const Text("Passer"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: widget.onLike,
                                  icon: const Icon(Icons.check),
                                  label: const Text("Match !"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}
