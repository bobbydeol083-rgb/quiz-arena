import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App-wide background: sky-blue daylight canvas with soft blooms in
/// light mode, deep gradient + neon glows in dark mode.
class ArenaBackground extends StatelessWidget {
  final Widget child;

  const ArenaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppGradients.darkBackground
            : AppGradients.lightBackground,
      ),
      child: Stack(
        children: [
          if (isDark) ...[
            // Ambient violet glow — top left.
            Positioned(
              top: -120,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  gradient: AppGradients.glowViolet,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Ambient cyan glow — bottom right.
            Positioned(
              bottom: -140,
              right: -100,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  gradient: AppGradients.glowCyan,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ] else ...[
            // Soft daylight bloom — top.
            Positioned(
              top: -140,
              left: -80,
              child: Container(
                width: 360,
                height: 360,
                decoration: const BoxDecoration(
                  gradient: AppGradients.glowSky,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Warm sun kiss — bottom right.
            Positioned(
              bottom: -160,
              right: -120,
              child: Container(
                width: 380,
                height: 380,
                decoration: const BoxDecoration(
                  gradient: AppGradients.glowSun,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}
