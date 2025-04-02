import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/post_repository.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({Key? key}) : super(key: key);

  @override
  _SocialScreenState createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  final _postRepository = PostRepository();

  UserModel? _currentUser;
  List<PostModel> _posts = [];
  Map<String, UserModel?> _postAuthors = {};

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Initialiser timeago pour le français
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer l'utilisateur actuel
      _currentUser = await _authRepository.getCurrentUser();
      debugPrint('Utilisateur chargé: ${_currentUser?.id}');

      // Charger les posts
      await _refreshPosts();
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
      });
      debugPrint('Erreur de chargement des données: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Récupérer les posts
      _posts = await _postRepository.getPosts(
        limit: 50,
      );

      debugPrint('Posts chargés: ${_posts.length}');

      // Charger les auteurs des posts
      for (final post in _posts) {
        if (!_postAuthors.containsKey(post.userId)) {
          final author = await _userRepository.getUserProfile(post.userId);
          if (mounted) {
            setState(() {
              _postAuthors[post.userId] = author;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement des posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fil social')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fil social')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Vous devez être connecté pour accéder au fil social',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fil social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshPosts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de chargement
          if (_isRefreshing) const LinearProgressIndicator(),

          // Message d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Liste des posts
          Expanded(
            child: _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.post_add,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun post pour le moment',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Soyez le premier à partager votre passion !',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePostScreen(),
                              ),
                            ).then((value) {
                              if (value == true) {
                                _refreshPosts();
                              }
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer un post'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshPosts,
                    child: ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final author = _postAuthors[post.userId];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    postId: post.id,
                                  ),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  _refreshPosts();
                                }
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // En-tête du post
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Avatar de l'auteur
                                      CircleAvatar(
                                        backgroundImage: author?.photo != null
                                            ? CachedNetworkImageProvider(
                                                author!.photo!)
                                            : null,
                                        child: author?.photo == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      // Nom de l'auteur et horodatage
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              author?.pseudo ??
                                                  'Utilisateur inconnu',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              timeago.format(post.createdAt,
                                                  locale: 'fr'),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Image du post
                                if (post.imageUrl != null)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 200,
                                    child: CachedNetworkImage(
                                      imageUrl: post.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                        child: Icon(Icons.error),
                                      ),
                                    ),
                                  ),

                                // Contenu du post
                                if (post.content != null)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      post.content!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                // Actions sur le post
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        icon:
                                            const Icon(Icons.thumb_up_outlined),
                                        label: const Text('J\'aime'),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Fonctionnalité à venir')),
                                          );
                                        },
                                      ),
                                      TextButton.icon(
                                        icon:
                                            const Icon(Icons.comment_outlined),
                                        label: const Text('Commenter'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PostDetailScreen(
                                                postId: post.id,
                                              ),
                                            ),
                                          ).then((value) {
                                            if (value == true) {
                                              _refreshPosts();
                                            }
                                          });
                                        },
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.share_outlined),
                                        label: const Text('Partager'),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Fonctionnalité à venir')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          ).then((value) {
            if (value == true) {
              _refreshPosts();
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Nouveau post',
      ),
    );
  }
}
