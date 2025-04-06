import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../models/user_model.dart';
import '../../models/sport_model.dart';

class MatchCard extends StatefulWidget {
  final UserModel user;
  final SportModel sport;
  final VoidCallback onLike;
  final VoidCallback onSkip;
  final String sportLevel;

  const MatchCard({
    Key? key,
    required this.user,
    required this.sport,
    required this.onLike,
    required this.onSkip,
    this.sportLevel = 'Intermédiaire',
  }) : super(key: key);

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
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
    setState(() {
      _dragStart = details.localPosition;
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final dragDelta = details.localPosition - _dragStart;

    // Calculate angle based on drag distance
    // The further from center, the more angle
    final newAngle =
        (dragDelta.dx / screenWidth) * (math.pi / 8); // Max ~22.5 degrees

    setState(() {
      _dragPosition = details.localPosition;
      _dragExtent = dragDelta.dx;
      _angle = newAngle;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
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
      // Reset position
      _resetPosition();
    }
  }

  void _resetPosition() {
    setState(() {
      _isExiting = false;
    });

    final resetTween = Tween<double>(
      begin: _dragExtent,
      end: 0.0,
    );

    final angleTween = Tween<double>(
      begin: _angle,
      end: 0.0,
    );

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
    final exitTween = Tween<double>(
      begin: _dragExtent,
      end: targetX,
    );

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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate swipe percentage for overlay opacity
    final swipePercentage = _dragExtent.abs() / (screenSize.width * 0.5);
    final cappedSwipePercentage = swipePercentage.clamp(0.0, 1.0);

    // Color overlay based on swipe direction
    final overlayColor = _dragExtent > 0
        ? Colors.green.withOpacity(0.3 * cappedSwipePercentage) // Like - Green
        : Colors.red.withOpacity(0.3 * cappedSwipePercentage); // Skip - Red

    return GestureDetector(
      onPanStart: _startDrag,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragExtent, 0),
        child: Transform.rotate(
          angle: _angle,
          child: Container(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Card content
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // User photo
                      Positioned.fill(
                        child: widget.user.photo != null
                            ? CachedNetworkImage(
                                imageUrl: widget.user.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.person,
                                      size: 120,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.person,
                                  size: 120,
                                  color: Colors.grey,
                                ),
                              ),
                      ),

                      // Gradient overlay for text readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 220,
                        child: Container(
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
                        ),
                      ),

                      // User info
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
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
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
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

                              // Level & distance info
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.fitness_center,
                                          size: 14,
                                          color: Colors.white,
                                        ),
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
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(math.Random().nextDouble() * 10).toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Description
                              if (widget.user.description != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  widget.user.description!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Color overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: overlayColor,
                    ),
                  ),
                ),

                // Swipe indicator
                if (_dragExtent.abs() > 20)
                  Positioned(
                    top: 40,
                    left: _dragExtent > 0 ? 20 : null,
                    right: _dragExtent < 0 ? 20 : null,
                    child: Transform.rotate(
                      angle: _dragExtent > 0 ? -0.2 : 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _dragExtent > 0 ? Colors.green : Colors.red,
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _dragExtent > 0 ? "MATCH !" : "PASSER",
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
    );
  }
}
