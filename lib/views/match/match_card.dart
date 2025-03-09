// lib/views/match/match_card.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sport_model.dart';

class MatchCard extends StatelessWidget {
  final UserModel user;
  final SportModel sport;
  final VoidCallback onLike;
  final VoidCallback onSkip;

  const MatchCard({
    Key? key,
    required this.user,
    required this.sport,
    required this.onLike,
    required this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo de profil
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: user.photo != null
                    ? Image.network(user.photo!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          size: 120,
                          color: Colors.blue.shade800,
                        ),
                      ),
              ),
            ),

            // Informations utilisateur
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '@${user.pseudo ?? "Utilisateur"}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sport.name,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (user.description != null)
                      Text(
                        user.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Bouton Passer
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onSkip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Passer'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bouton Proposer
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onLike,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Proposer'),
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
    );
  }
}
