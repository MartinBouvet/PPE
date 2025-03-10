// lib/views/chat/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _authRepository = AuthRepository();
  final _messageController = TextEditingController();

  UserModel? _currentUser;
  GroupModel? _group;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  // Mock data for demonstration
  // In a real app, this would come from a repository
  late GroupModel _mockGroup;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentUser = await _authRepository.getCurrentUser();

      // Mock group data
      // In a real app, you would fetch this from a repository
      _mockGroup = GroupModel(
        id: widget.groupId,
        name: 'Groupe Tennis Paris 15',
        description: 'Groupe pour organiser des matchs de tennis dans le 15ème',
        photoUrl: null,
        members: [
          GroupMemberModel(
            userId: _currentUser?.id ?? 'user1',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 30)),
            user: _currentUser ?? UserModel(id: 'user1', pseudo: 'User1'),
          ),
          GroupMemberModel(
            userId: 'user2',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 25)),
            user: UserModel(id: 'user2', pseudo: 'Jean Tennis'),
          ),
          GroupMemberModel(
            userId: 'user3',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 20)),
            user: UserModel(id: 'user3', pseudo: 'Marie Raquette'),
          ),
        ],
      );

      setState(() {
        _group = _mockGroup;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du groupe: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isCurrentUserAdmin() {
    if (_currentUser == null || _group == null) {
      return false;
    }

    return _group!.members.any(
      (member) => member.userId == _currentUser!.id && member.role == 'admin',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du groupe')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du groupe')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Une erreur est survenue',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final bool isAdmin = _isCurrentUserAdmin();

    return Scaffold(
      appBar: AppBar(
        title: Text(_group!.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGroupScreen(group: _group!),
                  ),
                );

                if (result == true) {
                  _loadData();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdmin)
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Modifier le groupe'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditGroupScreen(group: _group!),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _loadData();
                              }
                            });
                          },
                        ),
                      if (isAdmin)
                        ListTile(
                          leading: const Icon(Icons.person_add),
                          title: const Text('Ajouter des membres'),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to add members screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Fonctionnalité à venir')),
                            );
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {},
                        ),
                        onTap: () {
                          // Toggle notification
                        },
                      ),
                      if (!isAdmin)
                        ListTile(
                          leading:
                              const Icon(Icons.exit_to_app, color: Colors.red),
                          title: const Text(
                            'Quitter le groupe',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Quitter le groupe'),
                                content: const Text(
                                  'Êtes-vous sûr de vouloir quitter ce groupe ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // TODO: Implement leave group functionality
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Fonctionnalité à venir'),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Quitter'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      if (isAdmin)
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text(
                            'Supprimer le groupe',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Supprimer le groupe'),
                                content: const Text(
                                  'Êtes-vous sûr de vouloir supprimer ce groupe ? Cette action est irréversible.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // TODO: Implement delete group functionality
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Fonctionnalité à venir'),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Group info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group photo
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: _group!.photoUrl != null
                      ? CachedNetworkImageProvider(_group!.photoUrl!)
                          as ImageProvider
                      : null,
                  child: _group!.photoUrl == null
                      ? Icon(Icons.group, size: 32, color: Colors.blue.shade700)
                      : null,
                ),
                const SizedBox(width: 16),
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _group!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_group!.members.length} membres',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (_group!.description != null) ...[
                        const SizedBox(height: 8),
                        Text(_group!.description!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Members section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Membres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Members list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _group!.members.length,
              itemBuilder: (context, index) {
                final member = _group!.members[index];
                final user = member.user;
                final isAdmin = member.role == 'admin';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: user.photo != null
                        ? CachedNetworkImageProvider(user.photo!)
                            as ImageProvider
                        : null,
                    child: user.photo == null ? const Icon(Icons.person) : null,
                  ),
                  title: Row(
                    children: [
                      Text(user.pseudo ?? 'Utilisateur inconnu'),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    'Depuis ${DateFormat.yMMMd().format(member.joinedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: _isCurrentUserAdmin() && user.id != _currentUser?.id
                      ? PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: isAdmin ? 'remove_admin' : 'make_admin',
                              child: ListTile(
                                leading: Icon(
                                  isAdmin
                                      ? Icons.person
                                      : Icons.admin_panel_settings,
                                  color: isAdmin ? Colors.red : Colors.blue,
                                ),
                                title: Text(
                                  isAdmin
                                      ? 'Retirer les droits d\'admin'
                                      : 'Faire admin',
                                  style: TextStyle(
                                    color: isAdmin ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(Icons.person_remove,
                                    color: Colors.red),
                                title: Text(
                                  'Retirer du groupe',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            // TODO: Implement member role change and removal
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Fonctionnalité à venir')),
                            );
                          },
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to add members screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
              child: const Icon(Icons.person_add),
              tooltip: 'Ajouter des membres',
            )
          : null,
    );
  }
}
