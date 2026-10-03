import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/exam_controller.dart';

/// Timed exam: 20 questions, 20 minutes, graded results.
class ExamView extends GetView<ExamController> {
  const ExamView({super.key});

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
                    EliteAssets.svg(EliteAssets.exam, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Exam mode', style: text.titleLarge),
                    const Spacer(),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: controller.secondsLeft.value < 120
                                ? AppColors.error
                                : AppColors.lightText,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Text(
                            controller.timeLabel,
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
                  if (controller.finished.value) return _result(context, text);
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
    final q = controller.questions[controller.index.value];
    return Padding(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress + question navigator dots.
          Obx(() => Column(
                children: [
                  LinearProgressIndicator(
                    value: controller.answers.length /
                        controller.questions.length,
                    backgroundColor: AppColors.borderOf(context),
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    minHeight: 8,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.questions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final current = i == controller.index.value;
                        final done =
                            controller.answers.containsKey(i);
                        return GestureDetector(
                          onTap: () => controller.jumpTo(i),
                          child: Container(
                            width: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: current
                                  ? AppColors.blue
                                  : done
                                      ? AppColors.blue
                                          .withValues(alpha: 0.2)
                                      : AppColors.softTintOf(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.borderOf(context)),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: text.labelLarge?.copyWith(
                                color: current
                                    ? Colors.white
                                    : AppColors.textPrimaryOf(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    child: Text(q.question, style: text.titleLarge),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...List.generate(q.options.length, (oi) {
                    final selected =
                        controller.answers[controller.index.value] == oi;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => controller.select(oi),
                        child: Container(
                          padding: AppInsets.card,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.blue.withValues(alpha: 0.14)
                                : AppColors.softTintOf(context),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: selected
                                  ? AppColors.blue
                                  : AppColors.borderOf(context),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Text(q.options[oi],
                              style: text.titleMedium),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                    label: 'Back', onPressed: controller.prev),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Obx(() => GradientButton(
                      label: controller.index.value + 1 >=
                              controller.questions.length
                          ? 'Finish exam'
                          : 'Next',
                      onPressed: () {
                        if (controller.index.value + 1 >=
                            controller.questions.length) {
                          _confirmFinish(context, text);
                        } else {
                          controller.next();
                        }
                      },
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  void _confirmFinish(BuildContext context, TextTheme text) {
    final unanswered =
        controller.questions.length - controller.answers.length;
    Get.dialog(
      AlertDialog(
        title: const Text('Finish exam?'),
        content: Text(unanswered > 0
            ? 'You still have $unanswered unanswered question(s). Submit anyway?'
            : 'Submit your exam for grading?'),
        actions: [
          TextButton(
              onPressed: Get.back, child: const Text('Review')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.finish();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _result(BuildContext context, TextTheme text) {
    final pct = (controller.accuracy * 100).toStringAsFixed(1);
    final pass = controller.accuracy >= 0.6;
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: pass ? AppGradients.sunny : AppGradients.primary,
            ),
            child: Text(
              controller.grade,
              style: text.displayLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            pass ? 'Exam passed!' : 'Keep practicing!',
            style: text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${controller.correctCount}/${controller.questions.length} correct · $pct%',
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(label: 'Retake exam', onPressed: controller.retake),
          const SizedBox(height: AppSpacing.sm),
          GhostButton(label: 'Back', onPressed: Get.back),
        ],
      ),
    );
  }
}
