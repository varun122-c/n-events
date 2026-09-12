import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Returns a [CustomTransitionPage] with smooth fade, slide, and subtle scale transition.
CustomTransitionPage<void> buildAnimatedPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 350),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curveAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curveAnimation);
      final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(curveAnimation);
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.03),
        end: Offset.zero,
      ).animate(curveAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        ),
      );
    },
  );
}
