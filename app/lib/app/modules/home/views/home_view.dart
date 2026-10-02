import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/modules/home/controllers/home_controller.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';
import 'package:quiz_arena/app/modules/shared/widgets/difficulty_sheet.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      currentIndex: 0,
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        color: AppColors.violet,
        backgroundColor: AppColors.surfaceElevated,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppInsets.screen,
          children: [
            FadeSlideIn(index: 0, child: _header(context)),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => controller.offline.value
                  ? FadeSlideIn(
                      index: 1,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: OfflineChip(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => controller.isLoading.value
                  ? const ShimmerList(count: 5)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeSlideIn(index: 1, child: _xpCard()),
                        const SizedBox(height: AppSpacing.xxl),
                        FadeSlideIn(
                          index: 2,
                          child: _sectionTitle(context, 'Choose your battle'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(index: 3, child: _quickModes(context)),
                        const SizedBox(height: AppSpacing.xxl),
                        FadeSlideIn(
                          index: 4,
                          child: _categoriesHeader(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(
                            index: 5, child: _categoryChips()),
                        const SizedBox(height: AppSpacing.xxl),
                        FadeSlideIn(
                          index: 6,
                          child: _banner(
                            context,
                            emoji: '📍',
                            title: 'Nearby rivals',
                            subtitle: 'Find players near you',
                            onTap: () => Get.toNamed(Routes.nearby),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(
                          index: 7,
                          child: _banner(
                            context,
                            emoji: '⚔️',
                            title: 'Duel a friend',
                            subtitle: 'Realtime 1v1 battle',
                            onTap: () => Get.toNamed(Routes.duel),
                          ),
                        ),
                        // Clear the floating bottom bar.
                        const SizedBox(height: 110),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Obx(() {
            final user = controller.user;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.greeting.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: isDark
                        ? AppColors.adaptiveMuted
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user?.username ?? 'Player',
                  style: Theme.of(context).textTheme.displaySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }),
        ),
        Obx(() {
          final user = controller.user;
          return ArenaAvatar(
            imageUrl: user?.avatar,
            name: user?.username ?? 'Player',
            radius: 26,
          );
        }),
      ],
    );
  }

  Widget _xpCard() {
    return GlassCard(
      child: Obx(() => XpProgressBar(xp: controller.user?.xp ?? 0)),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _quickModes(BuildContext context) {
    const modes = [
      (QuizMode.solo, 'Solo'),
      (QuizMode.blitz, 'Blitz'),
      (QuizMode.marathon, 'Marathon'),
      (QuizMode.daily, 'Daily'),
    ];
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final (mode, label) = modes[i];
          return SizedBox(
            width: 120,
            child: GlassCard(
              onTap: () => _playQuick(mode),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mode.emoji,
                      style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    mode.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness ==
                              Brightness.dark
                          ? AppColors.adaptiveMuted
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _playQuick(QuizMode mode) {
    switch (mode) {
      case QuizMode.solo:
        Get.toNamed(Routes.categories);
      case QuizMode.blitz:
        Get.toNamed(
          Routes.quiz,
          arguments: QuizArgs(mode: QuizMode.blitz),
        );
      case QuizMode.marathon:
        Get.toNamed(
          Routes.quiz,
          arguments: QuizArgs(mode: QuizMode.marathon),
        );
      case QuizMode.daily:
        Get.toNamed(
          Routes.quiz,
          arguments: QuizArgs(mode: QuizMode.daily),
        );
      case QuizMode.duel:
        Get.toNamed(Routes.duel);
      case QuizMode.party:
        Get.toNamed(Routes.party);
    }
  }

  Widget _categoriesHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Get.toNamed(Routes.categories),
          child: const Text('See all'),
        ),
      ],
    );
  }

  Widget _categoryChips() {
    final categories = controller.categories;
    if (categories.isEmpty) {
      return const EmptyState(
        emoji: '🗂️',
        title: 'No categories yet',
        subtitle: 'Pull down to refresh and try again.',
      );
    }
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final cat = categories[i];
          return _CategoryChip(category: cat);
        },
      ),
    );
  }

  Widget _banner(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
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
  }
}

class _CategoryChip extends StatelessWidget {
  final QuizCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => DifficultySheet.pick(category),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glass : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isDark
                  ? AppColors.glassBorder
                  : AppColors.violetDeep.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.icon,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
