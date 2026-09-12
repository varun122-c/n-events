import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure animated glowing Ñ brand emblem loading indicator with dual counter-rotating rings.
class NLoadingIndicator extends StatefulWidget {
  final double size;

  const NLoadingIndicator({
    super.key,
    this.size = 84,
  });

  @override
  State<NLoadingIndicator> createState() => _NLoadingIndicatorState();
}

class _NLoadingIndicatorState extends State<NLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _counterSpinController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _counterSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 18.0, end: 32.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _counterSpinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final innerRingSize = widget.size * 0.82;
    final badgeSize = widget.size * 0.64;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer clockwise spinning gradient ring
                RotationTransition(
                  turns: _spinController,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF818CF8),
                      ),
                      backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // Inner counter-clockwise spinning ring
                AnimatedBuilder(
                  animation: _counterSpinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_counterSpinController.value * 2 * math.pi,
                      child: SizedBox(
                        width: innerRingSize,
                        height: innerRingSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFC084FC),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    );
                  },
                ),

                // Center glowing Ñ emblem badge
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF7C3AED),
                          Color(0xFFC084FC),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.55),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                          blurRadius: _glowAnimation.value * 1.5,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Ñ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

