import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _authRepository = AuthRepository();
  final _postRepository = PostRepository();
  final _userRepository = UserRepository();
  final _commentController = TextEditingController();

  UserModel? _currentUser;
  PostModel? _post;
  UserModel? _postAuthor;
  List<CommentModel> _comments = [];
  Map<String, UserModel?> _commentAuthors = {};

  bool _isLoading = true;
  bool _isCommenting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer l'utilisateur actuel
      _currentUser = await _authRepository.getCurrentUser();

      // Récupérer le post
      _post = await _postRepository.getPostById(widget.postId);
      if (_post == null) {
        setState(() {
          _errorMessage = 'Post non trouvé';
        });
        return;
      }

      // Créer les auteurs mock pour les posts fictifs
      final mockAuthors = {
        '00000000-0000-0000-0000-000000000001': UserModel(
          id: '00000000-0000-0000-0000-000000000001',
          pseudo: 'Elise_Tennis',
          firstName: 'Elise',
          photo:
              'https://images.pexels.com/photos/1727280/pexels-photo-1727280.jpeg?auto=compress&cs=tinysrgb&w=200',
          description: 'Passionnée de tennis et de randonnée',
        ),
        '00000000-0000-0000-0000-000000000002': UserModel(
          id: '00000000-0000-0000-0000-000000000002',
          pseudo: 'Thomas_Runner',
          firstName: 'Thomas',
          photo:
              'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=200',
          description: 'Coureur semi-pro, 10km en 42min',
        ),
        '00000000-0000-0000-0000-000000000003': UserModel(
          id: '00000000-0000-0000-0000-000000000003',
          pseudo: 'Emma_Yoga',
          firstName: 'Emma',
          photo:
              'https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&w=200',
          description: 'Prof de yoga cherchant à former un groupe',
        ),
        '00000000-0000-0000-0000-000000000004': UserModel(
          id: '00000000-0000-0000-0000-000000000004',
          pseudo: 'Lucas_Basket',
          firstName: 'Lucas',
          photo:
              'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200',
          description: 'Basketteur depuis 10 ans',
        ),
      };

      // Récupérer l'auteur du post
      if (mockAuthors.containsKey(_post!.userId)) {
        _postAuthor = mockAuthors[_post!.userId];
      } else {
        try {
          _postAuthor = await _userRepository.getUserProfile(_post!.userId);
        } catch (e) {
          debugPrint('Erreur chargement auteur: $e');
          // En cas d'erreur, utiliser l'utilisateur actuel pour le post
          if (_currentUser != null && _post!.userId == _currentUser!.id) {
            _postAuthor = _currentUser;
          }
        }
      }

      // Récupérer les commentaires
      await _loadComments(mockAuthors);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du post: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadComments(Map<String, UserModel?> mockAuthors) async {
    try {
      _comments = await _postRepository.getComments(widget.postId);

      // Charger les auteurs des commentaires
      for (final comment in _comments) {
        if (!_commentAuthors.containsKey(comment.userId)) {
          // Si c'est un utilisateur fictif, utiliser les données mock
          if (mockAuthors.containsKey(comment.userId)) {
            _commentAuthors[comment.userId] = mockAuthors[comment.userId];
          } else if (_currentUser != null &&
              comment.userId == _currentUser!.id) {
            // Si c'est l'utilisateur actuel
            _commentAuthors[comment.userId] = _currentUser;
          } else {
            // Sinon, essayer de récupérer l'auteur
            try {
              final author =
                  await _userRepository.getUserProfile(comment.userId);
              if (mounted) {
                setState(() {
                  _commentAuthors[comment.userId] = author;
                });
              }
            } catch (e) {
              debugPrint('Erreur chargement auteur de commentaire: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des commentaires: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null) return;

    setState(() {
      _isCommenting = true;
    });

    try {
      final comment = await _postRepository.addComment(
        postId: widget.postId,
        userId: _currentUser!.id,
        content: _commentController.text.trim(),
      );

      if (comment != null) {
        _commentController.clear();

        // Ajouter l'auteur du commentaire (l'utilisateur actuel)
        _commentAuthors[_currentUser!.id] = _currentUser;

        // Recharger les commentaires
        _comments = await _postRepository.getComments(widget.postId);
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Erreur lors de l\'ajout du commentaire: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCommenting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du post')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du post')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Une erreur est survenue',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du post'),
        actions: [
          if (_currentUser?.id == _post!.userId)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer le post'),
                      content: const Text(
                          'Êtes-vous sûr de vouloir supprimer ce post ?'),
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
                    final success = await _postRepository.deletePost(
                      widget.postId,
                      _currentUser!.id,
                    );

                    if (success && mounted) {
                      Navigator.pop(context, true); // Pop avec refresh flag
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Erreur lors de la suppression du post'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Contenu du post
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête du post
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _postAuthor?.photo != null
                              ? NetworkImage(_postAuthor!.photo!)
                              : null,
                          child: _postAuthor?.photo == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _postAuthor?.pseudo ?? 'Inconnu',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                timeago.format(_post!.createdAt, locale: 'fr'),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image du post
                  if (_post!.imageUrl != null)
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: Image.network(
                        _post!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey.shade400,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Contenu du post
                  if (_post!.content != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _post!.content!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.thumb_up_outlined),
                          label: const Text('J\'aime'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Vous avez aimé ce post')),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Partager'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Post partagé avec succès')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Section des commentaires
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Commentaires (${_comments.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Liste des commentaires
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Aucun commentaire pour le moment',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final author = _commentAuthors[comment.userId];

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: author?.photo != null
                                    ? NetworkImage(author!.photo!)
                                    : null,
                                child: author?.photo == null
                                    ? const Icon(Icons.person, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          author?.pseudo ?? 'Inconnu',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeago.format(comment.createdAt,
                                              locale: 'fr'),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(comment.content),
                                  ],
                                ),
                              ),
                              if (_currentUser?.id == comment.userId)
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                            'Supprimer le commentaire'),
                                        content: const Text(
                                            'Êtes-vous sûr de vouloir supprimer ce commentaire ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Annuler'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _postRepository.deleteComment(
                                        comment.id,
                                        _currentUser!.id,
                                      );
                                      // Recharger les commentaires
                                      _comments = await _postRepository
                                          .getComments(widget.postId);
                                      setState(() {});
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Zone de saisie des commentaires
          if (_currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: _currentUser?.photo != null
                        ? NetworkImage(_currentUser!.photo!)
                        : null,
                    child: _currentUser?.photo == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: _isCommenting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isCommenting ? null : _addComment,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
