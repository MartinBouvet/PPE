import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:uuid/uuid.dart';

class PostModel {
  final String id;
  final String userId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;
  final String status;

  PostModel({
    required this.id,
    required this.userId,
    this.content,
    this.imageUrl,
    required this.createdAt,
    required this.status,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id_post']?.toString() ?? json['id'],
      userId: json['id_publisher'] ?? json['userId'],
      content: json['description'] ?? json['content'],
      imageUrl: json['photo'] ?? json['imageUrl'],
      createdAt: json['post_date'] != null
          ? DateTime.parse(json['post_date'])
          : json['createdAt'] != null
              ? json['createdAt']
              : DateTime.now(),
      status: json['status'] ?? 'published',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id_comment']?.toString() ?? json['id'],
      postId: json['id_post']?.toString() ?? json['postId'],
      userId: json['id_user'] ?? json['userId'],
      content: json['content'],
      createdAt: json['comment_date'] != null
          ? DateTime.parse(json['comment_date'])
          : json['createdAt'] != null
              ? json['createdAt']
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PostRepository {
  final _supabase = SupabaseConfig.client;
  static final _uuid = Uuid();

  // Stockage local des posts pour les démonstrations avec des images sportives
  static final List<PostModel> _localPosts = [
    PostModel(
      id: '1',
      userId: '00000000-0000-0000-0000-000000000001',
      content:
          'Je recherche des partenaires pour jouer au tennis ce weekend au club du 15ème. Qui est partant ?',
      imageUrl:
          'https://images.pexels.com/photos/8224716/pexels-photo-8224716.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'published',
    ),
    PostModel(
      id: '2',
      userId: '00000000-0000-0000-0000-000000000002',
      content:
          'Superbe session de course à pied ce matin ! 10km en 42 minutes, nouveau record personnel 🏃‍♂️',
      imageUrl:
          'https://images.pexels.com/photos/2526878/pexels-photo-2526878.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      status: 'published',
    ),
    PostModel(
      id: '3',
      userId: '00000000-0000-0000-0000-000000000003',
      content:
          'Cours de yoga en plein air demain à 10h au parc Montsouris. Places limitées, envoyez-moi un message si vous êtes intéressés.',
      imageUrl:
          'https://images.pexels.com/photos/4056723/pexels-photo-4056723.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'published',
    ),
  ];

  // Stockage local des commentaires pour les démonstrations
  static final Map<String, List<CommentModel>> _localComments = {
    '1': [
      CommentModel(
        id: '101',
        postId: '1',
        userId: '00000000-0000-0000-0000-000000000002',
        content: 'Je suis disponible samedi après-midi ! À quelle heure ?',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
      ),
      CommentModel(
        id: '102',
        postId: '1',
        userId: '00000000-0000-0000-0000-000000000003',
        content: 'Partante pour dimanche matin !',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 15)),
      ),
    ],
    '2': [
      CommentModel(
        id: '201',
        postId: '2',
        userId: '00000000-0000-0000-0000-000000000001',
        content:
            'Bravo ! C\'est un super temps ! Tu t\'entraînes pour un marathon ?',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      ),
    ],
    '3': [
      CommentModel(
        id: '301',
        postId: '3',
        userId: '00000000-0000-0000-0000-000000000004',
        content: 'Super initiative ! Je serai là avec deux amis.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  };

  // Images par sport pour les posts
  final Map<String, List<String>> _sportImages = {
    'tennis': [
      'https://images.pexels.com/photos/8224716/pexels-photo-8224716.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/2304369/pexels-photo-2304369.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/8985506/pexels-photo-8985506.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'running': [
      'https://images.pexels.com/photos/2526878/pexels-photo-2526878.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/7188638/pexels-photo-7188638.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/6552557/pexels-photo-6552557.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'yoga': [
      'https://images.pexels.com/photos/4056723/pexels-photo-4056723.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/3823039/pexels-photo-3823039.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/775417/pexels-photo-775417.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'basketball': [
      'https://images.pexels.com/photos/1080882/pexels-photo-1080882.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/2820902/pexels-photo-2820902.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/2362255/pexels-photo-2362255.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'football': [
      'https://images.pexels.com/photos/3148452/pexels-photo-3148452.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/918798/pexels-photo-918798.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/47730/the-ball-stadion-football-the-pitch-47730.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'swimming': [
      'https://images.pexels.com/photos/260598/pexels-photo-260598.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/61225/pexels-photo-61225.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/73760/swimming-swimmer-female-race-73760.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'boxing': [
      'https://images.pexels.com/photos/4804077/pexels-photo-4804077.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/9568970/pexels-photo-9568970.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/4761779/pexels-photo-4761779.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'fitness': [
      'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/38630/bodybuilder-weight-training-stress-38630.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/2468339/pexels-photo-2468339.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'climbing': [
      'https://images.pexels.com/photos/8329499/pexels-photo-8329499.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/7291709/pexels-photo-7291709.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/1822458/pexels-photo-1822458.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'cycling': [
      'https://images.pexels.com/photos/5077067/pexels-photo-5077067.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/5462562/pexels-photo-5462562.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/163491/bike-mountain-mountain-biking-trail-163491.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
    'default': [
      'https://images.pexels.com/photos/3621104/pexels-photo-3621104.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/3927385/pexels-photo-3927385.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'https://images.pexels.com/photos/260409/pexels-photo-260409.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    ],
  };

  String _getRandomSportImage(String? sportKeyword) {
    String sportType = 'default';

    if (sportKeyword != null) {
      final sportText = sportKeyword.toLowerCase();

      if (sportText.contains('tennis')) {
        sportType = 'tennis';
      } else if (sportText.contains('basket') || sportText.contains('ball')) {
        sportType = 'basketball';
      } else if (sportText.contains('foot') || sportText.contains('soccer')) {
        sportType = 'football';
      } else if (sportText.contains('run') || sportText.contains('cours')) {
        sportType = 'running';
      } else if (sportText.contains('yoga')) {
        sportType = 'yoga';
      } else if (sportText.contains('box') || sportText.contains('ring')) {
        sportType = 'boxing';
      } else if (sportText.contains('climb') ||
          sportText.contains('escalade')) {
        sportType = 'climbing';
      } else if (sportText.contains('swim') || sportText.contains('nage')) {
        sportType = 'swimming';
      } else if (sportText.contains('fitness') || sportText.contains('gym')) {
        sportType = 'fitness';
      } else if (sportText.contains('velo') ||
          sportText.contains('cycling') ||
          sportText.contains('bike')) {
        sportType = 'cycling';
      }
    }

    final sportImagesList = _sportImages[sportType] ?? _sportImages['default']!;
    return sportImagesList[DateTime.now().microsecond % sportImagesList.length];
  }

  Future<List<PostModel>> getPosts({
    String? userId,
    int limit = 20,
    int offset = 0,
    bool showAllUsers = true,
  }) async {
    try {
      // Essayer d'abord d'obtenir les posts depuis la base de données
      try {
        var query = _supabase.from('post').select();
        if (userId != null && !showAllUsers) {
          query = query.eq('id_publisher', userId);
        }
        final response = await query
            .order('post_date', ascending: false)
            .range(offset, offset + limit - 1);

        if (response != null && response.isNotEmpty) {
          return response
              .map<PostModel>((post) => PostModel.fromJson(post))
              .toList();
        }
      } catch (e) {
        debugPrint('Erreur Supabase, utilisation des données locales: $e');
      }

      // Si la base de données ne renvoie rien ou en cas d'erreur, utiliser les données locales
      if (userId != null && !showAllUsers) {
        return _localPosts.where((post) => post.userId == userId).toList();
      }
      return [..._localPosts];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des posts: $e');
      // Toujours avoir un fallback avec les données locales
      return [..._localPosts];
    }
  }

  Future<PostModel?> getPostById(String postId) async {
    try {
      // Essayer d'abord d'obtenir le post depuis la base de données
      try {
        final response = await _supabase
            .from('post')
            .select()
            .eq('id_post', postId)
            .maybeSingle();
        if (response != null) {
          return PostModel.fromJson(response);
        }
      } catch (e) {
        debugPrint('Erreur Supabase, recherche dans les données locales: $e');
      }

      // Sinon, chercher dans les données locales
      return _localPosts.firstWhere((post) => post.id == postId);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du post: $e');
      return null;
    }
  }

  Future<PostModel?> createPost({
    required String userId,
    String? content,
    String? imageUrl,
  }) async {
    try {
      // Tenter d'abord de créer le post dans la base de données
      try {
        final now = DateTime.now().toIso8601String();
        final data = {
          'id_publisher': userId,
          'description': content,
          'photo': imageUrl,
          'post_date': now,
          'status': 'published',
          'location': null,
        };
        data.removeWhere((key, value) => value == null);
        final response =
            await _supabase.from('post').insert(data).select().single();
        if (response != null) {
          return PostModel.fromJson(response);
        }
      } catch (e) {
        debugPrint('Erreur Supabase, création en local: $e');
      }

      // Sélectionner une image en rapport avec le contenu sportif
      final sportImage = _getRandomSportImage(content);

      // Créer le post localement
      final now = DateTime.now();
      final newPost = PostModel(
        id: _uuid.v4(),
        userId: userId,
        content: content,
        imageUrl: sportImage,
        createdAt: now,
        status: 'published',
      );

      // Ajouter en tête de liste pour qu'il apparaisse en premier
      _localPosts.insert(0, newPost);
      return newPost;
    } catch (e) {
      debugPrint('Erreur lors de la création du post: $e');

      // Même en cas d'erreur, créer un post local pour la démo
      try {
        final sportImage = _getRandomSportImage(content);
        final now = DateTime.now();
        final newPost = PostModel(
          id: _uuid.v4(),
          userId: userId,
          content: content,
          imageUrl: sportImage,
          createdAt: now,
          status: 'published',
        );
        _localPosts.insert(0, newPost);
        return newPost;
      } catch (finalError) {
        debugPrint('Erreur fatale: $finalError');
        return null;
      }
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String userId,
    String? content,
    String? imageUrl,
  }) async {
    try {
      // Essayer d'abord de mettre à jour dans la base de données
      try {
        final postCheck = await _supabase
            .from('post')
            .select()
            .match({'id_post': postId, 'id_publisher': userId}).maybeSingle();

        if (postCheck != null) {
          final updateData = <String, dynamic>{};
          if (content != null) updateData['description'] = content;
          if (imageUrl != null) updateData['photo'] = imageUrl;

          await _supabase.from('post').update(updateData).eq('id_post', postId);
          return true;
        }
      } catch (e) {
        debugPrint('Erreur Supabase, mise à jour en local: $e');
      }

      // Mise à jour locale
      final index = _localPosts
          .indexWhere((post) => post.id == postId && post.userId == userId);
      if (index != -1) {
        final oldPost = _localPosts[index];

        // Si le contenu est modifié et qu'il n'y a pas d'image spécifiée,
        // on peut choisir une nouvelle image en rapport avec le contenu
        String? newImageUrl = imageUrl;
        if (content != null && imageUrl == null) {
          newImageUrl = _getRandomSportImage(content);
        }

        _localPosts[index] = PostModel(
          id: oldPost.id,
          userId: oldPost.userId,
          content: content ?? oldPost.content,
          imageUrl: newImageUrl ?? oldPost.imageUrl,
          createdAt: oldPost.createdAt,
          status: oldPost.status,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du post: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId, String userId) async {
    try {
      // Essayer d'abord de supprimer dans la base de données
      try {
        final postCheck = await _supabase
            .from('post')
            .select()
            .match({'id_post': postId, 'id_publisher': userId}).maybeSingle();

        if (postCheck != null) {
          await _supabase.from('post').delete().eq('id_post', postId);
          return true;
        }
      } catch (e) {
        debugPrint('Erreur Supabase, suppression en local: $e');
      }

      // Suppression locale
      final index = _localPosts
          .indexWhere((post) => post.id == postId && post.userId == userId);
      if (index != -1) {
        _localPosts.removeAt(index);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du post: $e');
      return false;
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    try {
      // Essayer d'abord d'obtenir les commentaires depuis la base de données
      try {
        final response = await _supabase
            .from('comment')
            .select()
            .eq('id_post', postId)
            .order('comment_date');

        if (response != null && response.isNotEmpty) {
          return response
              .map<CommentModel>((comment) => CommentModel.fromJson(comment))
              .toList();
        }
      } catch (e) {
        debugPrint('Erreur Supabase, utilisation des commentaires locaux: $e');
      }

      // Si la base de données ne renvoie rien, utiliser les données locales
      return _localComments[postId] ?? [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des commentaires: $e');
      return _localComments[postId] ?? [];
    }
  }

  Future<CommentModel?> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      // Essayer d'abord d'ajouter le commentaire dans la base de données
      try {
        final now = DateTime.now().toIso8601String();
        final data = {
          'id_post': postId,
          'id_user': userId,
          'content': content,
          'comment_date': now,
        };
        final response =
            await _supabase.from('comment').insert(data).select().single();
        if (response != null) {
          return CommentModel.fromJson(response);
        }
      } catch (e) {
        debugPrint('Erreur Supabase, ajout de commentaire en local: $e');
      }

      // Ajouter localement
      final newComment = CommentModel(
        id: _uuid.v4(),
        postId: postId,
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
      );

      if (!_localComments.containsKey(postId)) {
        _localComments[postId] = [];
      }
      _localComments[postId]!.add(newComment);
      return newComment;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du commentaire: $e');

      // Même en cas d'erreur, créer un commentaire local pour la démo
      try {
        final newComment = CommentModel(
          id: _uuid.v4(),
          postId: postId,
          userId: userId,
          content: content,
          createdAt: DateTime.now(),
        );
        if (!_localComments.containsKey(postId)) {
          _localComments[postId] = [];
        }
        _localComments[postId]!.add(newComment);
        return newComment;
      } catch (finalError) {
        debugPrint('Erreur fatale: $finalError');
        return null;
      }
    }
  }

  Future<bool> deleteComment(String commentId, String userId) async {
    try {
      // Essayer d'abord de supprimer dans la base de données
      try {
        final commentCheck = await _supabase
            .from('comment')
            .select()
            .match({'id_comment': commentId, 'id_user': userId}).maybeSingle();

        if (commentCheck != null) {
          await _supabase.from('comment').delete().eq('id_comment', commentId);
          return true;
        }
      } catch (e) {
        debugPrint('Erreur Supabase, suppression de commentaire en local: $e');
      }

      // Suppression locale
      bool deleted = false;
      _localComments.forEach((postId, comments) {
        final index = comments.indexWhere(
            (comment) => comment.id == commentId && comment.userId == userId);
        if (index != -1) {
          comments.removeAt(index);
          deleted = true;
        }
      });
      return deleted;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du commentaire: $e');
      return false;
    }
  }
}
