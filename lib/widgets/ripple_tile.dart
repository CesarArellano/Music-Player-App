import 'package:flutter/material.dart';

class RippleTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const RippleTile({
    Key? key,
    required this.child,
    required this.onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
            )
          ),
        )
      ],
    );
  }
}