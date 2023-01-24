import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class RippleTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const RippleTile({
    Key? key,
    required this.child,
    required this.onTap,
    this.onLongPress,
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