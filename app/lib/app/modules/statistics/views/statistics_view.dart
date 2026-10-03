import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/statistics_controller.dart';

/// Rich statistics dashboard with Elite iconography.
class StatisticsView extends GetView<StatisticsController> {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = controller.progress.progress.value;
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
                      icon: Icons.arrow_back_rounded,
                      onPressed: Get.back,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    EliteAssets.svg(EliteAssets.statistics, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Statistics', style: text.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppInsets.screen,
                  child: Column(
                    children: [
                      _rings(context, text, p),
                      const SizedBox(height: AppSpacing.lg),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.35,
                        children: [
                          _tile(context, text, EliteAssets.score,
                              '${p.totalQuizzes}', 'quizzes played'),
                          _tile(context, text, EliteAssets.correct,
                              '${p.totalCorrect}', 'correct answers'),
                          _tile(context, text, EliteAssets.badges,
                              'x${p.bestStreak}', 'best streak'),
                          _tile(context, text, EliteAssets.dailyQuiz,
                              '${p.dailyStreak}d', 'daily streak'),
                          _tile(context, text, EliteAssets.versus,
                              '${p.duelsWon}', 'duels won'),
                          _tile(context, text, EliteAssets.coin,
                              '${controller.auth.currentUser.value?.coins ?? 0}',
                              'coin balance'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rings(BuildContext context, TextTheme text, p) {
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ring(
            context,
            text,
            controller.accuracy,
            '${(controller.accuracy * 100).toStringAsFixed(0)}%',
            'accuracy',
            AppColors.blue,
          ),
          _ring(
            context,
            text,
            controller.winRate,
            '${(controller.winRate * 100).toStringAsFixed(0)}%',
            'win rate',
            AppColors.sun,
          ),
        ],
      ),
    );
  }

  Widget _ring(BuildContext context, TextTheme text, double value,
      String label, String caption, Color color) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 64,
          lineWidth: 12,
          percent: value.clamp(0.0, 1.0),
          center: Text(label, style: text.titleLarge),
          progressColor: color,
          backgroundColor: AppColors.borderOf(context),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          caption,
          style: text.bodySmall?.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, TextTheme text, String icon,
      String value, String label) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EliteAssets.svg(icon, size: 30),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: text.titleLarge),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
