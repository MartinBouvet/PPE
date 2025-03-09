// lib/views/chat/chat_screen.dart
import 'package:flutter/material.dart';
import '../../models/conversation_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/chat_repository.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _authRepository = AuthRepository();
  final _chatRepository = ChatRepository();

  String? _userId;
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _userId = user.id;
        _conversations = await _chatRepository.getUserConversations(_userId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes messages')),
      body:
          _conversations.isEmpty
              ? const Center(child: Text('Aucune conversation'))
              : ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return ListTile(
                    leading:
                        conversation.otherUserPhoto != null
                            ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                conversation.otherUserPhoto!,
                              ),
                            )
                            : CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                color: Colors.blue.shade800,
                              ),
                            ),
                    title: Text(
                      conversation.otherUserPseudo ?? 'Utilisateur inconnu',
                    ),
                    subtitle:
                        conversation.lastMessage != null
                            ? Text(
                              conversation.lastMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                            : null,
                    trailing:
                        conversation.unreadCount > 0
                            ? CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                            : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => ConversationScreen(
                                conversationId: conversation.id,
                                otherUserPseudo:
                                    conversation.otherUserPseudo ??
                                    'Utilisateur inconnu',
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
