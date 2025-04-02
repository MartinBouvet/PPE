import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id_post'].toString(),
      userId: json['id_publisher'] ?? json['id_user'],
      content: json['description'],
      imageUrl: json['photo'],
      createdAt: DateTime.parse(json['post_date']),
    );
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
      id: json['id_comment'].toString(),
      postId: json['id_post'].toString(),
      userId: json['id_user'],
      content: json['content'],
      createdAt: DateTime.parse(json['comment_date']),
    );
  }
}

class PostRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<PostModel>> getPosts({
    String? userId,
    int limit = 20,
    int offset = 0,
    bool showAllUsers = true, // Paramètre pour afficher tous les posts
  }) async {
    try {
      var query = _supabase.from('post').select();

      // Filtrer par utilisateur seulement si showAllUsers est false
      if (userId != null && !showAllUsers) {
        query = query.eq('id_publisher', userId);
      }

      final response = await query
          .order('post_date', ascending: false)
          .range(offset, offset + limit - 1);

      List<PostModel> posts = [];
      for (final postData in response) {
        try {
          posts.add(PostModel.fromJson(postData));
        } catch (e) {
          debugPrint('Erreur lors du traitement du post: $e');
        }
      }

      return posts;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des posts: $e');
      return [];
    }
  }

  Future<PostModel?> getPostById(String postId) async {
    try {
      final response =
          await _supabase.from('post').select().eq('id_post', postId).single();

      return PostModel.fromJson(response);
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
      final now = DateTime.now().toIso8601String();

      final data = {
        'id_publisher': userId,
        'description': content,
        'photo': imageUrl,
        'post_date': now,
        'status': 'active',
        'location': null,
      };

      data.removeWhere((key, value) => value == null);

      final response =
          await _supabase.from('post').insert(data).select().single();

      return PostModel.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de la création du post: $e');
      return null;
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String userId,
    String? content,
    String? imageUrl,
  }) async {
    try {
      final postCheck = await _supabase
          .from('post')
          .select()
          .match({'id_post': postId, 'id_publisher': userId}).maybeSingle();

      if (postCheck == null) {
        return false;
      }

      final updateData = <String, dynamic>{};
      if (content != null) updateData['description'] = content;
      if (imageUrl != null) updateData['photo'] = imageUrl;

      await _supabase.from('post').update(updateData).eq('id_post', postId);

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du post: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId, String userId) async {
    try {
      final postCheck = await _supabase
          .from('post')
          .select()
          .match({'id_post': postId, 'id_publisher': userId}).maybeSingle();

      if (postCheck == null) {
        return false;
      }

      await _supabase.from('post').delete().eq('id_post', postId);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du post: $e');
      return false;
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comment')
          .select()
          .eq('id_post', postId)
          .order('comment_date');

      List<CommentModel> comments = [];
      for (final commentData in response) {
        try {
          comments.add(CommentModel.fromJson(commentData));
        } catch (e) {
          debugPrint('Erreur lors du traitement du commentaire: $e');
        }
      }

      return comments;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des commentaires: $e');
      return [];
    }
  }

  Future<CommentModel?> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
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

      return CommentModel.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du commentaire: $e');
      return null;
    }
  }

  Future<bool> deleteComment(String commentId, String userId) async {
    try {
      final commentCheck = await _supabase
          .from('comment')
          .select()
          .match({'id_comment': commentId, 'id_user': userId}).maybeSingle();

      if (commentCheck == null) {
        return false;
      }

      await _supabase.from('comment').delete().eq('id_comment', commentId);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du commentaire: $e');
      return false;
    }
  }
}
