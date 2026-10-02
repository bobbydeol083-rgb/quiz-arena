import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_strings.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/modules/splash/controllers/splash_controller.dart';

/// Splash: gradient logo mark + Sora wordmark + tagline, no buttons.
/// Routes itself out after the controller's 2.4s boot window.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final taglineLines = AppStrings.tagline.split('\n');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArenaBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle pulsing violet glow behind the mark.
                    const PulsingDot(color: AppColors.violet, size: 56),
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet
                                .withValues(alpha: 0.55),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🧠',
                          style: TextStyle(fontSize: 56)),
                    )
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 500.ms),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeSlideIn(
                  index: 0,
                  child: Text(
                    'QuizArena',
                    style: text.displayLarge?.copyWith(fontSize: 40),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  index: 1,
                  child: Text(
                    taglineLines[0],
                    style: text.titleMedium?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FadeSlideIn(
                  index: 2,
                  child: Text(
                    taglineLines[1],
                    style: text.titleMedium?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
