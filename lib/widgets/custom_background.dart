import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';

class CustomBackground extends StatelessWidget {
  const CustomBackground({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
    );
  }
}