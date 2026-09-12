import 'package:flutter/material.dart';

/// Deterministic four-point sparkle used by the Companion Home Figma recipe.
final class ChromeKissSparkle extends StatelessWidget {
  const ChromeKissSparkle({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklePainter(color));
  }
}

final class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final path = Path()
      ..moveTo(center.dx, 0)
      ..cubicTo(
        center.dx + size.width * 0.06,
        center.dy - size.height * 0.08,
        center.dx + size.width * 0.08,
        center.dy - size.height * 0.06,
        size.width,
        center.dy,
      )
      ..cubicTo(
        center.dx + size.width * 0.08,
        center.dy + size.height * 0.06,
        center.dx + size.width * 0.06,
        center.dy + size.height * 0.08,
        center.dx,
        size.height,
      )
      ..cubicTo(
        center.dx - size.width * 0.06,
        center.dy + size.height * 0.08,
        center.dx - size.width * 0.08,
        center.dy + size.height * 0.06,
        0,
        center.dy,
      )
      ..cubicTo(
        center.dx - size.width * 0.08,
        center.dy - size.height * 0.06,
        center.dx - size.width * 0.06,
        center.dy - size.height * 0.08,
        center.dx,
        0,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => color != oldDelegate.color;
}
