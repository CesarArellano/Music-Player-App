import 'package:flutter/material.dart';
import 'package:focus_music_player/screens/screens.dart';

class AppRouter {
  static final Map<String, Widget Function(BuildContext)> routes = {
    'home': ( _ ) => const HomeScreen(),
  };

  static Route<dynamic> onGenerateRoute( RouteSettings settings ) {
    return MaterialPageRoute(
      builder: ( _ ) => const HomeScreen()
    );
  }

  /// Builds a route that slides the [page] up from the bottom when pushed and
  /// slides it back down when popped.
  static Route<T> slideUpRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      // Keep the route below painted for the whole transition. The app's
      // background is global (behind the Navigator) with transparent
      // scaffolds, so an opaque route leaves the page below offstage and the
      // slide would reveal only the bare background instead of the home screen.
      opaque: false,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),
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
          // Fade as well so the page below (kept painted by opaque:false) is
          // revealed *through* this screen as it leaves — without the fade its
          // opaque background just slides down and hides home until it clears.
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }
}