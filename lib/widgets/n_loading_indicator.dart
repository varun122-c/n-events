import 'package:flutter/material.dart';

/// Pure animated glowing Ñ brand emblem loading indicator.
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = widget.size * 0.72;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer spinning gradient arc ring
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
                  backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                ),
              ),
            ),

            // Center glowing Ñ emblem badge
            ScaleTransition(
              scale: _pulseAnimation,
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Ñ',
                    style: TextStyle(
                      fontSize: 28,
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
      ),
    );
  }
}
