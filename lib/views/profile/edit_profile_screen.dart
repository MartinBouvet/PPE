// lib/views/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../services/image_service.dart';
import '../../config/supabase_config.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userRepository = UserRepository();
  final _imageService = ImageService();
  final _supabase = SupabaseConfig.client;
  late TextEditingController _pseudoController;
  late TextEditingController _firstNameController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _currentPhotoUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pseudoController = TextEditingController(text: widget.user.pseudo);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _descriptionController =
        TextEditingController(text: widget.user.description);
    _currentPhotoUrl = widget.user.photo;

    debugPrint(
        'Initialisation de l\'écran d\'édition pour : ${widget.user.pseudo}, ID: ${widget.user.id}');
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _firstNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      debugPrint('Image sélectionnée: ${pickedFile.path}');
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors de la sélection de l\'image: ${e.toString()}';
      });
      _showErrorSnackBar(_errorMessage!);
    }
  }

  // Dans EditProfileScreen - méthode _saveProfile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Préparer les données à mettre à jour
      final updatedData = {
        'pseudo': _pseudoController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      debugPrint('Données à mettre à jour: $updatedData');

      // Télécharger la nouvelle image si sélectionnée
      if (_selectedImage != null) {
        setState(() {
          _isUploadingImage = true;
        });

        // Utiliser le service d'image pour l'upload
        final photoUrl = await _imageService.uploadProfileImage(
            _selectedImage!, widget.user.id);

        if (photoUrl != null) {
          updatedData['photo'] = photoUrl;
          debugPrint('Photo mise à jour: $photoUrl');
        }

        setState(() {
          _isUploadingImage = false;
        });
      }

      // Mettre à jour le profil
      await _userRepository.updateUserProfile(widget.user.id, updatedData);

      debugPrint('Profil mis à jour avec succès');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour: $e');
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });

      if (mounted) {
        _showErrorSnackBar(_errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        actions: [
          if (_isLoading || _isUploadingImage)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message d'erreur
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Photo de profil
              Center(
                child: Stack(
                  children: [
                    // Image actuelle ou nouvelle
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (_currentPhotoUrl != null
                                ? CachedNetworkImageProvider(_currentPhotoUrl!)
                                    as ImageProvider
                                : null),
                        child:
                            (_selectedImage == null && _currentPhotoUrl == null)
                                ? Icon(Icons.person,
                                    size: 60, color: Colors.blue.shade800)
                                : null,
                      ),
                    ),
                    // Bouton pour changer l'image
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Champ Pseudo
              TextFormField(
                controller: _pseudoController,
                decoration: const InputDecoration(
                  labelText: 'Pseudo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un pseudo';
                  }
                  if (value.length < 3) {
                    return 'Le pseudo doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Champ Prénom
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                // Le prénom est optionnel, pas de validation nécessaire
              ),

              const SizedBox(height: 16),

              // Champ Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                maxLength: 500,
              ),

              const SizedBox(height: 24),

              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || _isUploadingImage) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading || _isUploadingImage
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
