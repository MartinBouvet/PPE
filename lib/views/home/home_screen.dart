// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import '../match/match_screen.dart';
import '../facility/facility_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';
import '../social/social_screen.dart';
import '../social/friends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MatchScreen(), // Écran de découverte de partenaires sportifs
    const FacilityScreen(), // Écran de recherche d'installations sportives
    const SocialScreen(), // Écran de réseau social
    const ChatScreen(), // Écran de messages
    const ProfileScreen(), // Écran de profil
  ];

  final List<String> _titles = [
    'Découvrir',
    'Lieux',
    'Fil d\'actualité',
    'Messages',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Partenaires',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Lieux',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      appBar: _currentIndex == 2
          ? // Only show for the social tab
          AppBar(
              title: Text(_titles[_currentIndex]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.people),
                  tooltip: 'Amis',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FriendsScreen()),
                    );
                  },
                ),
              ],
            )
          : null,
    );
  }
}
