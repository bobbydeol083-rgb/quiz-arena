import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_strings.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/modules/onboarding/controllers/onboarding_controller.dart';

class _OnboardPage {
  final String emoji;
  final String title;
  final String body;
  final Gradient glow;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.glow,
  });
}

const _pages = [
  _OnboardPage(
    emoji: '🎮',
    title: AppStrings.onboardTitle1,
    body: AppStrings.onboardBody1,
    glow: AppGradients.glowViolet,
  ),
  _OnboardPage(
    emoji: '🏆',
    title: AppStrings.onboardTitle2,
    body: AppStrings.onboardBody2,
    glow: AppGradients.glowCyan,
  ),
  _OnboardPage(
    emoji: '📍',
    title: AppStrings.onboardTitle3,
    body: AppStrings.onboardBody3,
    glow: AppGradients.glowViolet,
  ),
];

/// Three-page onboarding carousel with animated dots, skip, and a
/// Next / Get Started gradient CTA.
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArenaBackground(
        child: SafeArea(
          child: Padding(
            padding: AppInsets.screen,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: controller.skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) =>
                        _PageContent(page: _pages[index]),
                  ),
                ),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: AppDurations.normal,
                        curve: AppCurves.entrance,
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs),
                        width: controller.page.value == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          gradient: controller.page.value == i
                              ? AppGradients.primary
                              : null,
                          color: controller.page.value == i
                              ? null
                              : AppColors.adaptiveMuted
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Obx(
                  () => GradientButton(
                    label: controller.page.value < 2
                        ? 'Next'
                        : 'Get Started',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: controller.next,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Emoji art floating on a gradient blob.
        FadeSlideIn(
          index: 0,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: page.glow,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  page.emoji,
                  style: const TextStyle(fontSize: 96),
                ),
              ],
            ),
          ),
        ),
        FadeSlideIn(
          index: 1,
          child: Text(
            page.title,
            style: text.displaySmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideIn(
          index: 2,
          child: Text(
            page.body,
            style: text.bodyLarge?.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
