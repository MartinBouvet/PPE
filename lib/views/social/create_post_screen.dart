import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../repositories/auth_repository.dart';
import '../../repositories/post_repository.dart';
import '../../models/user_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _authRepository = AuthRepository();
  final _postRepository = PostRepository();

  UserModel? _currentUser;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vous devez être connecté pour créer un post')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: ${e.toString()}';
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
    if (_currentUser == null) return;

    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter du texte ou une image')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        // En mode démonstration, utiliser une image aléatoire de Pexels
        // au lieu d'essayer de télécharger l'image réelle
        final List<String> demoImages = [
          'https://images.pexels.com/photos/1080882/pexels-photo-1080882.jpeg',
          'https://images.pexels.com/photos/6551144/pexels-photo-6551144.jpeg',
          'https://images.pexels.com/photos/2468339/pexels-photo-2468339.jpeg',
          'https://images.pexels.com/photos/2827400/pexels-photo-2827400.jpeg',
          'https://images.pexels.com/photos/13922643/pexels-photo-13922643.jpeg',
        ];

        // Sélectionner une image aléatoire de la liste
        imageUrl = demoImages[DateTime.now().microsecond % demoImages.length];

        debugPrint('Image factice utilisée: $imageUrl');
      }

      // Créer le post avec le contenu et l'URL de l'image
      final content = _contentController.text.trim().isNotEmpty
          ? _contentController.text.trim()
          : null;

      debugPrint(
          'Création du post: userId=${_currentUser!.id}, content=$content, imageUrl=$imageUrl');

      final post = await _postRepository.createPost(
        userId: _currentUser!.id,
        content: content,
        imageUrl: imageUrl,
      );

      if (post != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post créé avec succès')),
        );
        Navigator.pop(
            context, true); // Retour avec un signal pour rafraîchir la liste
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Échec de la création du post';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: ${e.toString()}';
          _isSaving = false;
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
          if (_isSaving)
            const Padding(
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
          else
            TextButton.icon(
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
            // Message d'erreur
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // En-tête du post avec la photo de profil de l'utilisateur
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _currentUser?.photo != null
                        ? NetworkImage(_currentUser!.photo!)
                        : null,
                    child: _currentUser?.photo == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Que voulez-vous partager, ${_currentUser?.firstName ?? _currentUser?.pseudo ?? 'utilisateur'} ?",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zone de texte
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

            // Aperçu de l'image
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
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

            // Barre d'actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ajouter une image depuis la galerie
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _pickImage,
                    tooltip: 'Ajouter une image',
                  ),
                  // Prendre une photo avec la caméra
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
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
                    },
                    tooltip: 'Prendre une photo',
                  ),
                  const Spacer(),
                  // Bouton de publication
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitPost,
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
