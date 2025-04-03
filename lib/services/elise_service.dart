import 'package:flutter/foundation.dart';
import '../repositories/chat_repository.dart';
import '../repositories/auth_repository.dart';

class EliseService {
  final ChatRepository _chatRepository = ChatRepository();
  final AuthRepository _authRepository = AuthRepository();

  Future<void> initializeEliseContact() async {
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        debugPrint('No user logged in, cannot setup Elise conversation');
        return;
      }

      await _chatRepository.addEliseAsFriend(currentUser.id);
      final conversationId =
          await _chatRepository.createConversationWithElise(currentUser.id);

      debugPrint('Initialized conversation with Elise: $conversationId');
    } catch (e) {
      debugPrint('Error initializing Elise contact: $e');
    }
  }
}
