import 'package:flutter/material.dart';

class RippleTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  const RippleTile({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.borderRadius
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.white30,
              borderRadius: borderRadius,
              onTap: onTap,
              onLongPress: onLongPress,
            )
          ),
        )
      ],
    );
  }
}