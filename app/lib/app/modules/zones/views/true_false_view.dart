import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/true_false_controller.dart';

/// True/False speed zone: 10 statements, 10 seconds each.
class TrueFalseView extends GetView<TrueFalseController> {
  const TrueFalseView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArenaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: AppInsets.screen,
                child: Row(
                  children: [
                    ArenaIconButton(
                      icon: Icons.close_rounded,
                      onPressed: Get.back,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    EliteAssets.svg(EliteAssets.trueFalse, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text('True / False', style: text.titleLarge),
                    const Spacer(),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Text(
                            '${controller.score.value} pts',
                            style: text.labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.finished.value) {
                    return _result(context, text);
                  }
                  return _play(context, text);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _play(BuildContext context, TextTheme text) {
    return Padding(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Q ${controller.index.value + 1}/${controller.statements.length}',
                    style: text.labelLarge?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (controller.streak.value >= 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppGradients.sunny,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '🔥 x${controller.streak.value}',
                        style: text.labelLarge
                            ?.copyWith(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              )),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => TimerRing(
                progress: controller.secondsLeft.value /
                    TrueFalseController.secondsPerStatement,
                secondsLeft: controller.secondsLeft.value,
              )),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Obx(() {
              final answered = controller.answered.value;
              final correct = controller.lastCorrect.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: answered
                      ? Border.all(
                          color: correct
                              ? AppColors.successOf(context)
                              : AppColors.error,
                          width: 3,
                        )
                      : null,
                ),
                child: GlassCard(
                  child: Center(
                    child: Padding(
                      padding: AppInsets.card,
                      child: Text(
                        controller.current.statement,
                        style: text.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _answerButton(
                      context,
                      text,
                      label: 'FALSE',
                      color: AppColors.error,
                      enabled: !controller.answered.value,
                      onTap: controller.answerFalse,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _answerButton(
                      context,
                      text,
                      label: 'TRUE',
                      color: AppColors.successOf(context),
                      enabled: !controller.answered.value,
                      onTap: controller.answerTrue,
                    ),
                  ),
                ],
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _answerButton(
    BuildContext context,
    TextTheme text, {
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            label,
            style: text.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _result(BuildContext context, TextTheme text) {
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          EliteAssets.svg(EliteAssets.score, size: 96),
          const SizedBox(height: AppSpacing.lg),
          Text('Zone complete!', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => Text(
                '${controller.score.value} points',
                style: text.displaySmall,
              )),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            label: 'Play again',
            onPressed: controller.playAgain,
          ),
          const SizedBox(height: AppSpacing.sm),
          GhostButton(label: 'Back', onPressed: Get.back),
        ],
      ),
    );
  }
}
