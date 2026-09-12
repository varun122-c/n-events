import 'dart:math' as math;
import 'package:flutter/material.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({super.key, this.size = 22.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double outerRadius = w / 2;
    final double strokeWidth = w * 0.22;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final Rect rect = Rect.fromCircle(center: center, radius: outerRadius - (strokeWidth / 2));

    // 1. Red (Top Arc)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.72, math.pi * 0.48, false, paint);

    // 2. Yellow (Left Arc)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -math.pi * 1.25, math.pi * 0.53, false, paint);

    // 3. Green (Bottom Arc)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.52, false, paint);

    // 4. Blue (Right Arc & Bar)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.24, math.pi * 0.49, false, paint);

    // Draw horizontal Blue bar extending to the center
    final Paint fillBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final double barHeight = strokeWidth * 0.95;
    final Rect barRect = Rect.fromLTWH(
      center.dx,
      center.dy - (barHeight / 2),
      outerRadius,
      barHeight,
    );
    canvas.drawRect(barRect, fillBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
