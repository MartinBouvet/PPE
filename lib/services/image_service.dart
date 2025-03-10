// lib/services/image_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

/// Service pour gérer les images dans l'application
class ImageService {
  final _supabase = SupabaseConfig.client;

  /// Télécharge une image de profil dans le bucket Supabase
  /// Retourne l'URL de l'image téléchargée ou null en cas d'erreur
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileExt = path
          .extension(imageFile.path); // Obtient l'extension (.jpg, .png, etc.)
      final fileName =
          'profile_${userId}_${const Uuid().v4()}$fileExt'; // Génère un nom unique

      // Téléchargement dans le bucket 'profiles'
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
  Future<bool> deleteProfileImage(String imageUrl) async {
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

  /// Télécharge une image de lieu sportif dans le bucket Supabase
  Future<String?> uploadFacilityImage(File imageFile, int facilityId) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = 'facility_${facilityId}_${const Uuid().v4()}$fileExt';

      // Téléchargement dans le bucket 'facilities'
      await _supabase.storage.from('facilities').upload(fileName, imageFile);

      // Construction de l'URL publique
      final imageUrl =
          _supabase.storage.from('facilities').getPublicUrl(fileName);

      debugPrint('Image de lieu téléchargée avec succès: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image de lieu: $e');
      return null;
    }
  }

  /// Met à jour l'URL de la photo de profil dans la base de données
  Future<bool> updateUserProfilePhoto(String userId, String photoUrl) async {
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
