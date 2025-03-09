// lib/config/supabase_config.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Singleton pour éviter de recréer l'instance à chaque fois
  static final SupabaseConfig _instance = SupabaseConfig._internal();

  factory SupabaseConfig() {
    return _instance;
  }

  SupabaseConfig._internal();

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ??
            'https://aaygogjvrgskhmlgymik.supabase.co',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ??
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFheWdvZ2p2cmdza2htbGd5bWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEzNjAyNTUsImV4cCI6MjA1NjkzNjI1NX0.3ea4d79P9z9EMoH3sSaumpibkVFa_MgST27ldlXkZjg',
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
