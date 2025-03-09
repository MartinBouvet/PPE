// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_router.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'services/connectivity_service.dart';
import 'utils/db_initializer.dart';

void main() async {
  // Assurez-vous que tout est initialisé correctement
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Chargement des variables d'environnement
    await dotenv.load(fileName: ".env").catchError((e) {
      debugPrint(
          'Erreur de chargement du fichier .env: $e. Utilisation des valeurs par défaut.');
    });

    // Initialisation des services
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();

    // Initialisation de Supabase
    await SupabaseConfig.initialize();

    // Vérification de la structure de la base de données
    final dbStructureOk = await DbInitializer.checkDatabaseStructure();
    if (dbStructureOk) {
      // Initialisation des données de base si nécessaire
      await DbInitializer.initializeBasicData();
    }

    runApp(const MyApp());
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation: $e');
    // Afficher une UI d'erreur appropriée
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AKOS',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      // Écran de chargement
      builder: (context, child) {
        return child ?? const Center(child: CircularProgressIndicator());
      },
      // Localisation pour les formats de date, etc.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale(
          'fr', 'FR'), // Définir le français comme langue par défaut
    );
  }
}

// Application à afficher en cas d'erreur critique
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erreur AKOS',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Une erreur est survenue lors du démarrage',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Tenter de redémarrer l'application
                    main();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
