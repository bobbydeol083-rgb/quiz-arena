import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../values/app_values.dart';

/// Staggered entrance wrapper: fade + slide-up with an index-based delay.
/// Wrap list items / cards with an incrementing [index].
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration step;
  final double slideBegin;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.step = AppDurations.stagger,
    this.slideBegin = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: step * index)
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(
          begin: slideBegin,
          end: 0,
          duration: 450.ms,
          curve: AppCurves.entrance,
        );
  }
}

/// Animated integer counter (results screen score, stats, ...).
class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$prefix${v.round()}$suffix',
        style: style,
      ),
    );
  }
}

/// 🔥 streak indicator that pops with a spring every time the streak changes.
class StreakFlame extends StatelessWidget {
  final int streak;

  const StreakFlame({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak < 2) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(streak),
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, _) => Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: Colors.deepOrange.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'x$streak streak',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing live dot (online players, live quiz indicators).
class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, this.color = Colors.green, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.2,
      height: size * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(2.0, 2.0),
                duration: 900.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 900.ms),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
