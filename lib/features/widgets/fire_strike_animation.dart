import 'package:flutter/material.dart';

class LightningStrikeThroughPainter extends CustomPainter {
  final double progress;

  LightningStrikeThroughPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Outer glow
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 8
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Electric core
    final electricPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.cyan, Colors.blue.shade300, Colors.purple.shade400],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(0, size.height / 2);
    final endPoint = Offset(size.width * progress, size.height / 2);

    // Draw glow
    canvas.drawLine(startPoint, endPoint, glowPaint);

    // Draw main line
    canvas.drawLine(startPoint, endPoint, electricPaint);

    // Add spark at the end
    if (progress > 0.1) {
      final sparkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, 3, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(LightningStrikeThroughPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
