import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiParticles extends StatefulWidget {
  final VoidCallback? onFinished;

  const ConfettiParticles({super.key, this.onFinished});

  @override
  State<ConfettiParticles> createState() => _ConfettiParticlesState();
}

class _ConfettiParticlesState extends State<ConfettiParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final size = MediaQuery.of(context).size;
      final centerX = size.width / 2;
      final centerY = size.height / 2;

      final colors = [
        Colors.pinkAccent,
        Colors.blueAccent,
        Colors.greenAccent,
        Colors.amberAccent,
        Colors.purpleAccent,
        Colors.deepOrangeAccent,
        Colors.cyanAccent,
        Colors.tealAccent
      ];

      for (int i = 0; i < 90; i++) {
        // Upwards spraying arc angle
        final angle = -pi / 6 - _random.nextDouble() * (2 * pi / 3); // -30 to -150 degrees
        final speed = 4.0 + _random.nextDouble() * 12.0;

        _particles.add(
          Particle(
            x: centerX,
            y: centerY - 50,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            color: colors[_random.nextInt(colors.length)],
            size: 4.0 + _random.nextDouble() * 8.0,
            rotation: _random.nextDouble() * 2 * pi,
            rotationSpeed: -0.1 + _random.nextDouble() * 0.2,
            isSquare: _random.nextBool(),
          ),
        );
      }

      _controller.forward().then((_) {
        if (mounted && widget.onFinished != null) {
          widget.onFinished!();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          for (var p in _particles) {
            p.x += p.vx;
            p.y += p.vy;
            p.vy += 0.28; // Gravity acceleration
            p.vx *= 0.98; // Air resistance coefficient
            p.rotation += p.rotationSpeed;
          }

          return CustomPaint(
            size: Size.infinite,
            painter: ConfettiPainter(_particles),
          );
        },
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  bool isSquare;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isSquare,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      if (p.x < 0 || p.x > size.width || p.y > size.height) continue;

      paint.color = p.color;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.isSquare) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
