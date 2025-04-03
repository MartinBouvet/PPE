import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/chat_repository.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserPseudo;

  const ConversationScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserPseudo,
  }) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _authRepository = AuthRepository();
  final _chatRepository = ChatRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _userId;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupMessageRefresh();
  }

  void _setupMessageRefresh() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _refreshMessages();
        _setupMessageRefresh();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        await _refreshMessages();

        await _chatRepository.markConversationAsRead(
          widget.conversationId,
          _userId!,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await _chatRepository.getConversationMessages(
        widget.conversationId,
      );

      setState(() {
        _messages = messages;
      });

      if (_isFirstLoad && _messages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (_isFirstLoad) {
        setState(() {
          _errorMessage =
              'Erreur lors du chargement des messages: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _userId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatRepository.sendMessage(widget.conversationId, _userId!, text);
      _messageController.clear();
      await _refreshMessages();

      if (widget.otherUserPseudo == 'Elise') {
        await _simulateEliseReply(text);
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Aujourd\'hui ${DateFormat('HH:mm').format(dateTime)}';
    } else if (messageDate == yesterday) {
      return 'Hier ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  Future<void> _simulateEliseReply(String userMessage) async {
    await Future.delayed(const Duration(seconds: 1));

    String reply;
    final lowerMsg = userMessage.toLowerCase();

    if (lowerMsg.contains('bonjour') ||
        lowerMsg.contains('salut') ||
        lowerMsg.contains('hello') ||
        lowerMsg.contains('hey')) {
      reply = 'Hey ! Comment ça va aujourd\'hui ?';
    } else if (lowerMsg.contains('comment') &&
        (lowerMsg.contains('va') || lowerMsg.contains('vas'))) {
      reply = 'Ça va super bien, merci ! Et toi ?';
    } else if (lowerMsg.contains('bien') || lowerMsg.contains('super')) {
      reply =
          'Content de l\'entendre ! Tu veux faire du sport ensemble cette semaine ?';
    } else if (lowerMsg.contains('sport') ||
        lowerMsg.contains('tennis') ||
        lowerMsg.contains('foot') ||
        lowerMsg.contains('course')) {
      reply =
          'J\'adore le tennis et la course à pied. On pourrait organiser une session ensemble !';
    } else if (lowerMsg.contains('quand') ||
        lowerMsg.contains('date') ||
        lowerMsg.contains('jour') ||
        lowerMsg.contains('disponible')) {
      reply = 'Je suis libre samedi après-midi. Ça te convient ?';
    } else if (lowerMsg.contains('oui') ||
        lowerMsg.contains('ok') ||
        lowerMsg.contains('d\'accord') ||
        lowerMsg.contains('parfait')) {
      reply =
          'Super ! On se retrouve samedi à 14h au parc ? Je ramène les raquettes 🎾';
    } else if (lowerMsg.contains('merci')) {
      reply = 'Avec plaisir ! À très vite 😊';
    } else {
      reply =
          'Intéressant ! Tu veux qu\'on organise une session de sport ensemble bientôt ?';
    }

    const eliseId = '39dc52c6-6f4c-4d8c-b81b-d7105e160c9a';
    await _chatRepository.sendMessage(widget.conversationId, eliseId, reply);

    await _refreshMessages();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserPseudo)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserPseudo),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMessages,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    onPressed: _loadData,
                    tooltip: 'Réessayer',
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envoyez le premier message !',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _userId;

                      bool showDateSeparator = false;
                      if (index < _messages.length - 1) {
                        final currentDate = DateTime(
                          message.sentAt.year,
                          message.sentAt.month,
                          message.sentAt.day,
                        );
                        final nextDate = DateTime(
                          _messages[index + 1].sentAt.year,
                          _messages[index + 1].sentAt.month,
                          _messages[index + 1].sentAt.day,
                        );
                        showDateSeparator = currentDate != nextDate;
                      } else if (index == _messages.length - 1) {
                        showDateSeparator = true;
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatMessageTime(message.sentAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
