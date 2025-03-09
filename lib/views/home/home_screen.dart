// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import '../discover/discover_screen.dart';
import '../facility/facility_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DiscoverScreen(), // Écran de swipe pour découvrir des sportifs
    const FacilityScreen(), // Écran de recherche d'installations sportives
    const ChatScreen(), // Écran de messages
    const ProfileScreen(), // Écran de profil
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
            icon: Icon(Icons.explore),
            label: 'Découvrir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Lieux',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
