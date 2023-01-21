import 'package:flutter/material.dart';
import 'package:focus_music_player/providers/ui_provider.dart';
import 'package:provider/provider.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UIProvider uiProvider = Provider.of<UIProvider>(context);
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white30, width: 0.4))
      ),
      child: BottomNavigationBar(
        iconSize: 20,
        currentIndex: uiProvider.currentIndex,
        onTap: (newIndex) => uiProvider.currentIndex = newIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon( Icons.library_music_rounded ),
            activeIcon: Icon( Icons.library_music ), 
            label: 'Music',
          ),
          BottomNavigationBarItem(
            icon: Icon( Icons.settings_outlined ),
            activeIcon: Icon( Icons.settings ), 
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}