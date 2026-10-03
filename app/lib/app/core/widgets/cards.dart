import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';
import '../values/app_values.dart';

/// Signature card used across the app: frosted glass on dark,
/// clean white with a soft blue shadow on light.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? AppInsets.card,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.glass
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? AppColors.glassBorder
                  : AppColors.lightBorder.withValues(alpha: 0.7),
              width: 1,
            ),
            gradient: isDark ? AppGradients.cardSheen : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppColors.blue.withValues(alpha: 0.10),
                blurRadius: isDark ? 24 : 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Shimmer skeleton for loading lists/cards.
class ShimmerCard extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ShimmerCard(
      {super.key, this.height = 96, this.borderRadius = AppRadius.lg});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceElevated : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade100,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const ShimmerList({super.key, this.count = 4, this.itemHeight = 96});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ShimmerCard(height: itemHeight),
        ),
      ),
    );
  }
}
