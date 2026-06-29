import 'package:flutter/material.dart';

class Helpers {
  static final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackbar({
    required String message,
    Color backgroundColor = const Color(0xFF303030),
    SnackBarAction? snackBarAction
  }) {
    scaffoldKey.currentState!.hideCurrentSnackBar();
    return scaffoldKey.currentState!.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        action: snackBarAction,
      )
    );
  }
}