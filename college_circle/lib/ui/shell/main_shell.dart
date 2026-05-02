import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../screens/games_hub_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/profile_gallery_screen.dart';
import '../screens/today_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Сегодня'),
    NavigationDestination(icon: Icon(Icons.spa_rounded), label: 'Практика'),
    NavigationDestination(icon: Icon(Icons.games_rounded), label: 'Игры'),
    NavigationDestination(icon: Icon(Icons.face_retouching_natural_rounded), label: 'Вы'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_index) {
      case 0:
        page = const TodayScreen();
        break;
      case 1:
        page = const PracticeScreen();
        break;
      case 2:
        page = const GamesHubScreen();
        break;
      default:
        page = const ProfileGalleryScreen();
    }

    return Scaffold(
      body: pastelBackground(
        context,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(key: ValueKey<int>(_index), child: page),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (v) => setState(() => _index = v),
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}
