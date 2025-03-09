// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_router.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chargement des variables d'environnement
  await dotenv.load(fileName: ".env");

  // Initialisation de Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ??
        'https://aaygogjvrgskhmlgymik.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFheWdvZ2p2cmdza2htbGd5bWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEzNjAyNTUsImV4cCI6MjA1NjkzNjI1NX0.3ea4d79P9z9EMoH3sSaumpibkVFa_MgST27ldlXkZjg',
  );

  runApp(const MyApp());
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
    );
  }
}
