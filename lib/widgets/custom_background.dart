import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';

class CustomBackground extends StatelessWidget {
  const CustomBackground({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00254F),
            AppTheme.primaryColor
          ]
        )
      ),
    );
  }
}