import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomIconTextButton extends StatelessWidget {
  const CustomIconTextButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(2.5) ),
        backgroundColor: AppTheme.lightTextColor.withOpacity(0.15),
      ),
      icon: Icon(icon, color: AppTheme.lightTextColor),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}