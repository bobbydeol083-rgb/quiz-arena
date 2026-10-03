import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/modules/duel/controllers/duel_controller.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Duel lobby: category picker, matchmaking radar, how-it-works, nearby link.
class DuelView extends GetView<DuelController> {
  const DuelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duel')),
      body: ArenaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pick your arena',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                _categoryChips(),
                const SizedBox(height: AppSpacing.xl),
                Obx(
                  () => controller.searching.value
                      ? _radarCard()
                      : GradientButton(
                          label: 'Find Match',
                          icon: Icons.bolt_rounded,
                          onPressed: controller.startMatchmaking,
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _howItWorks(),
                const SizedBox(height: AppSpacing.xl),
                GhostButton(
                  label: 'Invite a nearby friend',
                  icon: Icons.people_outline_rounded,
                  onPressed: () => Get.toNamed(Routes.nearby),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return Obx(
      () => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final c in controller.categories)
            ChoiceChip(
              label: Text('${c.icon} ${c.name}'),
              selected: controller.selectedCategory.value == c.id,
              onSelected: (_) => controller.selectedCategory.value = c.id,
              selectedColor: AppColors.blue.withValues(alpha: 0.18),
              backgroundColor: AppColors.adaptiveElevated,
              labelStyle: TextStyle(
                color: AppColors.adaptivePrimary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: controller.selectedCategory.value == c.id
                    ? AppColors.blue
                    : AppColors.adaptiveBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }

  Widget _radarCard() {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          const PulsingDot(color: AppColors.violet, size: 26),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Searching for an opponent…',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.adaptivePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(
            () => Text(
              'Category: ${controller.categoryName}',
              style: TextStyle(color: AppColors.adaptiveSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GhostButton(
            label: 'Cancel',
            onPressed: controller.cancel,
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    const steps = [
      ('1', 'Pick a category and hit Find Match.'),
      ('2', 'We pair you with a rival of similar skill.'),
      ('3', 'Answer 10 questions — highest score wins!'),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.adaptivePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (num, text) in steps) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    num,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: AppColors.adaptiveSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            if (num != '3') const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
