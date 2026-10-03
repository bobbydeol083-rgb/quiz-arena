import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';

import '../controllers/leaderboard_controller.dart';

/// Weekly / all-time rankings with a top-3 podium and staggered rank rows.
/// Bottom-nav tab index 2.
class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  static const _scopes = ['weekly', 'all-time'];
  static const _scopeLabels = ['Weekly', 'All time'];
  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      currentIndex: 2,
      body: Column(
        children: [
          Padding(
            padding: AppInsets.screen,
            child: Row(
              children: [
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Obx(
                  () => controller.offline.value
                      ? const OfflineChip()
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          _scopePills(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: AppInsets.screen,
                  child: ShimmerList(count: 6),
                );
              }
              if (controller.entries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 420,
                      child: EmptyState(
                        emoji: '🏆',
                        title: 'No rankings yet',
                        subtitle:
                            'Play some quizzes to climb the leaderboard.',
                        actionLabel: 'Refresh',
                        onAction: controller.refresh,
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  // Clear the floating bottom bar + Play FAB.
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    if (controller.entries.length >= 3) _podium(),
                    ...controller.entries
                        .skip(3)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => _rankRow(context, e.value, e.key)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Animated Weekly / All time pill with a sliding gradient indicator.
  Widget _scopePills() {
    return Obx(() {
      final selected = _scopes.indexOf(controller.scope.value).clamp(0, 1);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.adaptiveSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.adaptiveBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = (constraints.maxWidth - 8) / 2;
            return SizedBox(
              height: 44,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppDurations.normal,
                    curve: AppCurves.entrance,
                    left: selected * w,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _scopes.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                controller.setScope(_scopes[i]),
                            child: Center(
                              child: Text(
                                _scopeLabels[i],
                                style: TextStyle(
                                  color: i == selected
                                      ? Colors.white
                                      : AppColors.adaptiveSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  /// Top 3 arranged 2nd - 1st - 3rd.
  Widget _podium() {
    final sorted = [...controller.entries]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final top = sorted.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _podiumColumn(top[1], 110, 1),
          const SizedBox(width: AppSpacing.md),
          _podiumColumn(top[0], 150, 0),
          const SizedBox(width: AppSpacing.md),
          _podiumColumn(top[2], 90, 2),
        ],
      ),
    );
  }

  /// One podium column: medal, avatar, name, points, rising gradient bar.
  Widget _podiumColumn(LeaderboardEntry e, double barHeight, int rankIndex) {
    final isFirst = rankIndex == 0;
    return FadeSlideIn(
      index: rankIndex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_medals[rankIndex], style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppSpacing.xs),
          ArenaAvatar(
            imageUrl: e.avatar,
            name: e.username,
            radius: isFirst ? 30 : 24,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 92,
            child: Text(
              e.username,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${e.points} pts',
            style: TextStyle(
              color: AppColors.adaptiveSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: barHeight),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, h, _) => Container(
              width: isFirst ? 84 : 72,
              height: h,
              decoration: BoxDecoration(
                gradient: isFirst
                    ? const LinearGradient(
                        colors: [
                          AppColors.goldTier,
                          AppColors.warning,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : AppGradients.primaryVertical,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rank rows for 4th place onwards; the current user row is highlighted.
  Widget _rankRow(BuildContext context, LeaderboardEntry e, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe =
        controller.auth.currentUser.value?.username == e.username;
    final textColor =
        isMe ? Colors.white : (isDark ? AppColors.adaptivePrimary : null);
    return FadeSlideIn(
      index: index,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: isMe ? AppGradients.primary : null,
          color: isMe
              ? null
              : (isDark ? AppColors.surface : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isMe
                ? Colors.transparent
                : (isDark
                    ? AppColors.glassBorder
                    : AppColors.violetDeep.withValues(alpha: 0.12)),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#${e.rank}',
                style: TextStyle(
                  color: textColor ?? AppColors.adaptiveSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            ArenaAvatar(imageUrl: e.avatar, name: e.username, radius: 18),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                e.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${e.points} pts',
              style: TextStyle(
                color: textColor ?? AppColors.adaptiveSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
