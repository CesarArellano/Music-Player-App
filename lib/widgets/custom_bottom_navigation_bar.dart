import 'package:flutter/material.dart';
import 'package:music_player_app/providers/ui_provider.dart';
import 'package:provider/provider.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UIProvider uiProvider = Provider.of<UIProvider>(context);
    return NavigationBar(
      height: 65,
      selectedIndex: uiProvider.currentIndex,
      onDestinationSelected: (newIndex) => uiProvider.currentIndex = newIndex,
      destinations: const [
        NavigationDestination(
          icon: Icon( Icons.library_music_outlined ),
          selectedIcon: Icon( Icons.library_music ), 
          label: 'Music',
        ),
        NavigationDestination(
          icon: Icon( Icons.settings_outlined ),
          selectedIcon: Icon( Icons.settings ), 
          label: 'Settings',
        ),
      ],
    );
  }
}