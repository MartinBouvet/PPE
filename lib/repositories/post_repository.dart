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

  // Stockage local des posts pour les démonstrations
  static final List<PostModel> _localPosts = [
    PostModel(
      id: '1',
      userId: '00000000-0000-0000-0000-000000000001',
      content:
          'Je recherche des partenaires pour jouer au tennis ce weekend au club du 15ème. Qui est partant ?',
      imageUrl:
          'https://images.pexels.com/photos/5730758/pexels-photo-5730758.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'published',
    ),
    PostModel(
      id: '2',
      userId: '00000000-0000-0000-0000-000000000002',
      content:
          'Superbe session de course à pied ce matin ! 10km en 42 minutes, nouveau record personnel 🏃‍♂️',
      imageUrl:
          'https://images.pexels.com/photos/5067188/pexels-photo-5067188.jpeg',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      status: 'published',
    ),
    PostModel(
      id: '3',
      userId: '00000000-0000-0000-0000-000000000003',
      content:
          'Cours de yoga en plein air demain à 10h au parc Montsouris. Places limitées, envoyez-moi un message si vous êtes intéressés.',
      imageUrl:
          'https://images.pexels.com/photos/8436661/pexels-photo-8436661.jpeg',
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

      // Créer le post localement
      final now = DateTime.now();
      final newPost = PostModel(
        id: _uuid.v4(),
        userId: userId,
        content: content,
        imageUrl: imageUrl,
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
        final now = DateTime.now();
        final newPost = PostModel(
          id: _uuid.v4(),
          userId: userId,
          content: content,
          imageUrl: imageUrl,
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
        _localPosts[index] = PostModel(
          id: oldPost.id,
          userId: oldPost.userId,
          content: content ?? oldPost.content,
          imageUrl: imageUrl ?? oldPost.imageUrl,
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
