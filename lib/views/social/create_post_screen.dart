// lib/views/social/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/sport_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/sport_repository.dart';
import '../../services/image_service.dart';

class CreatePostScreen extends StatefulWidget {
  final int? initialSportId;

  const CreatePostScreen({
    Key? key,
    this.initialSportId,
  }) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _authRepository = AuthRepository();
  final _postRepository = PostRepository();
  final _sportRepository = SportRepository();
  final _imageService = ImageService();

  String? _userId;
  List<SportModel> _sports = [];
  int? _selectedSportId;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSportId = widget.initialSportId;
    _loadData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _userId = user.id;
      } else {
        // Navigate back if not logged in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vous devez être connecté pour créer un post')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Load sports
      _sports = await _sportRepository.getAllSports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erreur lors de la sélection de l\'image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (_userId == null) return;

    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter du texte ou une image')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageService.uploadProfileImage(
          _selectedImage!,
          'post_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Create post
      final post = await _postRepository.createPost(
        userId: _userId!,
        content: _contentController.text.trim().isNotEmpty
            ? _contentController.text.trim()
            : null,
        imageUrl: imageUrl,
        sportId: _selectedSportId,
      );

      if (post != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post créé avec succès')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la création du post')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nouveau post')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau post'),
        actions: [
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _submitPost,
                  icon: const Icon(Icons.send),
                  label: const Text('Publier'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sport selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Sport (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports),
                ),
                value: _selectedSportId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Aucun sport spécifique'),
                  ),
                  ..._sports.map((sport) => DropdownMenuItem(
                        value: sport.id,
                        child: Text(sport.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSportId = value;
                  });
                },
              ),
            ),

            // Post content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Écrivez quelque chose...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),

            // Selected image preview
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _pickImage,
                    tooltip: 'Ajouter une image',
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1200,
                          maxHeight: 1200,
                          imageQuality: 80,
                        );

                        if (pickedFile == null) return;

                        setState(() {
                          _selectedImage = File(pickedFile.path);
                        });
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    tooltip: 'Prendre une photo',
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitPost,
                    icon: const Icon(Icons.send),
                    label: const Text('Publier'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
