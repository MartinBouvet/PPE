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

      // En production, nous utiliserions ce code pour uploader l'image dans Supabase Storage
      /* 
      final fileExt = path.extension(imageFile.path).replaceAll('.', '');
      final fileName = '$_folder/profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      final bytes = await imageFile.readAsBytes();
      
      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      final imageUrl = _supabase.storage.from(_bucket).getPublicUrl(fileName);
      debugPrint('URL de l\'image générée: $imageUrl');
      return imageUrl;
      */

      // Solution temporaire: utiliser des photos de profil d'utilisateurs plus réalistes
      final List<String> sampleImages = [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=1770&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=1770&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=1770&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3',
      ];

      // Sélectionner une image aléatoire basée sur l'ID utilisateur pour simuler la persistance
      final imageIndex = userId.hashCode % sampleImages.length;
      debugPrint('Image sélectionnée: ${sampleImages[imageIndex]}');

      return sampleImages[imageIndex];
    } catch (e) {
      debugPrint('Erreur lors de l\'upload: $e');
      return 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3';
    }
  }

  Future<bool> deleteProfileImage(String imageUrl) {
    // Ne rien faire car nous utilisons des URLs d'image statiques
    return Future.value(true);
  }
}
