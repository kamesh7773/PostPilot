import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../theme/app_colors.dart';

/// Slowly drifting colour blobs: the ambient background behind every screen.
class AuroraBackground extends HookWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final t = _useLoop(context, const Duration(seconds: 14));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = isDark ? 0.22 : 0.12;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Blob(
            color: AppColors.primary.withValues(alpha: alpha),
            center: Alignment(0.9 + 0.3 * cos(t), -1.0 + 0.3 * sin(t)),
            radius: 0.9,
          ),
          _Blob(
            color: AppColors.secondary.withValues(alpha: alpha * 0.8),
            center: Alignment(-1.0 + 0.3 * sin(t * 0.8), 1.0 + 0.3 * cos(t)),
            radius: 0.8,
          ),
        ],
      ),
    );
  }
}

/// A gradient card whose highlights drift: used for hero blocks.
class AuroraCard extends HookWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AuroraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final t = _useLoop(context, const Duration(seconds: 9));
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.gradient),
          child: Stack(
            children: [
              _Blob(
                color: Colors.white.withValues(alpha: 0.28),
                center: Alignment(cos(t), sin(t * 0.7)),
                radius: 1.1,
              ),
              _Blob(
                color: AppColors.accent.withValues(alpha: 0.35),
                center: Alignment(-sin(t * 0.8), cos(t)),
                radius: 0.9,
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing glow around [child] while [active]: "the AI is working on this".
class PulseGlow extends HookWidget {
  final Widget child;
  final bool active;
  final double radius;

  const PulseGlow({
    super.key,
    required this.child,
    required this.active,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1600),
    );
    final reduce = MediaQuery.disableAnimationsOf(context);
    useEffect(() {
      if (active && !reduce) {
        controller.repeat(reverse: true);
      } else {
        controller.stop();
      }
      return null;
    }, [active, reduce]);
    if (!active) return child;
    final value = useAnimation(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2 + 0.35 * value),
            blurRadius: 18 + 14 * value,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 0..2π, looping; frozen when the user has animations turned off.
double _useLoop(BuildContext context, Duration period) {
  final controller = useAnimationController(duration: period);
  final reduce = MediaQuery.disableAnimationsOf(context);
  useEffect(() {
    if (reduce) {
      controller.stop();
    } else {
      controller.repeat();
    }
    return null;
  }, [reduce]);
  return useAnimation(controller) * 2 * pi;
}

class _Blob extends StatelessWidget {
  final Color color;
  final Alignment center;
  final double radius;

  const _Blob({
    required this.color,
    required this.center,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
