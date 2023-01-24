import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackbar({
  required BuildContext context,
  required String message,
  Color backgroundColor = const Color(0xFF303030),
  SnackBarAction? snackBarAction
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: backgroundColor,
      content: Text(message, style: const TextStyle(color: Colors.white)),
      action: snackBarAction,
    )
  );
}