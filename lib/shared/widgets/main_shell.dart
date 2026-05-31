import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Bottom-navigation shell hosting the four primary tabs. Uses go_router's
/// StatefulNavigationShell so each tab keeps its own navigation stack.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.home),
            selectedIcon: Icon(Symbols.home, fill: 1),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Symbols.chat_bubble),
            selectedIcon: Icon(Symbols.chat_bubble, fill: 1),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Symbols.person),
            selectedIcon: Icon(Symbols.person, fill: 1),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
