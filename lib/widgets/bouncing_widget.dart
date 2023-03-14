import 'package:flutter/material.dart';

class Bouncing extends StatefulWidget {
  final Widget child;

  const Bouncing({
    Key? key,
    required this.child,
  }): super(key: key);

  @override
  State<Bouncing> createState() => _BouncingState();
}

class _BouncingState extends State<Bouncing> with SingleTickerProviderStateMixin {
  double _scale = 1;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _controller.addListener(() {
      setState(() {
        _scale = 1 - _controller.value;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        _controller.forward();
      },
      onPointerUp: (PointerUpEvent event) {
        _controller.reverse();
      },
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}