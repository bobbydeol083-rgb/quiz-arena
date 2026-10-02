import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/utils/formatters.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/modules/discover/controllers/discover_controller.dart';
import 'package:quiz_arena/app/modules/shared/widgets/difficulty_sheet.dart';

class DiscoverView extends GetView<DiscoverController> {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      currentIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  index: 0,
                  child: Text(
                    'Discover',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  index: 1,
                  child: TextField(
                    onChanged: controller.setQuery,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search quizzes or players…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(index: 2, child: _tabPill(context)),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView(
                  padding: AppInsets.screen,
                  children: const [
                    ShimmerList(count: 5, itemHeight: 76),
                  ],
                );
              }
              return controller.tab.value == 0
                  ? _quizzesTab(context)
                  : _playersTab(context);
            }),
          ),
        ],
      ),
    );
  }

  Widget _tabPill(BuildContext context) {
    const labels = ['Quizzes', 'Players'];
    return Obx(() {
      final active = controller.tab.value;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = active == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.setTab(i),
                child: AnimatedContainer(
                  duration: AppDurations.normal,
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.all(AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        selected ? AppGradients.primary : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.violet
                                  .withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: selected
                          ? Colors.white
                          : AppColors.adaptiveSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _quizzesTab(BuildContext context) {
    final categories = controller.filteredCategories;
    if (categories.isEmpty) {
      return const EmptyState(
        emoji: '🔍',
        title: 'No quizzes found',
        subtitle: 'Try a different search term.',
      );
    }
    return ListView.builder(
      padding: AppInsets.screen.copyWith(bottom: 120),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        return FadeSlideIn(
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _CategoryRow(category: cat),
          ),
        );
      },
    );
  }

  Widget _playersTab(BuildContext context) {
    final players = controller.filteredPlayers;
    if (players.isEmpty) {
      return EmptyState(
        emoji: '🧑‍🚀',
        title: 'No players found',
        subtitle: controller.query.value.isEmpty
            ? 'Nobody is on the board yet — play a quiz to claim a spot.'
            : 'Try a different search term.',
      );
    }
    return ListView.builder(
      padding: AppInsets.screen.copyWith(bottom: 120),
      itemCount: players.length,
      itemBuilder: (context, i) {
        final player = players[i];
        return FadeSlideIn(
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _PlayerRow(entry: player),
          ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final QuizCategory category;

  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      onTap: () => DifficultySheet.pick(category),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.quizCount} quizzes',
                  style: TextStyle(
                    fontSize: 12,
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

class _PlayerRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _PlayerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          ArenaAvatar(
            imageUrl: entry.avatar,
            name: entry.username,
            radius: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${Formatters.compactNumber(entry.points)} pts',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isDark ? AppColors.gold : AppColors.violetDeep,
            ),
          ),
        ],
      ),
    );
  }
}
