// lib/views/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenir la hauteur de l'écran
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section Logo et introduction
                SizedBox(
                  height: screenHeight * 0.45,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'AKOS',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFF3B82F6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Trouvez des partenaires de sport près de chez vous',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      // Icône simple au lieu de l'animation Lottie
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports,
                          size: 100,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section des caractéristiques
                SizedBox(
                  height: screenHeight * 0.25,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Points forts de l'application
                      _buildFeatureItem(context, Icons.people,
                          'Rencontrez des sportifs partageant votre passion'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(context, Icons.sports_tennis,
                          'Tous sports disponibles'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(context, Icons.messenger_outline,
                          'Messagerie intégrée'),
                    ],
                  ),
                ),

                // Section des boutons
                SizedBox(
                  height: screenHeight * 0.20,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bouton de connexion
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Bouton d'inscription
                      OutlinedButton(
                        onPressed: () => context.go('/signup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Créer un compte',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
