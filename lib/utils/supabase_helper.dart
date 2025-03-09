import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Helper pour gérer les opérations Supabase et les erreurs associées
class SupabaseHelper {
  static final _client = SupabaseConfig.client;

  /// Exécute une opération Supabase en gérant les erreurs
  static Future<T?> safeExecute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthException catch (e) {
      _handleAuthError(e);
      return null;
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      return null;
    } catch (e) {
      debugPrint('Erreur Supabase non gérée: $e');
      return null;
    }
  }

  /// Gère les erreurs d'authentification
  static void _handleAuthError(AuthException error) {
    debugPrint('Erreur d\'authentification: ${error.message}');
    String userMessage = '';

    if (error.message.contains('Invalid login credentials')) {
      userMessage = 'Identifiants invalides';
    } else if (error.message.contains('Email not confirmed')) {
      userMessage = 'Email non confirmé';
    } else if (error.message.contains('already registered')) {
      userMessage = 'Cet email est déjà utilisé';
    } else {
      userMessage = 'Erreur d\'authentification: ${error.message}';
    }

    throw Exception(userMessage);
  }

  /// Gère les erreurs de la base de données Postgres
  static void _handlePostgrestError(PostgrestException error) {
    debugPrint('Erreur PostgrestException: ${error.message}');
    String userMessage = '';

    if (error.code == '42P01') {
      userMessage = 'Table non trouvée';
    } else if (error.code == '23505') {
      userMessage = 'Cet enregistrement existe déjà';
    } else if (error.code == '23503') {
      userMessage = 'Contrainte de clé étrangère violée';
    } else if (error.code == '42703') {
      userMessage = 'Colonne non trouvée';
    } else {
      userMessage = 'Erreur de base de données';
    }

    if (kDebugMode) {
      userMessage += ': ${error.message}';
    }

    throw Exception(userMessage);
  }

  /// Vérifie si un utilisateur est connecté
  static bool isUserLoggedIn() {
    final user = _client.auth.currentUser;
    return user != null;
  }

  /// Récupère l'ID de l'utilisateur actuel ou null si non connecté
  static String? getCurrentUserId() {
    final user = _client.auth.currentUser;
    return user?.id;
  }

  /// Récupère l'email de l'utilisateur actuel ou null si non connecté
  static String? getCurrentUserEmail() {
    final user = _client.auth.currentUser;
    return user?.email;
  }

  /// Crée un stream pour écouter les changements de données
  static Stream<List<Map<String, dynamic>>> createStream(
    String table, {
    String? eq,
    String? eqValue,
    String? order,
    bool ascending = true,
    int? limit,
  }) {
    try {
      var query = _client.from(table).stream(primaryKey: ['id']);

      if (eq != null && eqValue != null) {
        query = query.eq(eq, eqValue);
      }

      if (order != null) {
        query = query.order(order, ascending: ascending);
      }

      return query
          .map((event) => event.map((e) => e as Map<String, dynamic>).toList());
    } catch (e) {
      debugPrint('Erreur lors de la création du stream: $e');
      return Stream.value([]);
    }
  }

  /// Vérifie si une table existe
  static Future<bool> tableExists(String tableName) async {
    try {
      // Simple query to check if table exists
      await _client.from(tableName).select().limit(1);
      return true;
    } catch (e) {
      if (e.toString().contains('does not exist')) {
        return false;
      }
      // For other errors, assume the table exists but there's another issue
      return true;
    }
  }
}
