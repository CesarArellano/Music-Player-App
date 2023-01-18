import 'package:flutter/material.dart';

void showSnackbar({
  required BuildContext context,
  required String message,
  Color backgroundColor = const Color(0xFF303030),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        backgroundColor: backgroundColor,
        content: Text(message,
        style: const TextStyle(color: Colors.white)
      )
    )
  );
}