// lib/repositories/post_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

// These are placeholder classes for demonstration purposes
// They should be defined in their own model files
class PostModel {
  final String id;
  final String userId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;
  final int? sportId;

  PostModel({
    required this.id,
    required this.userId,
    this.content,
    this.imageUrl,
    required this.createdAt,
    this.sportId,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id_post'].toString(),
      userId: json['id_user'],
      content: json['content'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      sportId: json['id_sport'],
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
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PostRepository {
  final _supabase = SupabaseConfig.client;

  // Get posts with optional filters
  Future<List<PostModel>> getPosts({
    int? sportId,
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Start with a basic query
      var queryBuilder = _supabase
          .from('post')
          .select()
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      // Convert the builder to a string query
      String query = "order=created_at.desc&limit=$limit&offset=$offset";

      // Add filters if provided
      if (sportId != null) {
        query += "&id_sport=eq.$sportId";
      }

      if (userId != null) {
        query += "&id_user=eq.$userId";
      }

      // Execute the query using a simpler approach
      final response =
          await _supabase.from('post').select().withConverter((data) => data);

      // Filter in-memory if needed (as a fallback)
      List filteredResponse = response;
      if (sportId != null) {
        filteredResponse = filteredResponse
            .where((item) => item['id_sport'] == sportId)
            .toList();
      }
      if (userId != null) {
        filteredResponse = filteredResponse
            .where((item) => item['id_user'] == userId)
            .toList();
      }

      // Sort by created_at in descending order
      filteredResponse.sort((a, b) {
        DateTime dateA = DateTime.parse(a['created_at']);
        DateTime dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      // Apply limit
      if (filteredResponse.length > limit) {
        filteredResponse = filteredResponse.sublist(0, limit);
      }

      List<PostModel> posts = [];
      for (final postData in filteredResponse) {
        try {
          // Process post data to handle foreign keys and timestamps
          Map<String, dynamic> formattedPost =
              Map<String, dynamic>.from(postData);

          // Convert any timestamps to ISO format if needed
          if (formattedPost['created_at'] is! String) {
            formattedPost['created_at'] = DateTime.now().toIso8601String();
          }

          posts.add(PostModel.fromJson(formattedPost));
        } catch (e) {
          debugPrint('Error processing post: $e');
        }
      }

      return posts;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  // Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final response = await _supabase
          .from('post')
          .select()
          .match({'id_post': postId})
          .limit(1)
          .withConverter((data) => data.isNotEmpty ? data.first : null);

      if (response == null) {
        return null;
      }

      Map<String, dynamic> formattedPost = Map<String, dynamic>.from(response);

      // Ensure created_at is in the correct format
      if (formattedPost['created_at'] is! String) {
        formattedPost['created_at'] = DateTime.now().toIso8601String();
      }

      return PostModel.fromJson(formattedPost);
    } catch (e) {
      debugPrint('Error fetching post by ID: $e');
      return null;
    }
  }

  // Create a new post
  Future<PostModel?> createPost({
    required String userId,
    String? content,
    String? imageUrl,
    int? sportId,
  }) async {
    try {
      final data = {
        'id_user': userId,
        'content': content,
        'image_url': imageUrl,
        'id_sport': sportId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('post')
          .insert(data)
          .select()
          .withConverter((data) => data.isNotEmpty ? data.first : null);

      if (response == null) {
        return null;
      }

      Map<String, dynamic> formattedPost = Map<String, dynamic>.from(response);
      return PostModel.fromJson(formattedPost);
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  // Update a post
  Future<bool> updatePost({
    required String postId,
    required String userId, // to verify ownership
    String? content,
    String? imageUrl,
    int? sportId,
  }) async {
    try {
      // First verify the user owns the post
      final postCheck = await _supabase
          .from('post')
          .select()
          .match({'id_post': postId, 'id_user': userId})
          .limit(1)
          .withConverter((data) => data.isNotEmpty ? data.first : null);

      if (postCheck == null) {
        return false; // User does not own this post
      }

      // Prepare update data
      final updateData = <String, dynamic>{};
      if (content != null) updateData['content'] = content;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (sportId != null) updateData['id_sport'] = sportId;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('post')
          .update(updateData)
          .match({'id_post': postId});

      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId, String userId) async {
    try {
      // First verify the user owns the post
      final postCheck = await _supabase
          .from('post')
          .select()
          .match({'id_post': postId, 'id_user': userId})
          .limit(1)
          .withConverter((data) => data.isNotEmpty ? data.first : null);

      if (postCheck == null) {
        return false; // User does not own this post
      }

      // Delete the post
      await _supabase.from('post').delete().match({'id_post': postId});

      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comment')
          .select()
          .match({'id_post': postId})
          .order('created_at', ascending: true)
          .withConverter((data) => data);

      List<CommentModel> comments = [];
      for (final commentData in response) {
        try {
          Map<String, dynamic> formattedComment =
              Map<String, dynamic>.from(commentData);

          // Convert any timestamps to ISO format if needed
          if (formattedComment['created_at'] is! String) {
            formattedComment['created_at'] = DateTime.now().toIso8601String();
          }

          comments.add(CommentModel.fromJson(formattedComment));
        } catch (e) {
          debugPrint('Error processing comment: $e');
        }
      }

      return comments;
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  // Add a comment to a post
  Future<CommentModel?> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final data = {
        'id_post': postId,
        'id_user': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('comment')
          .insert(data)
          .select()
          .withConverter((data) => data.isNotEmpty ? data.first : null);

      if (response == null) {
        return null;
      }

      Map<String, dynamic> formattedComment =
          Map<String, dynamic>.from(response);
      return CommentModel.fromJson(formattedComment);
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId, String userId) async {
    try {
      // First verify the user owns the comment
      final commentCheck = await _supabase
          .from('comment')
          .select()
          .match({'id_comment': commentId, 'id_user': userId})
          .limit(1)
          .withConverter((data) => data.isNotEmpty ? data.first : null);

      if (commentCheck == null) {
        return false; // User does not own this comment
      }

      // Delete the comment
      await _supabase.from('comment').delete().match({'id_comment': commentId});

      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }
}
