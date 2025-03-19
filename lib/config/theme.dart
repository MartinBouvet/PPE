// lib/config/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Couleur de fond claire pour les listes et conteneurs
  static const Color listBackground = Colors.white;
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color.fromARGB(255, 78, 122, 170), // Bleu visible dans vos mockups
      scaffoldBackgroundColor: Colors.white,
      
      // Ajout de ce paramètre pour les fonds de listes
      canvasColor: listBackground,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color.fromARGB(255, 78, 122, 170),
        unselectedItemColor: Colors.grey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 78, 122, 170),
          foregroundColor: Colors.white, // Texte blanc pour tous les boutons
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Plus d'espace horizontal et vertical
        ),
      ),
      // Style pour les boutons texte également
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color.fromARGB(255, 78, 122, 170),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      // Style pour les boutons outlined également
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color.fromARGB(255, 78, 122, 170),
          side: const BorderSide(color: Color.fromARGB(255, 78, 122, 170)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 78, 122, 170), width: 2),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),

      // A voir si ca fonctionne
      // Personnalisation des listes
      listTileTheme: const ListTileThemeData(
        tileColor: listBackground,
        selectedTileColor: Color(0xFFE3F2FD), // Bleu très clair quand sélectionné
      ),
    );
  }
  
  // Méthode utilitaire pour obtenir une version claire de la couleur primaire sans teinte violette
  static Color getLightPrimaryColor(BuildContext context) {
    // Utiliser un bleu clair prédéfini au lieu de l'opacité
    return Colors.blue.shade50;
  }
}