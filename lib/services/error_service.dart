import 'package:flutter/material.dart';

/// Service de gestion des erreurs pour l'application.
/// Fournit des méthodes pour traiter et afficher les erreurs de manière cohérente.
class ErrorService {
  /// Traite une erreur et retourne un message utilisateur approprié
  static String handleError(dynamic error) {
    if (error == null) {
      return 'Une erreur inconnue est survenue';
    }

    final errorStr = error.toString();

    // Erreurs d'authentification Supabase
    if (errorStr.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }

    if (errorStr.contains('email address is already registered')) {
      return 'Cet email est déjà utilisé';
    }

    if (errorStr.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    if (errorStr.contains('not a valid email')) {
      return 'Veuillez entrer une adresse email valide';
    }

    // Erreurs de réseau
    if (errorStr.contains('Failed host lookup') ||
        errorStr.contains('Network is unreachable') ||
        errorStr.contains('Connection refused')) {
      return 'Problème de connexion internet. Veuillez vérifier votre connexion et réessayer.';
    }

    // Erreurs de permission
    if (errorStr.contains('permission denied')) {
      return 'Vous n\'avez pas les droits nécessaires pour effectuer cette action';
    }

    // Erreurs de base de données
    if (errorStr.contains('Row not found') ||
        errorStr.contains('no rows returned')) {
      return 'Les données demandées n\'existent pas';
    }

    if (errorStr.contains('duplicate key value violates unique constraint')) {
      return 'Cette donnée existe déjà';
    }

    // Si aucune correspondance spécifique, retourner un message générique
    // En mode debug, on inclut l'erreur originale pour faciliter le débogage
    return kDebugMod
        ? 'Une erreur est survenue: $errorStr'
        : 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Affiche un snackbar d'erreur dans le contexte donné
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = handleError(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Affiche un dialog d'erreur
  static void showErrorDialog(BuildContext context, dynamic error) {
    final message = handleError(error);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Log l'erreur (à implémenter avec un service de logging)
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('ERROR: ${error.toString()}');
    if (stackTrace != null) {
      debugPrint('STACK TRACE: ${stackTrace.toString()}');
    }

    // Ici, vous pourriez également envoyer l'erreur à un service comme Firebase Crashlytics
    // ou un autre service de monitoring des erreurs
  }
}
