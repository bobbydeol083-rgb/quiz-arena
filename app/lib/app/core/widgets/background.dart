import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App-wide background: deep gradient + soft violet/cyan ambient glows.
/// Every screen sits on this so the "arena" feel is consistent.
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
            : const LinearGradient(
                colors: [AppColors.lightBg, Color(0xFFE9E6FA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: Stack(
        children: [
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
          child,
        ],
      ),
    );
  }
}
