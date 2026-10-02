import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Shared difficulty picker bottom sheet.
///
/// Used by the Categories and Discover modules before launching a solo quiz.
class DifficultySheet {
  DifficultySheet._();

  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  static const _difficultyEmoji = {
    'Easy': '🌱',
    'Medium': '🔥',
    'Hard': '💀',
  };

  static void pick(QuizCategory category) {
    final isDark = Get.theme.brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.glassBorder
                  : AppColors.violetDeep.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    category.name,
                    style: Get.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pick your difficulty',
                style: TextStyle(
                  color: isDark
                      ? AppColors.adaptiveSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < _difficulties.length; i++)
                FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: GlassCard(
                      onTap: () => _start(category, _difficulties[i]),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Text(
                            _difficultyEmoji[_difficulties[i]]!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            _difficulties[i],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.adaptiveMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  static void _start(QuizCategory category, String difficulty) {
    Get.back();
    Get.toNamed(
      Routes.quiz,
      arguments: QuizArgs(
        mode: QuizMode.solo,
        categoryId: category.id,
        difficulty: difficulty.toLowerCase(),
      ),
    );
  }
}
