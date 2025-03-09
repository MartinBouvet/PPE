import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

/// Service pour gérer les images dans l'application
class ImageService {
  static final _supabase = SupabaseConfig.client;

  /// Télécharge une image de profil dans le bucket Supabase
  /// Retourne l'URL de l'image téléchargée ou null en cas d'erreur
  static Future<String?> uploadProfileImage(
      File imageFile, String userId) async {
    try {
      final fileExt = path
          .extension(imageFile.path); // Obtient l'extension (.jpg, .png, etc.)
      final fileName =
          '${userId}_${const Uuid().v4()}$fileExt'; // Génère un nom unique

      // Téléchargement dans le bucket public 'profiles'
      final response =
          await _supabase.storage.from('profiles').upload(fileName, imageFile);

      // Construction de l'URL publique
      final imageUrl =
          _supabase.storage.from('profiles').getPublicUrl(fileName);

      debugPrint('Image téléchargée avec succès: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image: $e');
      return null;
    }
  }

  /// Supprime une image de profil du bucket Supabase
  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extraction du nom de fichier depuis l'URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;

      // Suppression du fichier
      await _supabase.storage.from('profiles').remove([fileName]);

      debugPrint('Image supprimée avec succès: $fileName');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }

  /// Sélectionne une image depuis la galerie ou la caméra
  /// Cette méthode nécessite l'ajout du package image_picker
  /// Retourne le fichier image sélectionné ou null en cas d'annulation/erreur
  static Future<File?> pickImage(BuildContext context,
      {bool fromCamera = false}) async {
    try {
      // Note: Ce code requiert le package image_picker
      // Pour l'implémenter, ajoutez d'abord cette dépendance dans pubspec.yaml
      /*
      final picker = ImagePicker();
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      
      final pickedFile = await picker.pickImage(
        source: source, 
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      */

      // Pour l'instant, retournons null car image_picker n'est pas implémenté
      // Dans une implémentation réelle, ce code serait décommenté
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }

  /// Compresse une image pour réduire sa taille
  /// Cette méthode nécessite l'ajout du package flutter_image_compress
  static Future<File?> compressImage(File file) async {
    try {
      // Note: Ce code requiert le package flutter_image_compress
      // Pour l'implémenter, ajoutez d'abord cette dépendance dans pubspec.yaml
      /*
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/${path.basename(file.path)}';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minHeight: 1200,
        minWidth: 1200,
      );
      
      return result != null ? File(result.path) : file;
      */

      // Pour l'instant, retournons le fichier original
      return file;
    } catch (e) {
      debugPrint('Erreur lors de la compression de l\'image: $e');
      return file;
    }
  }

  /// Met à jour l'URL de la photo de profil dans la base de données
  static Future<bool> updateUserProfilePhoto(
      String userId, String photoUrl) async {
    try {
      await _supabase
          .from('app_user')
          .update({'photo': photoUrl}).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la photo de profil: $e');
      return false;
    }
  }
}
