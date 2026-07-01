import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScrollToTopButton extends StatelessWidget {
  final void Function()? onPressed;
  final bool isVisible;
  
  const ScrollToTopButton({super.key, this.onPressed, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor:
                  AppTheme.black.withValues(alpha: 0.5),
            ),
            color: AppTheme.white,
            icon: const Icon(Icons.arrow_upward_rounded),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}