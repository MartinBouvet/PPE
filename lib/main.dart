import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_router.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'services/connectivity_service.dart';
import 'utils/db_initializer.dart';
import 'services/elise_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env").catchError((e) {
      debugPrint('Error loading .env file: $e. Using default values.');
    });

    // Initialize services
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();

    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Check database structure
    final dbStructureOk = await DbInitializer.checkDatabaseStructure();
    if (dbStructureOk) {
      // Initialize basic data if needed
      await DbInitializer.initializeBasicData();
    }

    // Initialize Elise contact
    final eliseService = EliseService();
    await eliseService.initializeEliseContact();

    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Show appropriate error UI
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
      // Loading screen
      builder: (context, child) {
        return child ?? const Center(child: CircularProgressIndicator());
      },
      // Localization for date formats, etc.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'), // Set French as default language
    );
  }
}

// Application to display in case of critical error
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AKOS Error',
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
                  'An error occurred during startup',
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
                    // Try to restart the application
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
