import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed, // Mantiene los 5 íconos estables
        backgroundColor: isDarkMode ? const Color(0xFF1E2428) : Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.compass), label: 'Mercado'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.refreshCw), label: 'Trades'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.shoppingCart), label: 'Tienda'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.library), label: 'Colección'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
        ],
      ),
    );
  }
}