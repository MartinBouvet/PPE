import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math' show Random;
import '../../models/user_model.dart';
import '../../models/sport_model.dart';

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
    setState(() {
      _dragPosition = details.localPosition;
      _dragExtent = _dragPosition.dx - _dragStart.dx;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging || !widget.isActive) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final isRightSwipe = _dragExtent > 100 || velocity > 700;
    final isLeftSwipe = _dragExtent < -100 || velocity < -700;

    if (isRightSwipe) {
      _animateExit(true);
    } else if (isLeftSwipe) {
      _animateExit(false);
    } else {
      // Reset position
      setState(() {
        _dragStart = Offset.zero;
        _dragPosition = Offset.zero;
        _dragExtent = 0;
      });
    }
  }

  void _animateExit(bool isLike) {
    setState(() {
      _isExiting = true;
    });

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
    final opacity = widget.isActive ? 1.0 : 0.8;

    // Calculate rotation and offset based on drag or animation
    final rotation = (_dragExtent / 300) * (math.pi / 8);
    double dx = _dragExtent;

    // If animating exit
    if (_isExiting) {
      final screenWidth = MediaQuery.of(context).size.width;
      dx = _animationController.value *
          (screenWidth + 200) *
          (_dragExtent > 0 ? 1 : -1);
    }

    return GestureDetector(
      onPanStart: _startDrag,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              height: screenSize.height * 0.7,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Photo de profil
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        image: widget.user.photo != null
                            ? DecorationImage(
                                image: NetworkImage(widget.user.photo!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.user.photo == null
                          ? Center(
                              child: Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey.shade500,
                              ),
                            )
                          : null,
                    ),

                    // Overlay dégradé en bas pour le texte
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 220,
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.user.firstName ??
                                      widget.user.pseudo ??
                                      "Anonyme",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(Random().nextDouble() * 10).toStringAsFixed(1)} km',
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
                                  label: const Text("Proposer"),
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

                    // Indicateurs de swipe
                    if (_dragExtent != 0)
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
                            _dragExtent > 0 ? "PROPOSER" : "PASSER",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
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
    );
  }
}
