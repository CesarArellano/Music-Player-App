import 'package:flutter/material.dart';

class Helpers {
  static final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  
  /// Builds a route that slides the [page] up from the bottom when pushed and
  /// slides it back down when popped.
  static Route<T> slideUpRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      // Keep the route below painted for the whole transition. The app's
      // background is global (behind the Navigator) with transparent
      // scaffolds, so an opaque route leaves the page below offstage and the
      // slide would reveal only the bare background instead of the home screen.
      opaque: false,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

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