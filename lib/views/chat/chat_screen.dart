import 'package:flutter/material.dart';
import '../../models/conversation_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/chat_repository.dart';
import '../../services/elise_service.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _authRepository = AuthRepository();
  final _chatRepository = ChatRepository();
  final _eliseService = EliseService();

  String? _userId;
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _userId = user.id;

        // Ensure Elise contact is initialized
        await _eliseService.initializeEliseContact();

        // Get conversations
        _conversations = await _chatRepository.getUserConversations(_userId!);
      } else {
        setState(() {
          _errorMessage =
              'Vous devez être connecté pour accéder à cette fonctionnalité';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
      debugPrint('ChatScreen error: $e');
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
      appBar: AppBar(
        title: const Text('Mes messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : _conversations.isEmpty
              ? const Center(child: Text('Aucune conversation'))
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    return ListTile(
                      leading: conversation.otherUserPhoto != null
                          ? CircleAvatar(
                              backgroundImage:
                                  NetworkImage(conversation.otherUserPhoto!),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.person,
                                  color: Colors.blue.shade800),
                            ),
                      title: Text(
                        conversation.otherUserPseudo ?? 'Utilisateur inconnu',
                      ),
                      subtitle: conversation.lastMessage != null
                          ? Text(
                              conversation.lastMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: conversation.unreadCount > 0
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
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                  conversationId: conversation.id,
                                  otherUserPseudo:
                                      conversation.otherUserPseudo ??
                                          'Utilisateur inconnu',
                                ),
                              ),
                            )
                            .then((_) => _loadData());
                      },
                    );
                  },
                ),
      floatingActionButton: _userId != null
          ? FloatingActionButton(
              onPressed: () async {
                // Create conversation with Elise if not already exists
                final eliseConvId =
                    await _chatRepository.createConversationWithElise(_userId!);
                if (mounted && eliseConvId != null) {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                            conversationId: eliseConvId,
                            otherUserPseudo: 'Elise',
                          ),
                        ),
                      )
                      .then((_) => _loadData());
                }
              },
              tooltip: 'Discuter avec Elise',
              child: const Icon(Icons.chat),
            )
          : null,
    );
  }
}
