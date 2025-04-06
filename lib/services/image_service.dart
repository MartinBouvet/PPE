import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../config/supabase_config.dart';

class ImageService {
  final _supabase = SupabaseConfig.client;
  static const String _bucket = 'bucket_image';
  static const String _folder = 'user_profiles';

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('Aucun utilisateur connecté');
        return null;
      }

      final List<String> maleProfileImages = [
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=1480&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1600486913747-55e5470d6f40?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1583195764036-6dc248ac07d9?q=80&w=1476&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1618641986557-1ecd230959aa?q=80&w=1587&auto=format&fit=crop&ixlib=rb-4.0.3',
      ];

      final imageIndex = userId.hashCode % maleProfileImages.length;
      debugPrint('Image sélectionnée: ${maleProfileImages[imageIndex]}');

      return maleProfileImages[imageIndex];
    } catch (e) {
      debugPrint('Erreur lors de l\'upload: $e');
      return 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3';
    }
  }

  Future<bool> deleteProfileImage(String imageUrl) {
    return Future.value(true);
  }
}
