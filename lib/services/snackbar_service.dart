import 'package:flutter/material.dart';

import '../audio_player_handler.dart';

class SnackbarService {
  static SnackbarService get instance => audioPlayerHandler<SnackbarService>();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackbar({
    required String message,
    Color backgroundColor = const Color(0xFF303030),
    SnackBarAction? snackBarAction,
  }) {
    final state = scaffoldMessengerKey.currentState!;
    state.hideCurrentSnackBar();
    return state.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        action: snackBarAction,
      ),
    );
  }
}
