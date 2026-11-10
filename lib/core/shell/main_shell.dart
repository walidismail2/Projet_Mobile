import 'package:flutter/material.dart';

import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/modules/alimentation/screens/food_screen.dart';
import 'package:flutter_example/modules/sante/screens/health_screen.dart';
import 'package:flutter_example/modules/animaux/screens/pets_list_screen.dart';
import 'package:flutter_example/modules/compte/screens/profile/profile_screen.dart';

/// 4 modules pour la validation (groupe de 4) :
/// 1. Animaux · 2. Santé · 3. Alimentation · 4. Compte (User)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      PetsListScreen(),
      HealthScreen(),
      FoodScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets_rounded),
              label: 'Animaux',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Santé',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Alimentation',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Compte',
            ),
          ],
        ),
      ),
    );
  }
}
