import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/level_config.dart';
import '../values/app_values.dart';

/// Animated XP bar with a level badge. Animates from the previous XP to the
/// new XP so level-ups sweep visibly across the bar.
class XpProgressBar extends StatelessWidget {
  final int xp;
  final int? fromXp;
  final bool showLabel;
  final double height;

  const XpProgressBar({
    super.key,
    required this.xp,
    this.fromXp,
    this.showLabel = true,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    final level = LevelConfig.levelForXp(xp);
    final tier = LevelConfig.tierForLevel(level);
    final tierColor = LevelConfig.tierColorForLevel(level);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = (fromXp ?? xp).clamp(0, 1 << 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tierColor, tierColor.withValues(alpha: 0.55)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'LV $level · $tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${LevelConfig.xpToNext(xp)} XP to next',
                style: TextStyle(
                  color: isDark
                      ? AppColors.adaptiveSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        if (showLabel) const SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          tween: Tween(
            begin: LevelConfig.progress(start),
            end: LevelConfig.progress(xp),
          ),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.02, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated countdown ring for quiz questions.
class TimerRing extends StatelessWidget {
  /// 1.0 = full time left, 0.0 = expired.
  final double progress;
  final int secondsLeft;
  final double size;
  final double strokeWidth;

  const TimerRing({
    super.key,
    required this.progress,
    required this.secondsLeft,
    this.size = 64,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final urgent = p < 0.25;
    final color = urgent
        ? AppColors.error
        : p < 0.5
            ? AppColors.warning
            : AppColors.cyan;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: p,
              color: color,
              trackColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              strokeWidth: strokeWidth,
            ),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              color: urgent
                  ? AppColors.error
                  : (isDark
                      ? AppColors.adaptivePrimary
                      : AppColors.lightText),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
