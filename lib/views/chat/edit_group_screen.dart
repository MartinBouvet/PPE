// lib/views/chat/edit_group_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/image_service.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final List<GroupMemberModel> members;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    required this.members,
  });
}

class GroupMemberModel {
  final String userId;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;
  final UserModel user;

  GroupMemberModel({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.user,
  });
}

class EditGroupScreen extends StatefulWidget {
  final GroupModel group;

  const EditGroupScreen({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  _EditGroupScreenState createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authRepository = AuthRepository();
  final _imageService = ImageService();

  UserModel? _currentUser;
  File? _selectedImage;
  String? _currentPhotoUrl;
  bool _isAdmin = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Initialize controllers
    _nameController.text = widget.group.name;
    _descriptionController.text = widget.group.description ?? '';
    _currentPhotoUrl = widget.group.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authRepository.getCurrentUser();

      if (_currentUser != null) {
        // Check if current user is admin
        _isAdmin = widget.group.members.any((member) =>
            member.userId == _currentUser!.id && member.role == 'admin');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Erreur lors de la sélection de l\'image: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new image if selected
      String? photoUrl = _currentPhotoUrl;
      if (_selectedImage != null) {
        setState(() {
          _isUploadingImage = true;
        });

        photoUrl = await _imageService.uploadProfileImage(
          _selectedImage!,
          'group_${widget.group.id}',
        );

        // Delete old image if exists and a new one was uploaded
        if (photoUrl != null && _currentPhotoUrl != null) {
          await _imageService.deleteProfileImage(_currentPhotoUrl!);
        }

        setState(() {
          _isUploadingImage = false;
        });
      }

      // TODO: Implement group update in a group repository
      // For now, we'll just show a success message

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Groupe mis à jour avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier le groupe')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier le groupe')),
        body: const Center(
          child: Text('Vous n\'avez pas les droits pour modifier ce groupe'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le groupe'),
        actions: [
          if (_isLoading || _isUploadingImage)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveGroup,
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
              // Group photo
              Center(
                child: Stack(
                  children: [
                    // Current image or selected image
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (_currentPhotoUrl != null
                              ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                              : null),
                      child:
                          (_selectedImage == null && _currentPhotoUrl == null)
                              ? const Icon(Icons.group,
                                  size: 60, color: Colors.blue)
                              : null,
                    ),

                    // Edit button
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

              // Group name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du groupe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom pour le groupe';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Group description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Members section
              const Text(
                'Membres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Members list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.group.members.length,
                itemBuilder: (context, index) {
                  final member = widget.group.members[index];
                  final isAdmin = member.role == 'admin';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.user.photo != null
                          ? NetworkImage(member.user.photo!) as ImageProvider
                          : null,
                      child: member.user.photo == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(member.user.pseudo ?? 'Utilisateur'),
                    subtitle: Text(isAdmin ? 'Administrateur' : 'Membre'),
                    trailing: member.userId != _currentUser?.id
                        ? PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: isAdmin ? 'remove_admin' : 'make_admin',
                                child: Row(
                                  children: [
                                    Icon(
                                      isAdmin
                                          ? Icons.person
                                          : Icons.admin_panel_settings,
                                      color: isAdmin ? Colors.red : Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAdmin ? 'Retirer admin' : 'Faire admin',
                                      style: TextStyle(
                                        color:
                                            isAdmin ? Colors.red : Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Retirer du groupe',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              // TODO: Implement member role change and removal
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fonctionnalité à venir'),
                                ),
                              );
                            },
                          )
                        : null,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Add members button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement add members functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter des membres'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),

              const SizedBox(height: 32),

              // Delete group button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer le groupe'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir supprimer ce groupe ? Cette action est irréversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      // TODO: Implement group deletion
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité à venir')),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Supprimer le groupe',
                    style: TextStyle(color: Colors.red),
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
