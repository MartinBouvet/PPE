// lib/services/image_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ImageService {
  final _supabase = SupabaseConfig.client;
  static const String _bucket = 'bucket_user';
  static const String _folder = 'photo_profile';

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
  try {
    // Vérifiez l'authentification
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint('Erreur : Aucun utilisateur connecté');
      return null;
    }

    debugPrint('Utilisateur connecté: ${currentUser.id}');
    
    // Générer un nom de fichier unique
    final fileExt = path.extension(imageFile.path);
    final fileName = '$_folder/profile_${userId}_${const Uuid().v4()}$fileExt';
    
    debugPrint('Nom de fichier généré: $fileName');
    
    // Lire le fichier en bytes
    Uint8List bytes = await imageFile.readAsBytes();
    debugPrint('Taille de l\'image: ${bytes.length} bytes');

    // Redimensionner et compresser l'image si nécessaire
    final resizedImage = _resizeImage(bytes);
    debugPrint('Taille après redimensionnement: ${resizedImage.length} bytes');

    try {
      // Vérifiez les buckets disponibles
      final buckets = await _supabase.storage.listBuckets();
      debugPrint('Buckets disponibles: ${buckets.map((b) => b.name).toList()}');
    } catch (e) {
      debugPrint('Erreur lors de la liste des buckets: $e');
    }

    // Upload dans le bucket
    try {
      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        resizedImage,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      // Obtenir l'URL publique
      final imageUrl = _supabase.storage.from(_bucket).getPublicUrl(fileName);
      debugPrint('URL de l\'image générée: $imageUrl');

      return imageUrl;
    } catch (uploadError) {
      debugPrint('Détails complets de l\'erreur d\'upload: $uploadError');
      return null;
    }
  } catch (e) {
    debugPrint('Erreur globale lors de l\'upload: $e');
    return null;
  }
}

  // Méthode de redimensionnement d'image
  Uint8List _resizeImage(Uint8List bytes, {int maxWidth = 800, int maxHeight = 800, int quality = 85}) {
    try {
      // Décoder l'image
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('Impossible de décoder l\'image');
        return bytes;
      }

      // Redimensionner si nécessaire
      img.Image resizedImage;
      if (image.width > maxWidth || image.height > maxHeight) {
        resizedImage = img.copyResize(
          image, 
          width: maxWidth,
          height: maxHeight,
          interpolation: img.Interpolation.average,
        );
      } else {
        resizedImage = image;
      }

      // Compresser l'image
      return Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality)
      );
    } catch (e) {
      debugPrint('Erreur lors du redimensionnement de l\'image: $e');
      return bytes;
    }
  }

  // Méthode de suppression 
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extraction du nom de fichier depuis l'URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) {
        debugPrint('Impossible d\'extraire le nom de fichier de l\'URL: $imageUrl');
        return false;
      }

      // Pour les URL de bucket_user, trouver le chemin du fichier
      final fullPath = pathSegments.join('/');

      try {
        await _supabase.storage.from(_bucket).remove([fullPath]);
        debugPrint('Image supprimée: $fullPath');
        return true;
      } catch (e) {
        debugPrint('Erreur lors de la suppression de l\'image: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur globale lors de la suppression de l\'image: $e');
      return false;
    }
  }
}