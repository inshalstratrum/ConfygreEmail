import 'package:flutter/material.dart';

class MyBottomNavBar extends StatelessWidget {
  void Function(int)? onTabChange;
  MyBottomNavBar({
    super.key,
    required this.onTabChange
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 70,
      elevation: 0,
      backgroundColor: const Color(0xFFF6F8FB),
      selectedIndex: 0,
      onDestinationSelected: (value) => onTabChange!(value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.clean_hands_rounded),
          selectedIcon: Icon(Icons.clean_hands_rounded, color: Color(0xFF496A8F)),
          label: 'Clean',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_rounded),
          selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF496A8F)),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_rounded),
          selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF496A8F)),
          label: 'Settings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF496A8F)),
          label: 'Profile',
        ),
      ],
    );
  }
}
