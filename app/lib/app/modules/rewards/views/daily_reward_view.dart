import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:scratcher/scratcher.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/daily_reward_controller.dart';

/// Daily scratch-card reward: scratch to reveal today's coin prize.
class DailyRewardView extends GetView<DailyRewardController> {
  const DailyRewardView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final confetti = ConfettiController(duration: const Duration(seconds: 2));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArenaBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context, text),
              Expanded(
                child: Obx(() {
                  if (controller.checking.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!controller.canClaim.value && !controller.revealed.value) {
                    return _claimedState(context, text);
                  }
                  return _scratchState(context, text, confetti);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, TextTheme text) {
    return Padding(
      padding: AppInsets.screen,
      child: Row(
        children: [
          ArenaIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: Get.back,
          ),
          const SizedBox(width: AppSpacing.md),
          Text('Daily reward', style: text.titleLarge),
        ],
      ),
    );
  }

  Widget _claimedState(BuildContext context, TextTheme text) {
    return Center(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EliteAssets.svg(EliteAssets.dailyCoins, size: 96),
            const SizedBox(height: AppSpacing.lg),
            Text('Already claimed!', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your scratch card was claimed today.\nCome back tomorrow for another shot.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.error.value.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                controller.error.value,
                style: text.bodySmall?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scratchState(
      BuildContext context, TextTheme text, ConfettiController confetti) {
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        children: [
          Text(
            'Scratch the card to reveal\ntoday\u2019s prize!',
            style: text.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(() {
            if (controller.revealed.value) {
              confetti.play();
              return _revealedCard(context, text);
            }
            return Scratcher(
              brushSize: 42,
              threshold: 45,
              image: Image.asset(EliteAssets.scratchCover, fit: BoxFit.cover),
              onThreshold: controller.claim,
              child: _prizeFace(context, text),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Obx(() => controller.claiming.value
              ? const CircularProgressIndicator()
              : controller.error.value.isNotEmpty
                  ? Text(
                      controller.error.value,
                      style: text.bodySmall?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox.shrink()),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
            ),
          ),
        ],
      ),
    );
  }

  /// The hidden prize face under the scratch cover.
  Widget _prizeFace(BuildContext context, TextTheme text) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: AppGradients.sunny,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Center(
        child: Obx(() => controller.claiming.value
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EliteAssets.svg(EliteAssets.coin, size: 64),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '?',
                    style: text.displayLarge?.copyWith(color: Colors.white),
                  ),
                  Text(
                    'coins inside!',
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              )),
      ),
    );
  }

  Widget _revealedCard(BuildContext context, TextTheme text) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: AppGradients.sunny,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.sun.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 120,
              child: Lottie.asset(EliteAssets.successLottie, repeat: false),
            ),
            Text(
              '+${controller.awarded.value} coins!',
              style: text.displaySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
