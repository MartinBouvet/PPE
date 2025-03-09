import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/auth/welcome_screen.dart';
import '../views/home/home_screen.dart';
import '../views/profile/add_sport_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/chat/chat_screen.dart';
import '../views/chat/conversation_screen.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AppRouter {
  static final AuthRepository _authRepository = AuthRepository();

  // Vérification de l'état d'authentification
  static Future<String> _checkAuthState() async {
    final user = await _authRepository.getCurrentUser();
    return user != null ? '/' : '/welcome';
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/', // Sera redirigé selon l'état d'authentification
    redirect: (BuildContext context, GoRouterState state) async {
      // Vérification de l'authentification à l'initialisation
      if (state.matchedLocation == '/') {
        final destination = await _checkAuthState();
        return destination;
      }

      // Si l'utilisateur n'est pas connecté et essaie d'accéder à des routes protégées
      final user = await _authRepository.getCurrentUser();
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/welcome';

      if (user == null && !loggingIn) {
        return '/welcome';
      }

      // Si l'utilisateur est connecté et essaie d'accéder aux routes d'authentification
      if (user != null && loggingIn) {
        return '/';
      }

      return null; // Pas de redirection
    },
    routes: [
      // Route initiale qui redirige vers welcome ou home
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // Routes d'authentification
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Routes de profil
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: '/profile/add_sport',
        builder: (context, state) => const AddSportScreen(),
      ),

      // Routes de chat
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          // Dans les nouvelles versions de go_router, les paramètres de requête sont accessibles autrement
          final otherUserPseudo =
              state.uri.queryParameters['otherUserPseudo'] ?? 'Utilisateur';
          return ConversationScreen(
            conversationId: conversationId,
            otherUserPseudo: otherUserPseudo,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page non trouvée',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('La page ${state.uri.path} n\'existe pas'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}
