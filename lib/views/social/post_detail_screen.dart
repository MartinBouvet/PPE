// lib/views/social/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    // Initialize timeago localization
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
      // Get current user
      _currentUser = await _authRepository.getCurrentUser();

      // Get post data
      _post = await _postRepository.getPostById(widget.postId);
      if (_post == null) {
        setState(() {
          _errorMessage = 'Post non trouvé';
        });
        return;
      }

      // Get post author
      _postAuthor = await _userRepository.getUserProfile(_post!.userId);

      // Get comments
      await _loadComments();
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

  Future<void> _loadComments() async {
    try {
      _comments = await _postRepository.getComments(widget.postId);

      // Load comment authors
      for (final comment in _comments) {
        if (!_commentAuthors.containsKey(comment.userId)) {
          final author = await _userRepository.getUserProfile(comment.userId);
          if (mounted) {
            setState(() {
              _commentAuthors[comment.userId] = author;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
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
        await _loadComments();
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

    if (_errorMessage != null || _post == null || _postAuthor == null) {
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
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
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
                if (value == 'edit') {
                  // TODO: Navigate to edit post screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                } else if (value == 'delete') {
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
                      Navigator.pop(context, true); // Pop with refresh flag
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
          // Post content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Post header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _postAuthor?.photo != null
                              ? CachedNetworkImageProvider(_postAuthor!.photo!)
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

                  // Post image if any
                  if (_post!.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: _post!.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => SizedBox(
                        height: 200,
                        child: Center(
                          child: Icon(Icons.error),
                        ),
                      ),
                    ),

                  // Post content
                  if (_post!.content != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _post!.content!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                  const Divider(),

                  // Comments section
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

                  // Comments list
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
                                    ? CachedNetworkImageProvider(author!.photo!)
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
                                      await _loadComments();
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

          // Comment input
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
                        ? CachedNetworkImageProvider(_currentUser!.photo!)
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
