import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/modules/modes/controllers/modes_controller.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

class ModesView extends GetView<ModesController> {
  const ModesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Choose your battle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: ArenaBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: AppInsets.screen.copyWith(bottom: 40),
            children: [
              FadeSlideIn(index: 0, child: _streakCard(context)),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0;
                  i < controller.modes.length;
                  i++) ...[
                FadeSlideIn(
                  index: i + 1,
                  child: _ModeCard(
                    mode: controller.modes[i],
                    onTap: () =>
                        controller.playMode(controller.modes[i]),
                  ),
                ),
                if (i < controller.modes.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                index: controller.modes.length + 1,
                child: _PacksCard(),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                index: controller.modes.length + 2,
                child: _ZonesSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _streakCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final streak = controller.dailyStreak;
      return GlassCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: const Text(
                '📅',
                style: TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak-day streak',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak > 0
                        ? 'Keep it burning — play today\'s set'
                        : 'Start your streak with today\'s set',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.adaptiveSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GradientButton(
              label: 'Play',
              height: 44,
              borderRadius: AppRadius.pill,
              onPressed: () => controller.playMode(QuizMode.daily),
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ModeCard extends StatelessWidget {
  final QuizMode mode;
  final VoidCallback onTap;

  const _ModeCard({required this.mode, required this.onTap});

  bool get _highlighted => mode == QuizMode.solo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              mode.emoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mode.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (mode == QuizMode.duel) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.success
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PulsingDot(
                                color: AppColors.success, size: 8),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'ONLINE',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mode.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.adaptiveSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.adaptiveMuted,
          ),
        ],
      ),
    );
    if (!_highlighted) return card;
    // Solo gets a gradient border to mark it as the default pick.
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(1.6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg - 1.6),
        ),
        child: card,
      ),
    );
  }
}

/// Entry point to community game packs: install and play custom games,
/// or publish your own.
class _PacksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => Get.toNamed(Routes.packs),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: const Text(
              '📦',
              style: TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Packs',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'Play community-made games — or publish your own.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// New zones & rewards harvested from the Elite Quiz pack.
class _ZonesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zones & rewards', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        const _ZoneTile(
          icon: EliteAssets.trueFalse,
          title: 'True / False',
          subtitle: '10 rapid-fire statements, 10s each',
          route: Routes.trueFalse,
        ),
        const _ZoneTile(
          icon: EliteAssets.versus,
          title: 'Contests',
          subtitle: 'Timed prize contests — real coin rewards',
          route: Routes.contest,
        ),
        const _ZoneTile(
          icon: EliteAssets.exam,
          title: 'Exam mode',
          subtitle: '20 questions, 20 minutes, graded A+ to F',
          route: Routes.exam,
        ),
        const _ZoneTile(
          icon: EliteAssets.dailyCoins,
          title: 'Daily scratch card',
          subtitle: 'Scratch once a day, win up to 100 coins',
          route: Routes.dailyReward,
        ),
        const _ZoneTile(
          icon: EliteAssets.referEarn,
          title: 'Refer & earn',
          subtitle: '100 coins for every friend who joins',
          route: Routes.referEarn,
        ),
      ],
    );
  }
}

class _ZoneTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String route;

  const _ZoneTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: () => Get.toNamed(route),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            EliteAssets.svg(icon, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
