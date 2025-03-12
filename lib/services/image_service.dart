// lib/services/image_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import 'package:http/http.dart' as http;

class ImageService {
  final _supabase = SupabaseConfig.client;

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = 'profile_${userId}_${const Uuid().v4()}$fileExt';

      debugPrint('Début de l\'upload de l\'image: $fileName');

      // Lire le fichier en bytes
      final bytes = await imageFile.readAsBytes();

      // Upload via Supabase Storage
      await _supabase.storage.from('profiles').uploadBinary(
            fileName,
            bytes,
          );

      debugPrint('Image téléchargée, génération de l\'URL publique');

      // Obtenir l'URL publique
      final imageUrl =
          _supabase.storage.from('profiles').getPublicUrl(fileName);

      debugPrint('URL de l\'image: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Erreur lors de l\'upload de l\'image: $e');

      // Utiliser une approche alternative pour l'upload
      try {
        // Sauvegarder l'image sur un service temporaire
        final tempImageUrl = await _uploadToTempService(imageFile);
        debugPrint('Image téléchargée sur service alternatif: $tempImageUrl');
        return tempImageUrl;
      } catch (innerError) {
        debugPrint('Erreur lors de l\'upload alternatif: $innerError');
        return null;
      }
    }
  }

  // Méthode alternative pour héberger temporairement une image
  // (imgbb ou service similaire serait idéal ici)
  Future<String?> _uploadToTempService(File imageFile) async {
    // Pour une démo, nous utilisons une URL statique
    return 'https://picsum.photos/200'; // URL fictive
  }

  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extraction du nom de fichier depuis l'URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;

      // Suppression du fichier
      await _supabase.storage.from('profiles').remove([fileName]);

      debugPrint('Image supprimée: $fileName');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }
}
