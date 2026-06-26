import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _AppBackgroundPainter(),
        child: child,
      );
}

class _AppBackgroundPainter extends CustomPainter {
  const _AppBackgroundPainter();

  static const _base = Color(0xFF0C1D30);

  // Each entry: (cx%, cy%, radius as % of width, ARGB color)
  static const _blobs = [
    (0.48, 0.38, 0.85, Color(0x701B4070)), // large centre glow
    (0.14, 0.58, 0.55, Color(0x501A3A68)), // left-centre
    (0.82, 0.60, 0.55, Color(0x501A3A68)), // right-centre
    (0.52, 0.88, 0.55, Color(0x40173568)), // bottom
    (0.26, 0.14, 0.45, Color(0x42183A68)), // upper-left
    (0.74, 0.18, 0.42, Color(0x36173568)), // upper-right
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint()..color = _base);
    for (final (cx, cy, r, color) in _blobs) {
      _drawBlob(canvas, size, cx, cy, r, color);
    }
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double r,
    Color color,
  ) {
    final center = Offset(size.width * cx, size.height * cy);
    final radius = size.width * r;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
