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
      debugPrint(
          'Début du téléchargement de l\'image de profil pour l\'utilisateur $userId');
      final fileExt = path.extension(imageFile.path);
      final fileName = 'profile_${userId}_${const Uuid().v4()}$fileExt';

      // Lire le fichier en bytes
      final bytes = await imageFile.readAsBytes();

      // Vérifier la taille de l'image
      debugPrint('Taille de l\'image: ${bytes.length} bytes');

      // Si l'image est trop grande, la redimensionner
      Uint8List uploadBytes = bytes;
      if (bytes.length > 5 * 1024 * 1024) {
        // Plus de 5MB
        debugPrint('Image trop grande, compression nécessaire');
        // Dans une vraie app, on utiliserait flutter_image_compress pour redimensionner
        // Pour cette démo, on continuera avec l'image originale
      }

      // Upload via Supabase Storage (sans options spécifiques)
      await _supabase.storage.from('profiles').uploadBinary(
            fileName,
            uploadBytes,
          );

      debugPrint('Image téléchargée, génération de l\'URL publique');

      // Obtenir l'URL publique
      final imageUrl =
          _supabase.storage.from('profiles').getPublicUrl(fileName);

      debugPrint('URL de l\'image générée: $imageUrl');

      // Vérifier si l'URL est accessible
      try {
        final response = await http.head(Uri.parse(imageUrl));
        if (response.statusCode != 200) {
          debugPrint(
              'L\'URL de l\'image n\'est pas accessible: ${response.statusCode}');
        } else {
          debugPrint('L\'URL de l\'image est accessible');
        }
      } catch (e) {
        debugPrint('Erreur lors de la vérification de l\'URL: $e');
      }

      return imageUrl;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image de profil: $e');

      // Essai alternatif: upload avec un chemin différent
      try {
        final fileExt = path.extension(imageFile.path);
        final fileName = 'user_photos/${userId}_${const Uuid().v4()}$fileExt';

        final bytes = await imageFile.readAsBytes();

        await _supabase.storage.from('bucket_image').uploadBinary(
              fileName,
              bytes,
            );

        final imageUrl =
            _supabase.storage.from('bucket_image').getPublicUrl(fileName);
        debugPrint('URL de l\'image (méthode alternative): $imageUrl');

        return imageUrl;
      } catch (alternativeError) {
        debugPrint(
            'Erreur lors du téléchargement alternatif: $alternativeError');

        // En dernier recours, utiliser une URL d'image par défaut
        return 'https://ui-avatars.com/api/?name=${userId.substring(0, 2)}&background=random';
      }
    }
  }

  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extraction du nom de fichier depuis l'URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) {
        debugPrint(
            'Impossible d\'extraire le nom de fichier de l\'URL: $imageUrl');
        return false;
      }

      final fileName = pathSegments.last;
      debugPrint('Suppression de l\'image: $fileName');

      // Déterminer le bucket en fonction de l'URL
      String bucket = 'profiles';
      if (imageUrl.contains('bucket_image')) {
        bucket = 'bucket_image';

        // Pour le bucket_image, le chemin peut inclure des dossiers
        if (pathSegments.length > 1) {
          final folderPath =
              pathSegments.sublist(pathSegments.length - 2).join('/');
          await _supabase.storage.from(bucket).remove([folderPath]);
          debugPrint('Image supprimée (avec chemin de dossier): $folderPath');
          return true;
        }
      }

      // Suppression du fichier
      await _supabase.storage.from(bucket).remove([fileName]);
      debugPrint('Image supprimée: $fileName');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }
}
