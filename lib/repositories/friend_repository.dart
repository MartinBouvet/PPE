// lib/repositories/friend_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class FriendRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<UserModel>> getUserFriends(String userId) async {
    try {
      // Get friend relationships where user is either friend1 or friend2
      final friendships = await _supabase
          .from('friendship')
          .select()
          .or('id_user1.eq.$userId,id_user2.eq.$userId')
          .eq('status', 'accepted');

      // Extract friend IDs (the other user in each relationship)
      List<String> friendIds = [];
      for (final friendship in friendships) {
        final String friendId = friendship['id_user1'] == userId
            ? friendship['id_user2']
            : friendship['id_user1'];
        friendIds.add(friendId);
      }

      if (friendIds.isEmpty) {
        return [];
      }

      // Get user data for all friends
      final friendUsers =
          await _supabase.from('app_user').select().in_('id', friendIds);

      return friendUsers
          .map<UserModel>((data) => UserModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user friends: $e');
      return [];
    }
  }

  Future<List<UserModel>> getFriendRequests(String userId) async {
    try {
      // Get pending friend requests where user is the recipient
      final requests = await _supabase
          .from('friendship')
          .select('*, app_user!friendship_id_user1_fkey(*)')
          .eq('id_user2', userId)
          .eq('status', 'pending');

      return requests
          .map<UserModel>((data) => UserModel.fromJson(data['app_user']))
          .toList();
    } catch (e) {
      debugPrint('Error fetching friend requests: $e');
      return [];
    }
  }

  Future<bool> sendFriendRequest(String senderId, String receiverId) async {
    try {
      // Check if a friendship already exists
      final existingFriendship = await _supabase
          .from('friendship')
          .select()
          .or('and(id_user1.eq.$senderId,id_user2.eq.$receiverId),and(id_user1.eq.$receiverId,id_user2.eq.$senderId)')
          .maybeSingle();

      if (existingFriendship != null) {
        // A relationship already exists
        final status = existingFriendship['status'];
        if (status == 'accepted') {
          return true; // Already friends
        } else if (status == 'pending') {
          // If the other user sent a request, accept it
          if (existingFriendship['id_user1'] == receiverId) {
            return await acceptFriendRequest(receiverId, senderId);
          }
          return true; // Request already sent
        }
        // If status is rejected, allow sending again
      }

      // Create new friendship request
      await _supabase.from('friendship').insert({
        'id_user1': senderId,
        'id_user2': receiverId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return false;
    }
  }

  Future<bool> acceptFriendRequest(String senderId, String receiverId) async {
    try {
      await _supabase
          .from('friendship')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user1', senderId)
          .eq('id_user2', receiverId)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  Future<bool> rejectFriendRequest(String senderId, String receiverId) async {
    try {
      await _supabase
          .from('friendship')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user1', senderId)
          .eq('id_user2', receiverId)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      return false;
    }
  }

  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      await _supabase.from('friendship').delete().or(
          'and(id_user1.eq.$userId,id_user2.eq.$friendId),and(id_user1.eq.$friendId,id_user2.eq.$userId)');

      return true;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }
}
