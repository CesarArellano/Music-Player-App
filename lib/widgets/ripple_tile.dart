import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class RippleTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  const RippleTile({
    Key? key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.borderRadius
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Stack(
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
      ),
    );
  }
}